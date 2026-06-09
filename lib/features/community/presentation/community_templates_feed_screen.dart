import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../levels/presentation/category_l10n.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_template_repository.dart';
import '../domain/community_template_model.dart';
import 'widgets/community_template_card.dart';
import '../../../core/router/main_shell.dart';

/// Feed paginado del marketplace de plantillas de la comunidad.
class CommunityTemplatesFeedScreen extends StatefulWidget {
  const CommunityTemplatesFeedScreen({super.key});

  @override
  State<CommunityTemplatesFeedScreen> createState() =>
      _CommunityTemplatesFeedScreenState();
}

class _CommunityTemplatesFeedScreenState
    extends State<CommunityTemplatesFeedScreen> {
  late final CommunityTemplateRepository _repo;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  // feed paginado
  final List<CommunityTemplateModel> _templates = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  // filtros
  TemplateSort _sort = TemplateSort.popular;
  String? _categoryFilter;

  // busqueda client-side sobre la pagina cargada
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = CommunityTemplateRepository(uid: uid);
    _loadPage();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchQuery = q);
    });
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_loading) return;
    if (!_hasMore && !refresh) return;

    setState(() => _loading = true);

    if (refresh) {
      _templates.clear();
      _lastDoc = null;
      _hasMore = true;
    }

    final result = await _repo.fetchTemplatePage(
      category: _categoryFilter,
      sort: _sort,
      startAfter: refresh ? null : _lastDoc,
    );

    if (!mounted) return;
    setState(() {
      _templates.addAll(result.templates);
      _lastDoc = result.lastDoc;
      _hasMore = result.templates.length == 20;
      _loading = false;
    });
  }

  void _applySort(TemplateSort sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadPage(refresh: true);
  }

  void _applyCategory(String? cat) {
    if (_categoryFilter == cat) return;
    setState(() {
      _categoryFilter = cat;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadPage(refresh: true);
  }

  List<CommunityTemplateModel> get _filtered {
    if (_searchQuery.isEmpty) return _templates;
    return _templates
        .where((t) => t.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // cabecera
          SliverAppBar(
            floating: true,
            snap: true,
            centerTitle: false,
            leading: const DrawerMenuButton(),
            title: Text(s.communityTitle),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Column(
                children: [
                  // barra de busqueda
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: s.communitySearchHint,
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                      elevation: const WidgetStatePropertyAll(0),
                    ),
                  ),
                  // chips de orden
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _SortChip(
                          label: s.communitySortPopular,
                          icon: Icons.trending_up_rounded,
                          selected: _sort == TemplateSort.popular,
                          onTap: () => _applySort(TemplateSort.popular),
                        ),
                        const SizedBox(width: 8),
                        _SortChip(
                          label: s.communitySortRecent,
                          icon: Icons.schedule_rounded,
                          selected: _sort == TemplateSort.recent,
                          onTap: () => _applySort(TemplateSort.recent),
                        ),
                        const SizedBox(width: 8),
                        // separador visual
                        VerticalDivider(
                          width: 16,
                          indent: 8,
                          endIndent: 8,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(width: 8),
                        // chips de categoria
                        _SortChip(
                          label: s.communityFilterAll,
                          selected: _categoryFilter == null,
                          onTap: () => _applyCategory(null),
                        ),
                        ...AppTheme.categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _SortChip(
                                label: CategoryL10n.labelOf(cat, context),
                                selected: _categoryFilter == cat,
                                onTap: () => _applyCategory(cat),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // estado vacio
          if (filtered.isEmpty && !_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                hasFilter: _categoryFilter != null || _searchQuery.isNotEmpty,
              ),
            )
          else ...[
            // lista de plantillas
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                return CommunityTemplateCard(
                  key: ValueKey(filtered[i].id),
                  template: filtered[i],
                  onTap: () => context.push(
                    '/community/${filtered[i].id}',
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                      duration: 250.ms,
                    );
              },
            ),

            // indicador de carga / fin de lista
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, context.bottomNavInset),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _hasMore
                          ? TextButton(
                              onPressed: _loadPage,
                              child: Text(s.communityLoadMore),
                            )
                          : Text(
                              s.communityEndOfList,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: scheme.onSurfaceVariant),
                            ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== INTERNOS ====================

class _SortChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14),
                const SizedBox(width: 4),
                Text(label),
              ],
            )
          : Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;

  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EmptyStateView(
      icon: Icons.storefront_outlined,
      title: hasFilter ? s.communityEmptyFilterTitle : s.communityEmptyTitle,
      subtitle: hasFilter
          ? s.communityEmptyFilterSubtitle
          : s.communityEmptySubtitle,
    );
  }
}
