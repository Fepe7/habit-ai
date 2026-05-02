import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/habit_model.dart';
import '../../../ai/domain/renegotiation_model.dart';

/// Card de un habito con zonas de tap separadas:
/// - circulo izquierdo: toggle completado
/// - resto del card: navegar a detalle
/// [isInsideGroup] elimina sombra propia cuando va dentro de un contenedor padre
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isInsideGroup;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onEnterSelection;
  final VoidCallback? onToggleSelect;
  final RenegotiationModel? renegotiation;
  final VoidCallback? onApplyRenegotiation;
  final VoidCallback? onDismissRenegotiation;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isInsideGroup = false,
    this.selectionMode = false,
    this.isSelected = false,
    this.onEnterSelection,
    this.onToggleSelect,
    this.renegotiation,
    this.onApplyRenegotiation,
    this.onDismissRenegotiation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
    final catIcon = AppTheme.categoryIcon(habit.category);

    final cardBg = isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.25)
        : isCompletedToday
            ? scheme.primaryContainer.withValues(alpha: 0.18)
            : isInsideGroup
                ? Colors.transparent
                : scheme.surfaceContainerLowest;

    final hasPendingReno = renegotiation != null && renegotiation!.isPending;

    Widget card = GestureDetector(
      onLongPress: selectionMode ? null : onEnterSelection,
      child: Container(
      color: isInsideGroup ? cardBg : null,
      clipBehavior: isInsideGroup ? Clip.none : Clip.antiAlias,
      decoration: isInsideGroup
          ? null
          : BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: habit.currentStreak >= 7
                  ? AppTheme.tintedShadow(AppTheme.tertiary)
                  : isCompletedToday
                      ? AppTheme.tintedShadow(AppTheme.primary, opacity: 0.14)
                      : AppTheme.ambientShadow(),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // en modo selección: checkbox; si no: circulo de check
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect?.call(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _CheckCircle(
                    isCompleted: isCompletedToday,
                    categoryColor: catFg,
                  ),
                ),
              ),

            // contenido — tap para navegar a detalle (o seleccionar en modo selección)
            Expanded(
              child: InkWell(
                onTap: selectionMode ? onToggleSelect : onTap,
                onLongPress: selectionMode ? null : onEdit,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              habit.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: isCompletedToday
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor:
                                    scheme.onSurface.withValues(alpha: 0.4),
                                color: isCompletedToday
                                    ? scheme.onSurface.withValues(alpha: 0.45)
                                    : scheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // racha activa
                          if (habit.currentStreak > 0)
                            _MetaChip(
                              icon: Icons.local_fire_department_rounded,
                              label: '${habit.currentStreak} días',
                              iconColor: AppTheme.tertiaryContainer,
                              textColor: AppTheme.tertiary,
                              bgColor: AppTheme.tertiaryContainer.withValues(alpha: 0.15),
                            ),
                          // chip de categoria
                          Hero(
                            tag: 'habit_cat_${habit.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: _MetaChip(
                                icon: catIcon,
                                label: AppTheme.categoryLabel(habit.category),
                                iconColor: catFg,
                                textColor: catFg,
                                bgColor: catBg,
                              ),
                            ),
                          ),
                          // hora recordatorio
                          if (habit.reminderTime != null)
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: habit.reminderTime!,
                              iconColor: scheme.onSurfaceVariant,
                              textColor: scheme.onSurfaceVariant,
                              bgColor: scheme.surfaceContainerHighest,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // icono de completado con bounce / menu (oculto en modo selección)
            if (!selectionMode) ...[
              if (isCompletedToday)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                )
              else if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (ctx) => [
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
          ],
        ),
      ),
        if (hasPendingReno)
          _CoachBanner(
            renegotiation: renegotiation!,
            onApply: onApplyRenegotiation,
            onDismiss: onDismissRenegotiation,
          ),
        ],      // cierra Column.children
      ),        // cierra Column
    ));

    // separador sutil entre cards dentro de grupo (sin linea 1px visible)
    if (isInsideGroup) {
      return card;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: card,
    );
  }
}

// ==================== CHECK CIRCLE ====================

class _CheckCircle extends StatefulWidget {
  final bool isCompleted;
  final Color categoryColor;

  const _CheckCircle({required this.isCompleted, required this.categoryColor});

  @override
  State<_CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<_CheckCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_CheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scale,
      builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.isCompleted
          ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.heroGradient,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            )
          : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: widget.categoryColor.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
            ),
    );
  }
}

// ==================== COACH BANNER ====================

class _CoachBanner extends StatelessWidget {
  final RenegotiationModel renegotiation;
  final VoidCallback? onApply;
  final VoidCallback? onDismiss;

  const _CoachBanner({
    required this.renegotiation,
    this.onApply,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '– COACH · PREGUNTA DEL DÍA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${renegotiation.diagnosis}"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onApply,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'SÍ, HAZLO →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OTRA OPCIÓN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== META CHIP ====================

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color bgColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
