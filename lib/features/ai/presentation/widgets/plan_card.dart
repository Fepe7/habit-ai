import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../levels/presentation/category_l10n.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Tarjeta del plan generado por la IA con toggle por habito
class PlanCard extends StatefulWidget {
  final HabitPlanData plan;
  final VoidCallback onSave;

  const PlanCard({super.key, required this.plan, required this.onSave});

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cabecera con gradiente
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryContainer.withValues(alpha: 0.25),
                  AppTheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                if (widget.plan.emoji != null) ...[
                  Text(widget.plan.emoji!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(Icons.auto_awesome_rounded,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plan.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.plan.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.plan.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // lista de habitos con check custom
          ...widget.plan.habits.map((habit) => _HabitTile(
                habit: habit,
                enabled: !_saved,
                onChanged: (value) => setState(() => habit.accepted = value),
              )),

          // boton de guardar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GradientButton(
              onPressed: _saved
                  ? null
                  : () {
                      widget.onSave();
                      setState(() => _saved = true);
                    },
              label: _saved ? S.of(context).planCardSaved : S.of(context).planCardAddSelected,
              icon: _saved ? Icons.check_rounded : Icons.add_rounded,
              gradient: _saved ? null : AppTheme.heroGradient,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de hábito con checkbox custom (circulo con gradiente al activar)
class _HabitTile extends StatelessWidget {
  final HabitSuggestion habit;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _HabitTile({
    required this.habit,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final catBg = AppTheme.categoryBg(habit.category, scheme.brightness);
    final catFg = AppTheme.categoryFg(habit.category, scheme.brightness);

    return InkWell(
      onTap: enabled ? () => onChanged(!habit.accepted) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // check custom con gradiente
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: habit.accepted ? AppTheme.heroGradient : null,
                  color: habit.accepted ? null : Colors.transparent,
                  border: Border.all(
                    color: habit.accepted
                        ? Colors.transparent
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: habit.accepted
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: habit.accepted
                          ? scheme.onSurface.withValues(alpha: 0.5)
                          : scheme.onSurface,
                      decoration:
                          habit.accepted ? TextDecoration.lineThrough : null,
                      decorationColor:
                          scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      habit.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // chip categoria
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CategoryL10n.labelOf(habit.category, context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: catFg,
                          ),
                        ),
                      ),
                      if (habit.suggestedTime != null)
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: habit.suggestedTime!,
                          scheme: scheme,
                        ),
                      _InfoChip(
                        icon: Icons.repeat_rounded,
                        label: _frequencyLabel(habit.frequency, s),
                        scheme: scheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(String frequency, S s) {
    switch (frequency) {
      case 'daily':
        return s.planCardFrequencyDaily;
      case 'weekly':
        return s.planCardFrequencyWeekly;
      default:
        return s.planCardFrequencyCustom;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
