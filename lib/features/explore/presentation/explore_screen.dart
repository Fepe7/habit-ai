import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../community/data/community_template_repository.dart';
import '../../community/domain/community_template_model.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../profile/domain/public_profile_model.dart';

/// Descubrir hábitos — reemplaza la antigua pantalla de búsqueda.
/// Layout inspirado en el mockup Stitch "Discover Habits and Creators":
/// hero + search + Featured Templates (carrusel horizontal) + Trending Creators (grid 2 cols).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final CommunityTemplateRepository _templateRepo;
  late final PublicProfileRepository _profileRepo;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // featured (populares) — carrusel
  List<CommunityTemplateModel> _featured = [];
  bool _loadingFeatured = true;

  // trending creators — grid
  List<PublicProfileModel> _creators = [];
  bool _loadingCreators = true;

  // resultados de búsqueda (mezclados)
  List<CommunityTemplateModel> _searchTemplates = [];
  List<PublicProfileModel> _searchCreators = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _templateRepo = CommunityTemplateRepository(uid: uid);
    _profileRepo = PublicProfileRepository(uid: uid);
    _loadFeatured();
    _loadCreators();
    _searchController.addListener(_onQueryChanged);
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

  Future<void> _loadCreators() async {
    final res = await _profileRepo.watchPublicProfilesFeed(limit: 6);
    if (!mounted) return;
    setState(() {
      _creators = res.profiles;
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
          _searchCreators = [];
          _searching = false;
        });
        return;
      }
      setState(() => _searching = true);
      // buscamos plantillas client-side sobre el pool popular + creadores por username
      final creators = await _profileRepo.searchByUsername(q);
      final templates = _featured
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.authorUsername.toLowerCase().contains(q))
          .toList();
      if (!mounted) return;
      setState(() {
        _searchCreators = creators;
        _searchTemplates = templates;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                    'HabitAI',
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
                  onPressed: () => context.goNamed('settings'),
                ),
              ],
            ),

            // ---------- Hero ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  'Descubre hábitos\ny creadores',
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

  // ==================== FEATURED TEMPLATES ====================

  Widget _buildFeaturedSection(ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Plantillas destacadas',
            action: 'Ver todas',
            onAction: () => context.goNamed('community-feed'),
          ),
          const SizedBox(height: 12),
          if (_loadingFeatured)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_featured.isEmpty)
            _EmptyInline(
              icon: Icons.storefront_outlined,
              text: 'Aún no hay plantillas publicadas',
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
                      context.go('/community/${_featured[i].id}'),
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
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Creadores destacados',
            action: 'Ver todos',
            onAction: () => context.goNamed('public-profiles-feed'),
          ),
          const SizedBox(height: 12),
          if (_loadingCreators)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_creators.isEmpty)
            _EmptyInline(
              icon: Icons.people_outline_rounded,
              text: 'Aún no hay perfiles públicos',
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
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (_, i) => _CreatorCard(
                  profile: _creators[i],
                  highlighted: i < 2,
                  onTap: () => context.goNamed(
                    'public-profile',
                    pathParameters: {'userId': _creators[i].uid},
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 80 * i.clamp(0, 6)),
                      duration: 280.ms,
                    )
                    .slideY(begin: 0.08, end: 0, duration: 320.ms),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SEARCH RESULTS ====================

  List<Widget> _buildSearchResults(ColorScheme scheme) {
    if (_searching) {
      return const [
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_searchTemplates.isEmpty && _searchCreators.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyInline(
            icon: Icons.manage_search_rounded,
            text: 'Sin resultados para "$_query"',
          ),
        ),
      ];
    }
    return [
      if (_searchTemplates.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Plantillas',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverList.separated(
          itemCount: _searchTemplates.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FeaturedTemplateCard(
              template: _searchTemplates[i],
              full: true,
              onTap: () =>
                  context.go('/community/${_searchTemplates[i].id}'),
            ),
          ),
        ),
      ],
      if (_searchCreators.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Creadores',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.builder(
            itemCount: _searchCreators.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (_, i) => _CreatorCard(
              profile: _searchCreators[i],
              highlighted: false,
              onTap: () => context.goNamed(
                'public-profile',
                pathParameters: {'userId': _searchCreators[i].uid},
              ),
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar plantillas, creadores…',
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                          : 'Por @${template.authorUsername}',
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
                      '${template.habitCount} hábitos',
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
                        children: const [
                          Icon(Icons.download_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Importar',
                            style: TextStyle(
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
  final VoidCallback onTap;

  const _CreatorCard({
    required this.profile,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppTheme.tertiaryContainer, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${profile.bestStreakEver}',
                        style: const TextStyle(
                          color: AppTheme.tertiaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${profile.totalHabits} hábitos',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
