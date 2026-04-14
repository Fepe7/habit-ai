import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../data/ai_repository.dart';
import '../domain/weekly_review_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/presentation/widgets/edit_habit_sheet.dart';

// Pantalla con la revision semanal generada por la IA
class WeeklyReviewScreen extends StatefulWidget {
  final String weekId;

  const WeeklyReviewScreen({super.key, required this.weekId});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  late AIRepository _aiRepo;
  late HabitRepository _habitRepo;
  bool _initialized = false;
  WeeklyReviewModel? _review;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _aiRepo = AIRepository(uid: user.uid);
        _habitRepo = HabitRepository(uid: user.uid);
        _load();
      }
      _initialized = true;
    }
  }

  Future<void> _load() async {
    try {
      final review = await _aiRepo.getReviewForWeek(widget.weekId);
      if (mounted) {
        setState(() {
          _review = review;
          _loading = false;
          _error = review == null ? 'No se encontró esta revisión' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error al cargar la revisión';
        });
      }
    }
  }

  // Abre el EditHabitSheet del habito al que apunta una recomendacion
  Future<void> _applyRecommendation(ReviewRecommendation rec) async {
    final habit = await _habitRepo.getHabit(rec.habitId);
    if (!mounted) return;

    if (habit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este hábito ya no existe'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final updated = await EditHabitSheet.show(context, habit);
    if (updated == null || !mounted) return;

    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito actualizado'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el hábito'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión semanal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _buildContent(context, _review!),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeeklyReviewModel review) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, review).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),

          if (review.focus.isNotEmpty) ...[
            _buildFocusCard(context, review.focus)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 20),
          ],

          if (review.wins.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Lo que funcionó',
              icon: Icons.thumb_up_rounded,
              color: AppTheme.success,
              items: review.wins,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 20),
          ],

          if (review.struggles.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Dónde fallaste',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.error,
              items: review.struggles,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 20),
          ],

          if (review.recommendations.isNotEmpty) ...[
            _buildRecommendations(context, review.recommendations)
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // Cabecera con el rango de fechas y stats de la semana
  Widget _buildHeader(BuildContext context, WeeklyReviewModel review) {
    final colorScheme = Theme.of(context).colorScheme;
    final start = _formatDate(review.weekStart);
    final end = _formatDate(review.weekEnd);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            AppTheme.primaryContainer.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: AppTheme.primary.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Semana ${review.weekId}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$start — $end',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(
                context,
                value: '${review.stats.totalLogs}',
                label: 'Check-ins',
                color: AppTheme.success,
              ),
              const SizedBox(width: 12),
              _headerStat(
                context,
                value: '${review.stats.totalHabits}',
                label: 'Hábitos',
                color: AppTheme.primary,
              ),
              if (review.stats.habitsAtRisk.isNotEmpty) ...[
                const SizedBox(width: 12),
                _headerStat(
                  context,
                  value: '${review.stats.habitsAtRisk.length}',
                  label: 'En riesgo',
                  color: AppTheme.error,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Card principal con el consejo focus
  Widget _buildFocusCard(BuildContext context, String focus) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.tertiaryContainer.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppTheme.tertiary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu foco esta semana',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  focus,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Seccion generica wins/struggles
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bloque de recomendaciones con boton de aplicar
  Widget _buildRecommendations(
    BuildContext context,
    List<ReviewRecommendation> recommendations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...recommendations.map((rec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.habitTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec.action,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                  ),
                  if (rec.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      rec.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: rec.habitId.isEmpty
                          ? null
                          : () => _applyRecommendation(rec),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Aplicar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
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

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
