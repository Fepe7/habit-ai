import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/data/habit_repository.dart';
import '../../../habits/domain/habit_log_model.dart';
import '../../../habits/domain/habit_model.dart';
import 'categories_step.dart';
import 'confetti_burst.dart';

// Paso 5: primer check-in. El usuario marca un hábito recién creado y se
// lleva su primera victoria (racha de 1 día) antes de salir del onboarding.
class FirstCheckinStep extends StatefulWidget {
  final List<HabitModel> habits;
  final HabitRepository habitRepo;
  final VoidCallback onContinue;

  const FirstCheckinStep({
    super.key,
    required this.habits,
    required this.habitRepo,
    required this.onContinue,
  });

  @override
  State<FirstCheckinStep> createState() => _FirstCheckinStepState();
}

class _FirstCheckinStepState extends State<FirstCheckinStep> {
  final Set<String> _completed = {};
  int _confettiKey = 0;

  Future<void> _checkIn(HabitModel habit) async {
    if (_completed.contains(habit.id)) return;
    // Feedback inmediato; la escritura va por detrás (patrón de HabitsScreen)
    unawaited(FeedbackService.instance.habitCompleted());
    setState(() {
      _completed.add(habit.id);
      _confettiKey++;
    });
    try {
      final log = HabitLogModel(
        id: '',
        date: DateTime.now(),
        completed: true,
      );
      await widget.habitRepo.addLog(habit.id, log);
      unawaited(widget.habitRepo.updateStreak(habit.id).catchError((_) {}));
    } catch (_) {
      // Si falla la escritura no rompemos el onboarding: el usuario podrá
      // marcarlo de nuevo desde la pantalla de hábitos
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasFirstWin = _completed.isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                s.onbCheckinTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                s.onbCheckinSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.habits.length,
                  itemBuilder: (context, i) {
                    final habit = widget.habits[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CheckableHabitCard(
                        habit: habit,
                        isCompleted: _completed.contains(habit.id),
                        streakLabel: s.onbCheckinStreak,
                        onTap: () => _checkIn(habit),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (250 + i * 110).ms, duration: 400.ms)
                        .slideY(
                          begin: 0.15,
                          delay: (250 + i * 110).ms,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // El CTA cambia de tono cuando ya hay una victoria
              FilledButton(
                onPressed: widget.onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: hasFirstWin
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.25),
                  foregroundColor:
                      hasFirstWin ? const Color(0xFF00668A) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(hasFirstWin ? s.confirm : s.onbCheckinLater),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        // Nueva explosión de confeti en cada check-in (la key reinicia el widget)
        if (_confettiKey > 0)
          Positioned.fill(
            child: ConfettiBurst(key: ValueKey(_confettiKey)),
          ),
      ],
    );
  }
}

// Card de hábito marcable: check con rebote, tachado y chip de racha
class _CheckableHabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompleted;
  final String streakLabel;
  final VoidCallback onTap;

  const _CheckableHabitCard({
    required this.habit,
    required this.isCompleted,
    required this.streakLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryBg = AppTheme.categoryBg(habit.category);
    final categoryFg = AppTheme.categoryFg(habit.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            // tinte suave de éxito al completar
            color: isCompleted
                ? const Color(0xFF059669).withValues(alpha: 0.10)
                : Colors.transparent,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF059669).withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                scale: isCompleted ? 1.1 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF059669) : Colors.white,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF059669)
                          : AppTheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: isCompleted
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(habit.title),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryBg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            CategoriesStep.categoryLabel(
                              context,
                              habit.category,
                            ),
                            style: TextStyle(
                              color: categoryFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chip de racha que aparece al completar
                        AnimatedScale(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          scale: isCompleted ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.streakGradient,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              streakLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
