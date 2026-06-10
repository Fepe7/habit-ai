import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai/domain/habit_plan_model.dart';
import 'categories_step.dart';
import 'confetti_burst.dart';

// Fragmento de la "receta" del plan: las partes que vienen de las
// respuestas del usuario van resaltadas
class RecipeSegment {
  final String text;
  final bool highlighted;

  const RecipeSegment(this.text, {this.highlighted = false});
}

// Paso 3: el momento "wow" — la IA genera el plan con una secuencia narrada
// y los hábitos entran en cascada. El usuario puede destildar los que no quiera.
class PlanStep extends StatefulWidget {
  // Genera (o regenera) el plan llamando a la Cloud Function
  final Future<HabitPlanModel> Function({required bool regenerate}) generate;

  // Guarda los hábitos aceptados; el padre avanza al siguiente paso al acabar
  final Future<void> Function(
    HabitPlanModel plan,
    List<GeneratedHabitModel> accepted,
  ) onAccept;

  // Resumen de las respuestas del usuario, se escribe solo durante la espera
  final List<RecipeSegment> Function() buildRecipe;

  const PlanStep({
    super.key,
    required this.generate,
    required this.onAccept,
    required this.buildRecipe,
  });

  @override
  State<PlanStep> createState() => PlanStepState();
}

class PlanStepState extends State<PlanStep> {
  HabitPlanModel? _plan;
  String? _error;
  bool _isGenerating = false;
  bool _isSaving = false;
  final Set<int> _rejected = {};

  Timer? _phaseTimer;
  int _phaseIndex = 0;

  // El padre lo llama cuando el PageView llega a este paso
  void startGeneration() {
    if (_plan == null && !_isGenerating) _generate(regenerate: false);
  }

  Future<void> _generate({required bool regenerate}) async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _plan = null;
      _rejected.clear();
      _phaseIndex = 0;
    });
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) setState(() => _phaseIndex = (_phaseIndex + 1) % 3);
    });

    try {
      final plan = await widget.generate(regenerate: regenerate);
      _phaseTimer?.cancel();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _plan = plan;
        _isGenerating = false;
      });
    } catch (e) {
      _phaseTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _error = e is String ? e : S.of(context).onbPlanError;
        _isGenerating = false;
      });
    }
  }

  Future<void> _accept() async {
    final plan = _plan;
    if (plan == null || _isSaving) return;
    final accepted = [
      for (int i = 0; i < plan.habits.length; i++)
        if (!_rejected.contains(i)) plan.habits[i],
    ];
    setState(() => _isSaving = true);
    try {
      await widget.onAccept(plan, accepted);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _GeneratingView(
        phaseIndex: _phaseIndex,
        recipe: widget.buildRecipe(),
      );
    }
    if (_error != null) return _buildError(context);
    if (_plan != null) return _buildPlan(context);
    // Estado inicial antes de llegar al paso: mismo visual que generando
    return _GeneratingView(phaseIndex: _phaseIndex, recipe: const []);
  }

  Widget _buildError(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 64)
              .animate()
              .fadeIn(duration: 400.ms)
              .shake(hz: 3, duration: 500.ms),
          const SizedBox(height: 20),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _generate(regenerate: false),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00668A),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.onbRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(BuildContext context) {
    final s = S.of(context);
    final plan = _plan!;
    final acceptedCount = plan.habits.length - _rejected.length;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                s.onbPlanReadyTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 6),
              Text(
                '${plan.planEmoji ?? '✨'} ${plan.planTitle}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: plan.habits.length,
                  itemBuilder: (context, i) {
                    final habit = plan.habits[i];
                    final isAccepted = !_rejected.contains(i);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitPreviewCard(
                        habit: habit,
                        isAccepted: isAccepted,
                        onToggle: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            isAccepted ? _rejected.add(i) : _rejected.remove(i);
                          });
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (300 + i * 120).ms, duration: 400.ms)
                        .slideY(
                          begin: 0.15,
                          delay: (300 + i * 120).ms,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: acceptedCount == 0 || _isSaving ? null : _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00668A),
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(s.onbAcceptPlan),
              ),
              TextButton(
                onPressed: _isSaving ? null : () => _generate(regenerate: true),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(s.onbRegenerate),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Confeti de celebración al aparecer el plan
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}

// Secuencia narrada mientras la Cloud Function trabaja: receta del usuario
// escribiéndose sola + orbe pulsante + frases que rotan. Nunca un spinner a secas.
class _GeneratingView extends StatelessWidget {
  final int phaseIndex;
  final List<RecipeSegment> recipe;

  const _GeneratingView({required this.phaseIndex, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final phases = [s.onbGenPhase1, s.onbGenPhase2, s.onbGenPhase3];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (recipe.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: _RecipeTypewriter(segments: recipe),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
        // Orbe IA: núcleo pulsante + anillo girando
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF34D399)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.12, 1.12),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -5),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              phases[phaseIndex % phases.length],
              key: ValueKey(phaseIndex),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

// Escribe la receta carácter a carácter, con las respuestas del usuario
// resaltadas en ámbar y un cursor parpadeante mientras teclea
class _RecipeTypewriter extends StatefulWidget {
  final List<RecipeSegment> segments;

  const _RecipeTypewriter({required this.segments});

  @override
  State<_RecipeTypewriter> createState() => _RecipeTypewriterState();
}

class _RecipeTypewriterState extends State<_RecipeTypewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _totalChars;

  @override
  void initState() {
    super.initState();
    _totalChars =
        widget.segments.fold(0, (sum, seg) => sum + seg.text.length);
    _controller = AnimationController(
      vsync: this,
      // ~28ms por carácter: legible sin hacerse eterno
      duration: Duration(milliseconds: 400 + _totalChars * 28),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final visible =
            (Curves.easeOut.transform(_controller.value) * _totalChars)
                .round();
        final spans = <TextSpan>[];
        var remaining = visible;
        for (final seg in widget.segments) {
          if (remaining <= 0) break;
          final take = remaining.clamp(0, seg.text.length);
          spans.add(TextSpan(
            text: seg.text.substring(0, take),
            style: seg.highlighted
                ? const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                  )
                : null,
          ));
          remaining -= take;
        }
        if (!_controller.isCompleted) {
          spans.add(const TextSpan(text: '▌'));
        }
        return Text.rich(
          TextSpan(
            children: spans,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

// Card de hábito propuesto, destildable
class _HabitPreviewCard extends StatelessWidget {
  final GeneratedHabitModel habit;
  final bool isAccepted;
  final VoidCallback onToggle;

  const _HabitPreviewCard({
    required this.habit,
    required this.isAccepted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categoryBg = AppTheme.categoryBg(habit.category);
    final categoryFg = AppTheme.categoryFg(habit.category);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isAccepted ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAccepted ? const Color(0xFF059669) : Colors.white,
                    border: Border.all(
                      color: isAccepted
                          ? const Color(0xFF059669)
                          : AppTheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: isAccepted
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
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
                          if (habit.suggestedTime != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              habit.suggestedTime!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
