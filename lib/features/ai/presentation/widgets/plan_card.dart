import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
import '../../../../core/theme/app_theme.dart';

// Tarjeta que muestra el plan generado por la IA con toggle por habito
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cabecera del plan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.plan.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.plan.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.plan.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

          const Divider(height: 1),

          // lista de habitos con checkbox
          ...widget.plan.habits.map((habit) => _HabitTile(
                habit: habit,
                enabled: !_saved,
                onChanged: (value) {
                  setState(() => habit.accepted = value);
                },
              )),

          // boton de guardar
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saved
                    ? null
                    : () {
                        widget.onSave();
                        setState(() => _saved = true);
                      },
                icon: Icon(_saved ? Icons.check : Icons.add),
                label: Text(
                  _saved ? 'Hábitos guardados' : 'Añadir hábitos seleccionados',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Fila de habito con checkbox y chip de categoria
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
    return CheckboxListTile(
      value: habit.accepted,
      onChanged: enabled ? (v) => onChanged(v ?? false) : null,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        habit.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habit.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                habit.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              _CategoryChip(category: habit.category),
              if (habit.suggestedTime != null)
                _InfoChip(
                  icon: Icons.schedule,
                  label: habit.suggestedTime!,
                ),
              _InfoChip(
                icon: Icons.repeat,
                label: _frequencyLabel(habit.frequency),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      default:
        return 'Personalizado';
    }
  }
}

// Chip con color segun la categoria
class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.categoryBg(category),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.categoryFg(category),
        ),
      ),
    );
  }
}

// Chip generico con icono + texto
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
