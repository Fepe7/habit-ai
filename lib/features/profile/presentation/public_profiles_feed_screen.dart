import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_profile_model.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/user_directory_entry.dart';
import 'widgets/public_profile_card.dart';
import '../../../core/router/main_shell.dart';

/// Directorio global de perfiles con búsqueda universal por username.
/// El feed principal solo muestra perfiles públicos (public_profiles).
/// La búsqueda devuelve TODOS los usuarios con username, privados incluidos.
class PublicProfilesFeedScreen extends StatefulWidget {
  const PublicProfilesFeedScreen({super.key});

  @override
  State<PublicProfilesFeedScreen> createState() =>
      _PublicProfilesFeedScreenState();
}

class _PublicProfilesFeedScreenState extends State<PublicProfilesFeedScreen> {
  late final PublicProfileRepository _repo;
  late final UserDirectoryRepository _dirRepo;
  final _searchController = SearchController();
  Timer? _searchDebounce;

  // feed paginado (solo públicos)
  final List<PublicProfileModel> _feedProfiles = [];
  DocumentSnapshot? _lastDoc;
  bool _loadingFeed = false;
  bool _hasMore = true;

  // resultados de búsqueda (todos los usuarios)
  List<UserDirectoryEntry>? _searchResults;
  bool _loadingSearch = false;

  String _query = '';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = PublicProfileRepository(uid: uid);
    _dirRepo = UserDirectoryRepository(uid: uid);
    _loadFeed();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q == _query) return;
    _query = q;

    _searchDebounce?.cancel();
    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    setState(() => _loadingSearch = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _dirRepo.searchByUsername(q);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _loadingSearch = false;
      });
    });
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (_loadingFeed) return;
    if (!_hasMore && !refresh) return;

    setState(() => _loadingFeed = true);

    if (refresh) {
      _feedProfiles.clear();
      _lastDoc = null;
      _hasMore = true;
    }

    final result = await _repo.watchPublicProfilesFeed(
      limit: 20,
      startAfter: refresh ? null : _lastDoc,
    );

    if (!mounted) return;
    setState(() {
      _feedProfiles.addAll(result.profiles);
      _lastDoc = result.lastDoc;
      _hasMore = result.profiles.length == 20;
      _loadingFeed = false;
    });
  }

  void _openProfile(String uid) {
    context.pushNamed('public-profile', pathParameters: {'userId': uid});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const DrawerMenuButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          S.of(context).publicProfilesFeedTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SearchBar(
                    controller: _searchController,
                    hintText: S.of(context).publicProfilesFeedSearchHint,
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _searchResults = null;
                            });
                          },
                        ),
                    ],
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12),
                    ),
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: WidgetStatePropertyAll(
                      scheme.surfaceContainerLowest,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: isSearching
                  ? _SearchResultsView(
                      loading: _loadingSearch,
                      results: _searchResults ?? [],
                      onTap: _openProfile,
                    )
                  : _FeedView(
                      profiles: _feedProfiles,
                      loading: _loadingFeed,
                      hasMore: _hasMore,
                      onLoadMore: _loadFeed,
                      onRefresh: () => _loadFeed(refresh: true),
                      onTap: _openProfile,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS INTERNOS ====================

class _FeedView extends StatelessWidget {
  final List<PublicProfileModel> profiles;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(String uid) onTap;

  const _FeedView({
    required this.profiles,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && profiles.isEmpty) {
      return const SectionSkeleton(itemCount: 5);
    }

    if (profiles.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline_rounded,
        title: S.of(context).exploreNoProfiles,
        subtitle: S.of(context).publicProfilesFeedEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification &&
              n.metrics.extentAfter < 200 &&
              hasMore) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.only(bottom: context.bottomNavInset),
          itemCount: profiles.length + (hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == profiles.length) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PublicProfileCard(
              profile: profiles[i],
              onTap: () => onTap(profiles[i].uid),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: (i % 20) * 40),
                  duration: 300.ms,
                )
                .slideY(begin: 0.05);
          },
        ),
      ),
    );
  }
}

/// Vista de resultados de búsqueda — usa UserDirectoryEntry (todos los usuarios)
class _SearchResultsView extends StatelessWidget {
  final bool loading;
  final List<UserDirectoryEntry> results;
  final void Function(String uid) onTap;

  const _SearchResultsView({
    required this.loading,
    required this.results,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return EmptyStateView(
        icon: Icons.manage_search_rounded,
        title: S.of(context).exploreNoResults,
        subtitle: S.of(context).publicProfilesFeedNoResultsSubtitle,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: context.bottomNavInset),
      itemCount: results.length,
      itemBuilder: (context, i) => _DirectoryEntryCard(
        entry: results[i],
        onTap: () => onTap(results[i].uid),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 40), duration: 250.ms),
    );
  }
}

/// Card para resultados de búsqueda — muestra candado si el perfil es privado
class _DirectoryEntryCard extends StatelessWidget {
  final UserDirectoryEntry entry;
  final VoidCallback onTap;

  const _DirectoryEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPrivate = !entry.isProfilePublic;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarCircle(
                initials: entry.avatarInitials,
                size: 52,
                backgroundColor: scheme.primaryContainer,
                textColor: scheme.onPrimaryContainer,
                photoUrl: entry.photoUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${entry.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isPrivate)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
