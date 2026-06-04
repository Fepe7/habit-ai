import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../app.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../l10n/app_localizations.dart';
import '../data/ai_repository.dart';
import '../domain/butterfly_projection_model.dart';

/// Pantalla de detalle del Simulador Efecto Mariposa.
/// Muestra dos historias inmersivas: si mantienes los hábitos vs si los abandonas.
class ButterflyProjectionScreen extends StatefulWidget {
  final String monthId;

  const ButterflyProjectionScreen({super.key, required this.monthId});

  @override
  State<ButterflyProjectionScreen> createState() =>
      _ButterflyProjectionScreenState();
}

class _ButterflyProjectionScreenState extends State<ButterflyProjectionScreen> {
  late AIRepository _aiRepo;
  ButterflyProjectionModel? _projection;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _aiRepo = AIRepository(uid: user.uid);
        _loadProjection();
      }
      _initialized = true;
    }
  }

  Future<void> _loadProjection() async {
    final projection = await _aiRepo.getProjectionForMonth(widget.monthId);
    if (mounted) {
      setState(() {
        _projection = projection;
        _loading = false;
      });
    }
  }

  // Convierte "2026-04" en "Abril 2026"
  String _formatMonthId(String monthId, S s) {
    final meses = _fullMonthNames(s);
    final parts = monthId.split('-');
    if (parts.length != 2) return monthId;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = parts[0];
    return '${meses[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Text('🦋', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _formatMonthId(widget.monthId, s),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SectionSkeleton(itemCount: 3),
            )
          : _projection == null
              ? _buildError(context)
              : _buildContent(context, _projection!),
    );
  }

  Widget _buildError(BuildContext context) {
    return ErrorStateView(
      message: S.of(context).butterflyNotFound,
      icon: Icons.cloud_off_outlined,
    );
  }

  Widget _buildContent(BuildContext context, ButterflyProjectionModel p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips de estadísticas del mes
          _buildStatsChips(context, p.stats)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 20),

          // Historia positiva
          _buildStoryCard(
            context,
            title: p.titleKeep,
            story: p.storyKeep,
            isPositive: true,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.06),

          const SizedBox(height: 14),

          // Historia de abandono
          _buildStoryCard(
            context,
            title: p.titleAbandon,
            story: p.storyAbandon,
            isPositive: false,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.06),

          if (p.keyMoments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildKeyMoments(context, p.keyMoments)
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.06),
          ],

          if (p.closingMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildClosingCard(context, p.closingMessage)
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.06),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsChips(BuildContext context, ButterflyStats stats) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final pct = (stats.completionRate * 100).round();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          icon: Icons.check_circle_rounded,
          label: s.butterflyCheckins(stats.totalLogs),
          color: AppTheme.primary,
        ),
        _Chip(
          icon: Icons.calendar_today_rounded,
          label: s.exploreHabitCount(stats.activeHabits),
          color: AppTheme.secondary,
        ),
        _Chip(
          icon: Icons.local_fire_department_rounded,
          label: s.butterflyStreakDays(stats.longestStreak),
          color: AppTheme.tertiary,
        ),
        _Chip(
          icon: Icons.percent_rounded,
          label: s.butterflyCompletion(pct),
          color: scheme.primary,
        ),
      ],
    );
  }

  Widget _buildStoryCard(
    BuildContext context, {
    required String title,
    required String story,
    required bool isPositive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isPositive
            ? LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.secondary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF64748B).withValues(alpha: 0.10),
                  const Color(0xFF475569).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
        border: Border.all(
          color: isPositive
              ? AppTheme.primary.withValues(alpha: 0.18)
              : const Color(0xFF94A3B8).withValues(alpha: 0.20),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPositive ? '🌟' : '🌧️',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            story,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: isPositive ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMoments(
      BuildContext context, List<ButterflyKeyMoment> moments) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                S.of(context).butterflyKeyMoments,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...moments.asMap().entries.map((entry) {
            final i = entry.key;
            final moment = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < moments.length - 1 ? 14 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.habitTitle,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          moment.impact,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClosingCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.tertiary.withValues(alpha: 0.14),
            AppTheme.tertiaryContainer.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
        border: Border.all(
          color: AppTheme.tertiary.withValues(alpha: 0.20),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🦋', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// nombres completos de meses localizados (enero→diciembre)
List<String> _fullMonthNames(S s) => [
      s.monthFullJan,
      s.monthFullFeb,
      s.monthFullMar,
      s.monthFullApr,
      s.monthFullMay,
      s.monthFullJun,
      s.monthFullJul,
      s.monthFullAug,
      s.monthFullSep,
      s.monthFullOct,
      s.monthFullNov,
      s.monthFullDec,
    ];

/// Chip de estadística compacto
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
