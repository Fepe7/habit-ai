import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/habit_model.dart';

// Card de un habito individual con checkbox y info
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);

    return Card(
      color: isCompletedToday
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // checkbox circular
              _CheckCircle(
                isCompleted: isCompletedToday,
                color: catFg,
              ),
              const SizedBox(width: 16),

              // titulo + descripcion + racha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompletedToday
                            ? colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // racha
                        if (habit.currentStreak > 0) ...[
                          const Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} días',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // categoria con colores propios
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            habit.category,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: catFg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // hora recordatorio
                        if (habit.reminderTime != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.reminderTime!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // icono de check si completado
              if (isCompletedToday)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// circulo con check animado
class _CheckCircle extends StatelessWidget {
  final bool isCompleted;
  final Color color;

  const _CheckCircle({
    required this.isCompleted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? color : Colors.transparent,
        border: Border.all(
          color: isCompleted ? color : color.withValues(alpha: 0.4),
          width: 2.5,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }
}
