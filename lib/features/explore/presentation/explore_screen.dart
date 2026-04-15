import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../community/data/community_template_repository.dart';
import '../../community/domain/community_template_model.dart';
import '../../community/presentation/widgets/community_template_card.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../profile/domain/public_profile_model.dart';
import '../../profile/presentation/widgets/public_profile_card.dart';

enum _ExploreSection { plantillas, usuarios }

/// Pantalla de exploración unificada con búsqueda y toggle Plantillas/Usuarios.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final CommunityTemplateRepository _templateRepo;
  late final PublicProfileRepository _profileRepo;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  _ExploreSection _section = _ExploreSection.plantillas;
  String _query = '';

  // ---- estado plantillas ----
  final List<CommunityTemplateModel> _templates = [];
  DocumentSnapshot? _lastTemplateDoc;
  bool _loadingTemplates = false;
  bool _hasMoreTemplates = true;
  TemplateSort _templateSort = TemplateSort.popular;
  String? _templateCategory;

  // ---- estado perfiles ----
  final List<PublicProfileModel> _profiles = [];
  DocumentSnapshot? _lastProfileDoc;
  bool _loadingProfiles = false;
  bool _hasMoreProfiles = true;
  List<PublicProfileModel>? _profileSearchResults;
  bool _searchingProfiles = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _templateRepo = CommunityTemplateRepository(uid: uid);
    _profileRepo = PublicProfileRepository(uid: uid);
    _loadTemplates();
    _loadProfiles();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== SCROLL / BÚSQUEDA ====================

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_section == _ExploreSection.plantillas) {
        _loadTemplates();
      } else {
        _loadProfiles();
      }
    }
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim().toLowerCase();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = q);
      if (_section == _ExploreSection.usuarios) {
        _searchUsers(q);
      }
    });
  }

  // ==================== PLANTILLAS ====================

  Future<void> _loadTemplates({bool refresh = false}) async {
    if (_loadingTemplates) return;
    if (!_hasMoreTemplates && !refresh) return;
    setState(() => _loadingTemplates = true);
    if (refresh) {
      _templates.clear();
      _lastTemplateDoc = null;
      _hasMoreTemplates = true;
    }
    final result = await _templateRepo.fetchTemplatePage(
      category: _templateCategory,
      sort: _templateSort,
      startAfter: refresh ? null : _lastTemplateDoc,
    );
    if (!mounted) return;
    setState(() {
      _templates.addAll(result.templates);
      _lastTemplateDoc = result.lastDoc;
      _hasMoreTemplates = result.templates.length == 20;
      _loadingTemplates = false;
    });
  }

  void _applyTemplateSort(TemplateSort sort) {
    if (_templateSort == sort) return;
    setState(() {
      _templateSort = sort;
      _query = '';
      _searchController.clear();
    });
    _loadTemplates(refresh: true);
  }

  void _applyCategory(String? cat) {
    if (_templateCategory == cat) return;
    setState(() {
      _templateCategory = cat;
      _query = '';
      _searchController.clear();
    });
    _loadTemplates(refresh: true);
  }

  // filtro client-side por titulo
  List<CommunityTemplateModel> get _filteredTemplates {
    if (_query.isEmpty) return _templates;
    return _templates
        .where((t) => t.title.toLowerCase().contains(_query))
        .toList();
  }

  // ==================== PERFILES ====================

  Future<void> _loadProfiles({bool refresh = false}) async {
    if (_loadingProfiles) return;
    if (!_hasMoreProfiles && !refresh) return;
    setState(() => _loadingProfiles = true);
    if (refresh) {
      _profiles.clear();
      _lastProfileDoc = null;
      _hasMoreProfiles = true;
    }
    final result = await _profileRepo.watchPublicProfilesFeed(
      limit: 20,
      startAfter: refresh ? null : _lastProfileDoc,
    );
    if (!mounted) return;
    setState(() {
      _profiles.addAll(result.profiles);
      _lastProfileDoc = result.lastDoc;
      _hasMoreProfiles = result.profiles.length == 20;
      _loadingProfiles = false;
    });
  }

  Future<void> _searchUsers(String q) async {
    if (q.isEmpty) {
      setState(() => _profileSearchResults = null);
      return;
    }
    setState(() => _searchingProfiles = true);
    final results = await _profileRepo.searchByUsername(q);
    if (!mounted) return;
    setState(() {
      _profileSearchResults = results;
      _searchingProfiles = false;
    });
  }

  // ==================== CAMBIO DE SECCIÓN ====================

  void _switchSection(_ExploreSection section) {
    if (_section == section) return;
    setState(() {
      _section = section;
      _query = '';
      _searchController.clear();
      _profileSearchResults = null;
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // cabecera fija con drawer + título + búsqueda + toggle
          SliverAppBar(
            floating: true,
            snap: true,
            centerTitle: false,
            leading: const DrawerMenuButton(),
            title: const Text('Explorar'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    // barra de búsqueda
                    SearchBar(
                      controller: _searchController,
                      hintText: _section == _ExploreSection.plantillas
                          ? 'Buscar plantillas…'
                          : 'Buscar por @usuario…',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _profileSearchResults = null;
                              });
                            },
                          ),
                      ],
                      elevation: const WidgetStatePropertyAll(0),
                    ),
                    const SizedBox(height: 10),
                    // toggle Plantillas / Usuarios
                    SegmentedButton<_ExploreSection>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: _ExploreSection.plantillas,
                          icon: Icon(Icons.storefront_outlined, size: 16),
                          label: Text('Plantillas'),
                        ),
                        ButtonSegment(
                          value: _ExploreSection.usuarios,
                          icon: Icon(Icons.people_outline_rounded, size: 16),
                          label: Text('Usuarios'),
                        ),
                      ],
                      selected: {_section},
                      onSelectionChanged: (s) => _switchSection(s.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // filtros de plantillas (solo visible en sección plantillas)
          if (_section == _ExploreSection.plantillas)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'Popular',
                      icon: Icons.trending_up_rounded,
                      selected: _templateSort == TemplateSort.popular,
                      onTap: () => _applyTemplateSort(TemplateSort.popular),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Recientes',
                      icon: Icons.schedule_rounded,
                      selected: _templateSort == TemplateSort.recent,
                      onTap: () => _applyTemplateSort(TemplateSort.recent),
                    ),
                    const SizedBox(width: 8),
                    VerticalDivider(
                      width: 16,
                      indent: 8,
                      endIndent: 8,
                      color: scheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Todas',
                      selected: _templateCategory == null,
                      onTap: () => _applyCategory(null),
                    ),
                    ...AppTheme.categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: AppTheme.categoryLabel(cat),
                            selected: _templateCategory == cat,
                            onTap: () => _applyCategory(cat),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // contenido según sección
          if (_section == _ExploreSection.plantillas)
            _buildTemplateList()
          else
            _buildProfileList(),

          // indicador final de lista
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _buildListFooter(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECCIÓN PLANTILLAS ====================

  Widget _buildTemplateList() {
    final items = _filteredTemplates;

    if (items.isEmpty && !_loadingTemplates) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.storefront_outlined,
          message: _query.isNotEmpty || _templateCategory != null
              ? 'Sin resultados para ese filtro'
              : 'Todavía no hay plantillas',
          sub: _query.isNotEmpty || _templateCategory != null
              ? 'Prueba otro filtro o búsqueda.'
              : 'Sé el primero en publicar un plan.',
        ),
      );
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => CommunityTemplateCard(
        key: ValueKey(items[i].id),
        template: items[i],
        onTap: () => context.go('/community/${items[i].id}'),
      )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: 40 * i.clamp(0, 12)),
            duration: 250.ms,
          ),
    );
  }

  // ==================== SECCIÓN USUARIOS ====================

  Widget _buildProfileList() {
    // si hay búsqueda activa, mostrar resultados
    if (_query.isNotEmpty) {
      if (_searchingProfiles) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final results = _profileSearchResults ?? [];
      if (results.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.manage_search_rounded,
            message: 'Sin resultados para "$_query"',
            sub: 'Comprueba que el @usuario existe.',
          ),
        );
      }
      return SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, i) => PublicProfileCard(
          key: ValueKey(results[i].uid),
          profile: results[i],
          onTap: () => context.goNamed(
            'public-profile',
            pathParameters: {'userId': results[i].uid},
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 40 * i.clamp(0, 12)), duration: 250.ms),
      );
    }

    // feed paginado sin búsqueda
    if (_profiles.isEmpty && !_loadingProfiles) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.people_outline_rounded,
          message: 'Ningún perfil público aún',
          sub: 'Activa el tuyo en Perfil → Ajustes.',
        ),
      );
    }

    return SliverList.builder(
      itemCount: _profiles.length,
      itemBuilder: (context, i) => PublicProfileCard(
        key: ValueKey(_profiles[i].uid),
        profile: _profiles[i],
        onTap: () => context.goNamed(
          'public-profile',
          pathParameters: {'userId': _profiles[i].uid},
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 40 * i.clamp(0, 12)), duration: 250.ms),
    );
  }

  // ==================== FOOTER ====================

  Widget _buildListFooter() {
    final loading = _section == _ExploreSection.plantillas
        ? _loadingTemplates
        : _loadingProfiles;
    final hasMore = _section == _ExploreSection.plantillas
        ? _hasMoreTemplates
        : _hasMoreProfiles;
    final loadMore = _section == _ExploreSection.plantillas
        ? () => _loadTemplates()
        : () => _loadProfiles();

    if (loading) return const Center(child: CircularProgressIndicator());
    if (hasMore) {
      return Center(
        child: TextButton(onPressed: loadMore, child: const Text('Cargar más')),
      );
    }
    return Center(
      child: Text(
        '— fin de la lista —',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ==================== WIDGETS INTERNOS ====================

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label),
            ])
          : Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
