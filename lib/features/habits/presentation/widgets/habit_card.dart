import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../levels/presentation/category_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/habit_model.dart';

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

  // --- Stacking ---
  // true si este hábito es el siguiente en completarse dentro de su cadena
  final bool isNextInStack;
  // posición en la cadena (0 = ancla, 1+ = encadenados)
  final int stackPosition;
  // total de hábitos en la cadena (0 si no pertenece a ninguna)
  final int stackTotal;
  // título del hábito que completó el usuario para llegar aquí (contexto del nudge)
  final String? nudgeFromHabitTitle;
  // si se pasa, reemplaza onEnterSelection en el long press (p.ej. modo reorden de cadena)
  final VoidCallback? onLongPressOverride;
  // true mientras la escritura de este hábito aún no se ha confirmado en servidor
  final bool pendingSync;

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
    this.isNextInStack = false,
    this.stackPosition = 0,
    this.stackTotal = 0,
    this.nudgeFromHabitTitle,
    this.onLongPressOverride,
    this.pendingSync = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final catBg = AppTheme.categoryBg(habit.category, scheme.brightness);
    final catFg = AppTheme.categoryFg(habit.category, scheme.brightness);
    final catIcon = AppTheme.categoryIcon(habit.category);

    // Modo "En Llamas": racha > 5 días → realce visual (borde ámbar brillante,
    // glow reforzado y llama animada en el chip de racha).
    final isOnFire = habit.currentStreak > 5;

    final cardBg = isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.25)
        : isCompletedToday
            ? scheme.primaryContainer.withValues(alpha: 0.18)
            : isInsideGroup
                ? Colors.transparent
                : scheme.surfaceContainerLowest;

    // chip de contexto: "🔗 Después de X" o "¡Siguiente!" según si hay título disponible
    final nudgeLabel = nudgeFromHabitTitle != null
        ? s.habitCardAfter(nudgeFromHabitTitle!.length > 18 ? '${nudgeFromHabitTitle!.substring(0, 16)}…' : nudgeFromHabitTitle!)
        : s.habitCardNext;

    final nextChip = isNextInStack && !isCompletedToday
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, size: 10, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  nudgeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          )
        : null;

    Widget card = GestureDetector(
      onLongPress: selectionMode ? null : onLongPressOverride,
      child: Container(
      color: isInsideGroup ? cardBg : null,
      clipBehavior: isInsideGroup ? Clip.none : Clip.antiAlias,
      decoration: isInsideGroup
          ? null
          : BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: isOnFire
                  ? Border.all(
                      color: AppTheme.tertiary.withValues(alpha: 0.55),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isOnFire
                  ? AppTheme.tintedShadow(AppTheme.tertiary, opacity: 0.28)
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
                  // Feedback sensorial según estado resultante
                  if (!isCompletedToday) {
                    FeedbackService.instance.habitCompleted();
                  } else {
                    FeedbackService.instance.habitUncompleted();
                  }
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
                          if (pendingSync)
                            ValueListenableBuilder<bool>(
                              valueListenable: ConnectivityService.instance.isOnline,
                              builder: (context, online, _) => online
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Tooltip(
                                        message: 'Se sincronizará al volver la conexión',
                                        child: Icon(
                                          Icons.cloud_off_rounded,
                                          size: 14,
                                          color: scheme.outline,
                                        ),
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
                              label: s.daysLabel(habit.currentStreak),
                              iconColor: scheme.tertiary,
                              textColor: scheme.tertiary,
                              bgColor: scheme.tertiary
                                  .withValues(alpha: isOnFire ? 0.22 : 0.15),
                              // en modo "En Llamas" la llama parpadea
                              leading: isOnFire
                                  ? const _AnimatedFlame(color: AppTheme.tertiary)
                                  : null,
                            ),
                          // chip de categoria
                          Hero(
                            tag: 'habit_cat_${habit.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: _MetaChip(
                                icon: catIcon,
                                label: CategoryL10n.labelOf(habit.category, context),
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
                          // chip de posición en cadena: ej. 🔗 1/3
                          if (habit.isInStack && stackTotal > 0)
                            _MetaChip(
                              icon: Icons.link_rounded,
                              label: '${stackPosition + 1}/$stackTotal',
                              iconColor: scheme.primary.withValues(alpha: 0.8),
                              textColor: scheme.primary,
                              bgColor: scheme.primaryContainer.withValues(alpha: 0.25),
                            ),
                          // chip de nudge: es el siguiente en la cadena
                          ?nextChip,
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(s.commonEdit),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                            const SizedBox(width: 12),
                            Text(s.habitDetailDelete, style: const TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
        ],      // cierra Column.children
      ),        // cierra Column
    ));

    // efecto shimmer en el hábito que es siguiente en la cadena
    if (isNextInStack && !isCompletedToday) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1400.ms,
            delay: 200.ms,
            color: scheme.primary.withValues(alpha: 0.12),
          );
    }

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

// ==================== LLAMA ANIMADA (Modo "En Llamas") ====================

/// Icono de fuego que parpadea para las rachas > 5 días.
/// Animación barata con flutter_animate: escala oscilante + tinte naranja
/// pulsante, en bucle reverso para dar sensación de llama viva.
class _AnimatedFlame extends StatelessWidget {
  final Color color;

  const _AnimatedFlame({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.local_fire_department_rounded, size: 11, color: color)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.88,
          end: 1.18,
          duration: 700.ms,
          curve: Curves.easeInOut,
        )
        .tint(
          color: Colors.deepOrange.withValues(alpha: 0.45),
          duration: 700.ms,
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
  // si se pasa, reemplaza el icono estático (p.ej. la llama animada del modo fuego)
  final Widget? leading;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.bgColor,
    this.leading,
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
          leading ?? Icon(icon, size: 11, color: iconColor),
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
