import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app.dart';
import '../../../core/router/main_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../data/levels_repository.dart';
import '../domain/level_model.dart';
import 'widgets/category_level_card.dart';

/// Pantalla de perfil de maestría: radar hexagonal + niveles por categoría
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  LevelsRepository? _levelsRepo;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _levelsRepo = LevelsRepository(uid: user.uid);
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Maestría'),
        centerTitle: false,
      ),
      body: _levelsRepo == null
          ? const SectionSkeleton()
          : FutureBuilder<LevelsProfile>(
              future: _levelsRepo!.computeProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SectionSkeleton();
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildEmptyState(context);
                }

                final profile = snapshot.data!;
                if (profile.categories.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _buildContent(context, profile);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, LevelsProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, context.bottomNavInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header resumen
          _buildSummaryHeader(context, profile)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 20),

          // radar hexagonal
          _buildRadarCard(context, profile)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 20),

          Text(
            'Por categoría',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 12),

          // cards por categoría (todas las 6, activas o no)
          ...AppTheme.categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final level = profile.categories[category] ??
                CategoryLevel.fromXp(category, 0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CategoryLevelCard(
                level: level,
                onTap: () => _showCategoryDetail(context, level),
              )
                  .animate()
                  .fadeIn(delay: (250 + index * 60).ms, duration: 350.ms)
                  .slideX(begin: 0.03),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, LevelsProfile profile) {
    final top = profile.topCategory;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(opacity: 0.16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel medio',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.averageLevel.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${profile.totalXp} XP total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (top != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Más fuerte',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppTheme.categoryIcon(top.category),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        top.titleCurrent,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.categoryLabel(top.category),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarCard(BuildContext context, LevelsProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Radar de habilidades',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _HexRadarChart(profile: profile),
          ),
          const SizedBox(height: 12),
          // leyenda compacta
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: AppTheme.categories.map((cat) {
              final level = profile.categories[cat];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.categoryFg(cat),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppTheme.categoryLabel(cat)} ${level != null ? 'Nvl ${level.level}' : '-'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.military_tech_rounded,
      title: 'Empieza a crear hábitos',
      subtitle: 'Completa check-ins para subir de nivel en cada categoría.',
    );
  }

  void _showCategoryDetail(BuildContext context, CategoryLevel level) {
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDetailSheet(level: level),
    );
  }
}

// ─── Radar Chart ──────────────────────────────────────────────────────────────

class _HexRadarChart extends StatelessWidget {
  final LevelsProfile profile;

  const _HexRadarChart({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Construir dataSets: valores de nivel (0-5) para las 6 categorías
    final dataEntries = AppTheme.categories.map((cat) {
      final level = profile.categories[cat];
      return RadarEntry(value: level != null ? level.level.toDouble() : 0.0);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: dataEntries,
            fillColor: scheme.primary.withValues(alpha: 0.18),
            borderColor: scheme.primary,
            borderWidth: 2,
            entryRadius: 3,
          ),
        ],
        radarShape: RadarShape.polygon,
        tickCount: 5,
        ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        getTitle: (index, angle) {
          final cat = AppTheme.categories[index];
          return RadarChartTitle(
            text: AppTheme.categoryLabel(cat),
            angle: 0,
          );
        },
      ),
    );
  }
}

