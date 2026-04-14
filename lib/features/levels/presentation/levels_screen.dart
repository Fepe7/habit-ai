import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../data/levels_repository.dart';
import '../domain/level_model.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<LevelsProfile>(
              future: _levelsRepo!.computeProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              child: _CategoryLevelCard(
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_rounded, size: 72, color: scheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Empieza a crear hábitos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completa check-ins para subir de nivel en cada categoría.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetail(BuildContext context, CategoryLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryDetailSheet(level: level),
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

// ─── Card de categoría ────────────────────────────────────────────────────────

class _CategoryLevelCard extends StatelessWidget {
  final CategoryLevel level;
  final VoidCallback onTap;

  const _CategoryLevelCard({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgColor = AppTheme.categoryFg(level.category);
    final bgColor = AppTheme.categoryBg(level.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.12)),
          boxShadow: AppTheme.ambientShadow(),
        ),
        child: Row(
          children: [
            // icono de categoría
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                AppTheme.categoryIcon(level.category),
                color: fgColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // info nivel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppTheme.categoryLabel(level.category),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: fgColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Nvl ${level.level}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: fgColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.titleCurrent,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // barra de progreso hacia siguiente nivel
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: level.progressToNext,
                            minHeight: 5,
                            backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(fgColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level.level < 5
                            ? '${level.xpToNext} XP'
                            : 'Máx.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet de detalle ──────────────────────────────────────────────────

class _CategoryDetailSheet extends StatelessWidget {
  final CategoryLevel level;

  const _CategoryDetailSheet({required this.level});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgColor = AppTheme.categoryFg(level.category);
    final bgColor = AppTheme.categoryBg(level.category);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // cabecera
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(AppTheme.categoryIcon(level.category), color: fgColor, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTheme.categoryLabel(level.category),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    level.titleCurrent,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              // nivel grande
              Column(
                children: [
                  Text(
                    'Nvl',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '${level.level}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // XP total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP acumulado', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              Text('${level.xp} XP', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),

          const SizedBox(height: 14),

          // barra de progreso
          if (level.level < 5) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  level.titleCurrent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fgColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  level.titleNext ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: level.progressToNext,
                minHeight: 10,
                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(fgColor),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Faltan ${level.xpToNext} XP para ${level.titleNext}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: fgColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '¡Nivel máximo alcanzado!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // cómo ganar XP
          Text(
            'Cómo ganar XP',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _XpTip(icon: Icons.check_circle_outline_rounded, text: '+10 XP por cada check-in completado', color: fgColor),
          const SizedBox(height: 6),
          _XpTip(icon: Icons.local_fire_department_rounded, text: '+5 XP por día de racha activa (máx. +50)', color: fgColor),
          const SizedBox(height: 6),
          _XpTip(icon: Icons.emoji_events_rounded, text: '+50 XP por cada logro desbloqueado', color: fgColor),
        ],
      ),
    );
  }
}

class _XpTip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _XpTip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
