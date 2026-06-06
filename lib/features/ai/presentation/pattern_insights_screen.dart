import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_availability_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../data/ai_repository.dart';
import '../domain/pattern_insight_model.dart';

/// Pantalla de detalle para los insights de patrones de un período concreto
class PatternInsightsScreen extends StatefulWidget {
  final String periodId;

  const PatternInsightsScreen({super.key, required this.periodId});

  @override
  State<PatternInsightsScreen> createState() => _PatternInsightsScreenState();
}

class _PatternInsightsScreenState extends State<PatternInsightsScreen> {
  static const _accent = Color(0xFF6366F1);

  late AIRepository _aiRepo;
  bool _initialized = false;
  bool _regenerating = false;
  int _refreshKey = 0; // fuerza rebuild del FutureBuilder al regenerar

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = AuthProvider.of(context).currentUser;
      if (user != null) _aiRepo = AIRepository(uid: user.uid);
      _initialized = true;
    }
  }

  Future<void> _regenerate() async {
    if (!ConnectivityService.instance.isOnline.value) {
      if (mounted) {
        AppSnackBar.showInfo(context, S.of(context).patternInsightsNeedConnection);
      }
      return;
    }
    if (AiAvailabilityService.instance.isPaused.value) {
      if (mounted) {
        AppSnackBar.showInfo(context, S.of(context).aiPausedMessage);
      }
      return;
    }
    setState(() => _regenerating = true);
    try {
      final periodId = await _aiRepo.generatePatternInsights();
      if (!mounted) return;
      if (periodId == null) {
        AppSnackBar.showInfo(
          context,
          S.of(context).patternInsightsNeedMore,
        );
      } else {
        setState(() => _refreshKey++);
        AppSnackBar.showSuccess(context, S.of(context).patternInsightsUpdated);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  // Formatea "2026-05" → "Mayo 2026"
  String _formatPeriod(String periodId, S s) {
    final parts = periodId.split('-');
    if (parts.length < 2) return periodId;
    final months = [
      '',
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
    final month = int.tryParse(parts[1]) ?? 0;
    return '${months[month]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded, color: _accent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dashboardPatternsTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  _formatPeriod(widget.periodId, s),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<PatternInsightModel?>(
        key: ValueKey(_refreshKey),
        future: _aiRepo.getInsightsForPeriod(widget.periodId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final model = snapshot.data;
          if (model == null) {
            return _buildEmpty(context);
          }
          return _buildContent(context, model);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.analytics_rounded, color: _accent, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              s.patternInsightsEmptyTitle(_formatPeriod(widget.periodId, s)),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.patternInsightsEmptySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PatternInsightModel model) {

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // card de resumen
        _buildSummaryCard(context, model)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.04),

        const SizedBox(height: 16),

        // lista de insights
        ...model.insights.asMap().entries.map((entry) {
          final i = entry.key;
          final insight = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInsightCard(context, insight)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 80 + i * 60), duration: 350.ms)
                .slideY(begin: 0.04),
          );
        }),

        const SizedBox(height: 8),

        // botón regenerar
        Center(
          child: OutlinedButton.icon(
            onPressed: _regenerating ? null : _regenerate,
            icon: _regenerating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              _regenerating ? S.of(context).dashboardRegenerating : S.of(context).patternInsightsRegenerate,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const StadiumBorder(),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, PatternInsightModel model) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.12),
            _accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.daysLabel(model.stats.analyzedDays),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.butterflyCheckins(model.stats.totalLogs),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (model.dataQuality == 'limited')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.patternInsightsLimitedData,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            model.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.patternInsightsDetected(model.insights.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, PatternInsight insight) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final typeColor = insight.type.color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tipo + confianza
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(insight.type.icon, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      insight.type.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // dot de confianza
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: insight.confidenceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                insight.confidence == 'high'
                    ? s.patternInsightsConfidenceHigh
                    : insight.confidence == 'medium'
                        ? s.patternInsightsConfidenceMedium
                        : s.patternInsightsConfidenceLow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // título
          Text(
            insight.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          // descripción
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          // chips de hábitos relacionados
          if (insight.relatedHabits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: insight.relatedHabits
                  .map((habit) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          habit,
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],

          // consejo accionable
          if (insight.actionable.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: typeColor, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: typeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.actionable,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
