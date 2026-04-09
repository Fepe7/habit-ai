import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/habit_model.dart';

// Card de un habito con zonas de tap separadas:
// - circulo: toggle completado
// - resto del card: navegar a detalle
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
    final catIcon = AppTheme.categoryIcon(habit.category);

    return Card(
      color: isCompletedToday
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // circulo de check — zona de tap independiente
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _CheckCircle(
                  isCompleted: isCompletedToday,
                  color: catFg,
                ),
              ),
            ),

            // contenido del card — tap para navegar a detalle
            Expanded(
              child: InkWell(
                onTap: onTap,
                onLongPress: onEdit,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                          Hero(
                            tag: 'habit_cat_${habit.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: catBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(catIcon, size: 12, color: catFg),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppTheme.categoryLabel(habit.category),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: catFg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
              ),
            ),

            // menu o check con animacion
            if (isCompletedToday)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                  ),
                ),
              )
            else if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                          const SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// circulo con check animado + bounce al completar
class _CheckCircle extends StatefulWidget {
  final bool isCompleted;
  final Color color;

  const _CheckCircle({
    required this.isCompleted,
    required this.color,
  });

  @override
  State<_CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<_CheckCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_CheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // bounce solo al marcar como completado
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCompleted ? widget.color : Colors.transparent,
          border: Border.all(
            color: widget.isCompleted
                ? widget.color
                : widget.color.withValues(alpha: 0.4),
            width: 2.5,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.isCompleted
              ? const Icon(Icons.check, size: 18, color: Colors.white,
                  key: ValueKey('check'))
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }
}
