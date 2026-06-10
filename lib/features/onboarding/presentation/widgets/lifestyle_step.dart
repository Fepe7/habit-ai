import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/app_localizations.dart';

// Respuestas del micro-quiz de estilo de vida (paso 2)
class LifestyleAnswers {
  String? energyMoment;
  String? timeBudget;
  String? blocker;

  bool get isComplete =>
      energyMoment != null && timeBudget != null && blocker != null;
}

// Paso 2: tres preguntas rápidas tipo card que dan contexto real a la IA
class LifestyleStep extends StatelessWidget {
  final LifestyleAnswers answers;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  const LifestyleStep({
    super.key,
    required this.answers,
    required this.onChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            s.onbLifestyleTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            s.onbLifestyleSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _QuestionBlock(
                  index: 0,
                  question: s.onbQ1,
                  options: [
                    _Option('🌅', s.onbQ1Morning),
                    _Option('☀️', s.onbQ1Afternoon),
                    _Option('🌙', s.onbQ1Night),
                  ],
                  selected: answers.energyMoment,
                  onSelect: (value) {
                    answers.energyMoment = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 20),
                _QuestionBlock(
                  index: 1,
                  question: s.onbQ2,
                  options: [
                    _Option('⏱️', s.onbQ2Short),
                    _Option('⏲️', s.onbQ2Medium),
                    _Option('🕐', s.onbQ2Long),
                  ],
                  selected: answers.timeBudget,
                  onSelect: (value) {
                    answers.timeBudget = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 20),
                _QuestionBlock(
                  index: 2,
                  question: s.onbQ3,
                  options: [
                    _Option('🚀', s.onbQ3Start),
                    _Option('📉', s.onbQ3Consistency),
                    _Option('🗺️', s.onbQ3Plan),
                  ],
                  selected: answers.blocker,
                  onSelect: (value) {
                    answers.blocker = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: answers.isComplete ? 1 : 0.45,
            child: FilledButton(
              onPressed: answers.isComplete ? onContinue : null,
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
              child: Text(s.onbGeneratePlan),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Option {
  final String emoji;
  final String label;
  const _Option(this.emoji, this.label);
}

// Pregunta con sus opciones como tiles seleccionables de ancho completo
class _QuestionBlock extends StatelessWidget {
  final int index;
  final String question;
  final List<_Option> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _QuestionBlock({
    required this.index,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              option: option,
              isSelected: selected == option.label,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(option.label);
              },
            ),
          ),
      ],
    )
        .animate()
        .fadeIn(delay: (250 + index * 150).ms, duration: 400.ms)
        .slideY(
          begin: 0.15,
          delay: (250 + index * 150).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: isSelected ? 1.02 : 1,
      child: Material(
        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: isSelected ? 0 : 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00668A)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  scale: isSelected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00668A),
                    size: 22,
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
