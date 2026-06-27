import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge_model.dart';
import '../../challenges/presentation/widgets/create_challenge_sheet.dart';
import '../../community/data/community_template_repository.dart';
import '../../community/domain/community_template_model.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../profile/domain/public_profile_model.dart';
import '../../social/data/follow_repository.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/user_directory_entry.dart';
import '../../../l10n/app_localizations.dart';

/// Descubrir hábitos — reemplaza la antigua pantalla de búsqueda.
/// Layout inspirado en el mockup Stitch "Discover Habits and Creators":
/// hero + search + Featured Templates (carrusel horizontal) + Trending Creators (grid 2 cols).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CommunityTemplateRepository _templateRepo;
  late final PublicProfileRepository _profileRepo;
  late final ChallengeRepository _challengeRepo;
  late final FollowRepository _followRepo;
  late final UserDirectoryRepository _dirRepo;
  late final String _myUid;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // featured (populares) — carrusel
  List<CommunityTemplateModel> _featured = [];
  bool _loadingFeatured = true;

  // trending creators — grid
  List<PublicProfileModel> _creators = [];
  bool _loadingCreators = true;

  // retos activos del usuario
  List<ChallengeModel> _activeChallenges = [];
  bool _loadingChallenges = true;

  // resultados de búsqueda (mezclados)
  List<CommunityTemplateModel> _searchTemplates = [];
  List<UserDirectoryEntry> _searchUsers = [];
  bool _searching = false;

  // estado de follow — cargado una vez para evitar N reads
  Set<String> _followingUids = {};
  Set<String> _pendingUids = {};

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _templateRepo = CommunityTemplateRepository(uid: _myUid);
    _profileRepo = PublicProfileRepository(uid: _myUid);
    _challengeRepo = ChallengeRepository(uid: _myUid);
    _followRepo = FollowRepository(uid: _myUid);
    _dirRepo = UserDirectoryRepository(uid: _myUid);
    _loadFeatured();
    _loadCreators();
    _loadChallenges();
    _loadFollowState();
    _searchController.addListener(_onQueryChanged);
  }

  Future<void> _loadFollowState() async {
    final results = await Future.wait([
      _followRepo.getFollowingUids(),
      _followRepo.getSentPendingUids(),
    ]);
    if (mounted) {
      setState(() {
        _followingUids = results[0].toSet();
        _pendingUids = results[1].toSet();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatured() async {
    final res = await _templateRepo.fetchTemplatePage(
      sort: TemplateSort.popular,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _featured = res.templates.take(8).toList();
      _loadingFeatured = false;
    });
  }

  Future<void> _loadChallenges() async {
    final all = await _challengeRepo.watchMyChallenges().first;
    if (!mounted) return;
    setState(() {
      _activeChallenges = all
          .where((c) =>
              c.status == ChallengeStatus.active ||
              c.status == ChallengeStatus.pending)
          .take(5)
          .toList();
      _loadingChallenges = false;
    });
  }

  Future<void> _loadCreators() async {
    // Creadores destacados = autores que han publicado una rutina (plantilla),
    // no todos los usuarios públicos. Excluye al propio usuario.
    final creatorUids = await _templateRepo.fetchCreatorUids(limit: 30);
    final profiles =
        await _profileRepo.getPublicProfiles(creatorUids.take(6).toList());
    if (!mounted) return;
    setState(() {
      _creators = profiles.where((p) => p.uid != _myUid).toList();
      _loadingCreators = false;
    });
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim().toLowerCase();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      if (!mounted) return;
      setState(() => _query = q);
      if (q.isEmpty) {
        setState(() {
          _searchTemplates = [];
          _searchUsers = [];
          _searching = false;
        });
        return;
      }
      setState(() => _searching = true);
      // usuarios por username (directory) + plantillas client-side del pool popular
      final users = await _dirRepo.searchByUsername(q, limit: 10);
      final templates = _featured
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.authorUsername.toLowerCase().contains(q))
          .toList();
      if (!mounted) return;
      setState(() {
        _searchUsers = users.where((u) => u.uid != _myUid).toList();
        _searchTemplates = templates;
        _searching = false;
      });
    });
  }

  Future<void> _followUser(UserDirectoryEntry target) async {
    if (_followingUids.contains(target.uid)) return;
    final me = FirebaseAuth.instance.currentUser!;
    final myEntry = await _dirRepo.getEntry(_myUid);
    try {
      if (!target.isProfilePublic) {
        // perfil privado → solicitud
        final hasPending = await _followRepo.hasPendingFollowRequest(target.uid);
        if (hasPending) return;
        await _followRepo.sendFollowRequest(
          toUid: target.uid,
          fromUsername: myEntry?.username ?? '',
          fromDisplayName: me.displayName ?? '',
          fromPhotoUrl: me.photoURL,
          toUsername: target.username,
          toDisplayName: target.displayName,
          toPhotoUrl: target.photoUrl,
        );
        if (mounted) setState(() => _pendingUids.add(target.uid));
      } else {
        // perfil público → follow directo
        await _followRepo.follow(
          targetUid: target.uid,
          targetUsername: target.username,
          targetDisplayName: target.displayName,
          targetPhotoUrl: target.photoUrl,
          myUsername: myEntry?.username ?? '',
          myDisplayName: me.displayName ?? '',
          myPhotoUrl: me.photoURL,
        );
        if (mounted) setState(() => _followingUids.add(target.uid));
      }
    } catch (_) {}
  }

  Future<void> _cancelFollowRequest(UserDirectoryEntry target) async {
    try {
      await _followRepo.cancelFollowRequest(target.uid);
      if (mounted) setState(() => _pendingUids.remove(target.uid));
    } catch (_) {}
  }

  Future<void> _followPublicProfile(PublicProfileModel profile) async {
    if (_followingUids.contains(profile.uid)) return;
    final me = FirebaseAuth.instance.currentUser!;
    final myEntry = await _dirRepo.getEntry(_myUid);
    try {
      // los perfiles en public_profiles/ son siempre públicos → follow directo
      await _followRepo.follow(
        targetUid: profile.uid,
        targetUsername: profile.username,
        targetDisplayName: profile.displayName,
        targetPhotoUrl: profile.photoUrl,
        myUsername: myEntry?.username ?? '',
        myDisplayName: me.displayName ?? '',
        myPhotoUrl: me.photoURL,
      );
      if (mounted) setState(() => _followingUids.add(profile.uid));
    } catch (_) {}
  }

  Future<void> _unfollowUid(String uid) async {
    await _followRepo.unfollow(uid);
    if (mounted) setState(() => _followingUids.remove(uid));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---------- AppBar con drawer + settings ----------
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: false,
              elevation: 0,
              backgroundColor: scheme.surface,
              leading: const DrawerMenuButton(),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.exploreTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                          letterSpacing: -0.2,
                        ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.pushNamed('settings'),
                ),
              ],
            ),

            // ---------- Hero ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  s.exploreSubtitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 320.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),

            // ---------- Search bar ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _SearchField(controller: _searchController),
              ),
            ),

            // ---------- Resultados de búsqueda o secciones normales ----------
            if (_query.isNotEmpty)
              ..._buildSearchResults(scheme)
            else ...[
              _buildChallengesSection(scheme),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildFeaturedSection(scheme),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildCreatorsSection(scheme),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== RETOS COMPARTIDOS ====================

  Widget _buildChallengesSection(ColorScheme scheme) {
    final s = S.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: s.exploreChallenges,
            action: s.exploreSeeAll,
            onAction: () => context.push('/challenges'),
          ),
          const SizedBox(height: 12),
          if (_loadingChallenges)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ChartSkeleton(height: 80),
            )
          else if (_activeChallenges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  final created = await CreateChallengeSheet.show(context);
                  if (created == true && mounted) _loadChallenges();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.handshake_rounded,
                            color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.exploreCreateChallenge,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.exploreChallengeSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.05, end: 0),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _activeChallenges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = _activeChallenges[i];
                  final brightness = Theme.of(context).brightness;
                  final catBg = AppTheme.categoryBg(c.habitCategory, brightness);
                  final catFg = AppTheme.categoryFg(c.habitCategory, brightness);
                  return GestureDetector(
                    onTap: () => context.push('/challenges/${c.id}'),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  AppTheme.categoryIcon(c.habitCategory),
                                  size: 12,
                                  color: catFg,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.habitTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.isPending
                                ? s.explorePending
                                : s.exploreChallengeDays(c.durationDays),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 60 * i.clamp(0, 5)),
                        duration: 280.ms,
                      )
                      .slideX(begin: 0.1, end: 0, duration: 320.ms);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== FEATURED TEMPLATES ====================

  Widget _buildFeaturedSection(ColorScheme scheme) {
    final s = S.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: s.exploreFeaturedTemplates,
            action: s.exploreSeeAllAlt,
            onAction: () => context.pushNamed('community-feed'),
          ),
          const SizedBox(height: 12),
          if (_loadingFeatured)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ChartSkeleton(height: 180),
            )
          else if (_featured.isEmpty)
            _EmptyInline(
              icon: Icons.storefront_outlined,
              text: s.exploreNoTemplates,
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => _FeaturedTemplateCard(
                  template: _featured[i],
                  onTap: () =>
                      context.push('/community/${_featured[i].id}'),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                      duration: 280.ms,
                    )
                    .slideX(begin: 0.1, end: 0, duration: 320.ms),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== TRENDING CREATORS ====================

  Widget _buildCreatorsSection(ColorScheme scheme) {
    final s = S.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: s.exploreFeaturedCreators,
            action: s.exploreSeeAll,
            onAction: () => context.pushNamed('public-profiles-feed'),
          ),
          const SizedBox(height: 12),
          if (_loadingCreators)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionSkeleton(itemCount: 3),
            )
          else if (_creators.isEmpty)
            _EmptyInline(
              icon: Icons.people_outline_rounded,
              text: s.exploreNoProfiles,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _creators.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  // altura de celda fija (en vez de aspect ratio dependiente del
                  // ancho) para que la tarjeta de creador no desborde en móviles
                  mainAxisExtent: 224,
                ),
                itemBuilder: (_, i) {
                  final p = _creators[i];
                  return _CreatorCard(
                    profile: p,
                    highlighted: i < 2,
                    isFollowing: _followingUids.contains(p.uid),
                    onTap: () => context.pushNamed(
                      'public-profile',
                      pathParameters: {'userId': p.uid},
                    ),
                    onFollowToggle: () => _followingUids.contains(p.uid)
                        ? _unfollowUid(p.uid)
                        : _followPublicProfile(p),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 80 * i.clamp(0, 6)),
                        duration: 280.ms,
                      )
                      .slideY(begin: 0.08, end: 0, duration: 320.ms);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SEARCH RESULTS ====================

  List<Widget> _buildSearchResults(ColorScheme scheme) {
    final s = S.of(context);
    if (_searching) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionSkeleton(itemCount: 3),
          ),
        ),
      ];
    }
    if (_searchTemplates.isEmpty && _searchUsers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: Icons.manage_search_rounded,
            title: s.exploreNoResults,
            subtitle: s.exploreNoResultsHint,
          ),
        ),
      ];
    }
    return [
      if (_searchUsers.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              s.explorePeople,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverList.separated(
          itemCount: _searchUsers.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 72,
            endIndent: 20,
          ),
          itemBuilder: (_, i) {
            final u = _searchUsers[i];
            final isFollowing = _followingUids.contains(u.uid);
            final isPending = _pendingUids.contains(u.uid);
            final isPrivate = !u.isProfilePublic;
            return _UserSearchTile(
              entry: u,
              isFollowing: isFollowing,
              isPending: isPending,
              isPrivate: isPrivate,
              onTap: () => context.pushNamed(
                'public-profile',
                pathParameters: {'userId': u.uid},
              ),
              onFollowTap: isFollowing
                  ? () => _unfollowUid(u.uid)
                  : isPending
                      ? () => _cancelFollowRequest(u)
                      : () => _followUser(u),
            );
          },
        ),
      ],
      if (_searchTemplates.isNotEmpty) ...[
        if (_searchUsers.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              s.exploreTemplates,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverList.separated(
          itemCount: _searchTemplates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FeaturedTemplateCard(
              template: _searchTemplates[i],
              full: true,
              onTap: () =>
                  context.push('/community/${_searchTemplates[i].id}'),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(child: SizedBox(height: context.bottomNavInset)),
    ];
  }
}

// ==================== WIDGETS ====================

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: s.exploreSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => controller.clear(),
              ),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTemplateCard extends StatelessWidget {
  final CommunityTemplateModel template;
  final VoidCallback onTap;
  final bool full;

  const _FeaturedTemplateCard({
    required this.template,
    required this.onTap,
    this.full = false,
  });

  // Línea de autor sin exponer NUNCA el uid: prefiere el nombre, luego un
  // username válido (≠ uid), y si no hay nada usable muestra "Usuario eliminado".
  // Protege contra datos heredados donde authorUsername quedó igual al uid.
  String _authorLine(S s, CommunityTemplateModel t) {
    if (t.authorDisplayName.isNotEmpty && t.authorDisplayName != t.authorUid) {
      return s.exploreByAuthorName(t.authorDisplayName);
    }
    if (t.authorUsername.isNotEmpty && t.authorUsername != t.authorUid) {
      return s.exploreByAuthor(t.authorUsername);
    }
    return s.exploreByAuthorName(s.communityDeletedAuthor);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final accent = _categoryAccent(template.category, scheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: full ? double.infinity : 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // halo accent
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: template.emoji != null
                          ? Center(
                              child: Text(
                                template.emoji!,
                                style: const TextStyle(fontSize: 22),
                              ),
                            )
                          : Icon(
                              AppTheme.categoryIcon(template.category),
                              color: accent,
                              size: 22,
                            ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description.isNotEmpty
                          ? template.description
                          : _authorLine(s, template),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      s.exploreHabitCount(template.habitCount),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            s.exploreImport,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final PublicProfileModel profile;
  final bool highlighted;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  const _CreatorCard({
    required this.profile,
    required this.highlighted,
    required this.isFollowing,
    required this.onTap,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // avatar con anillo opcional
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: highlighted
                    ? const LinearGradient(
                        colors: [AppTheme.primaryContainer, AppTheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: highlighted
                    ? null
                    : Border.all(
                        color: scheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
              ),
              child: AvatarCircle(
                initials: profile.avatarInitials,
                size: 56,
                backgroundColor: scheme.surfaceContainerHigh,
                textColor: scheme.primary,
                photoUrl: profile.photoUrl,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '@${profile.username}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppTheme.tertiaryContainer, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${profile.bestStreakEver}',
                        style: const TextStyle(
                          color: AppTheme.tertiaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.exploreHabitCountShort(profile.totalHabits),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: isFollowing
                  ? OutlinedButton(
                      onPressed: onFollowToggle,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        s.exploreFollowing,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: onFollowToggle,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        s.exploreFollow,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyInline({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ==================== USER SEARCH TILE (estilo Instagram) ====================

class _UserSearchTile extends StatelessWidget {
  final UserDirectoryEntry entry;
  final bool isFollowing;
  final bool isPending;
  final bool isPrivate;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  const _UserSearchTile({
    required this.entry,
    required this.isFollowing,
    required this.isPending,
    required this.isPrivate,
    required this.onTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    Widget trailingButton;
    if (isFollowing) {
      trailingButton = OutlinedButton(
        onPressed: onFollowTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(90, 32),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(s.exploreFollowing,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
    } else if (isPending) {
      trailingButton = OutlinedButton(
        onPressed: onFollowTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(90, 32),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(s.exploreRequested,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
    } else {
      trailingButton = FilledButton(
        onPressed: onFollowTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(90, 32),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: scheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          isPrivate ? s.exploreRequest : s.exploreFollow,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      leading: AvatarCircle(
        initials: entry.avatarInitials,
        photoUrl: entry.photoUrl,
        size: 44,
      ),
      title: Row(
        children: [
          Text(entry.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (isPrivate) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_rounded,
                size: 13, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
      subtitle: Text('@${entry.username}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
      trailing: trailingButton,
    );
  }
}

/// Devuelve un color accent por categoría (inspirado en el mock con halos).
Color _categoryAccent(String category, ColorScheme scheme) {
  switch (category) {
    case 'salud':
      return const Color(0xFF10B981);
    case 'productividad':
      return const Color(0xFF38BDF8);
    case 'bienestar':
      return const Color(0xFFF59E0B);
    case 'social':
      return const Color(0xFFEC4899);
    case 'aprendizaje':
      return const Color(0xFF8B5CF6);
    case 'finanzas':
      return const Color(0xFFEF4444);
    default:
      return scheme.primary;
  }
}
