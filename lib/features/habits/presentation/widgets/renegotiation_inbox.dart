import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ai/domain/renegotiation_model.dart';
import '../../domain/habit_model.dart';

// Superficie consolidada de renegociaciones.
//
// Antes cada HabitCard pintaba su propio _CoachBanner: para usuarios poco
// activos eso empapelaba la pantalla (una propuesta por hábito atascado, cada
// vez que entraban). Ahora todas las propuestas pendientes se agrupan en una
// única tarjeta arriba de la lista; al tocarla se abre el inbox con cada
// propuesta y sus acciones (aplicar / descartar).

/// Tarjeta única que resume las renegociaciones pendientes. Se oculta sola si
/// no hay ninguna.
class RenegotiationInboxCard extends StatelessWidget {
  final List<RenegotiationModel> renegotiations;
  final VoidCallback onTap;

  const RenegotiationInboxCard({
    super.key,
    required this.renegotiations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (renegotiations.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.renoInboxTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.renoInboxCount(renegotiations.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet que lista cada renegociación pendiente con sus acciones.
class RenegotiationInboxSheet extends StatefulWidget {
  final List<RenegotiationModel> renegotiations;
  final Map<String, HabitModel> habitsById;
  // Aplicar necesita el HabitModel para prerellenar la edición; descartar solo
  // el id. Ambos los gestiona el State de HabitsScreen.
  final void Function(HabitModel habit) onApply;
  final void Function(String habitId) onDismiss;

  const RenegotiationInboxSheet({
    super.key,
    required this.renegotiations,
    required this.habitsById,
    required this.onApply,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required List<RenegotiationModel> renegotiations,
    required Map<String, HabitModel> habitsById,
    required void Function(HabitModel habit) onApply,
    required void Function(String habitId) onDismiss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RenegotiationInboxSheet(
        renegotiations: renegotiations,
        habitsById: habitsById,
        onApply: onApply,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<RenegotiationInboxSheet> createState() =>
      _RenegotiationInboxSheetState();
}

class _RenegotiationInboxSheetState extends State<RenegotiationInboxSheet> {
  late final List<RenegotiationModel> _items =
      List.of(widget.renegotiations);

  void _apply(RenegotiationModel reno) {
    final habit = widget.habitsById[reno.habitId];
    if (habit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).renoUnavailable)),
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onApply(habit);
  }

  void _dismiss(RenegotiationModel reno) {
    widget.onDismiss(reno.habitId);
    setState(() => _items.removeWhere((r) => r.habitId == reno.habitId));
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.renoInboxSheetTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final reno = _items[i];
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Text(
                            reno.habitTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        CoachBanner(
                          renegotiation: reno,
                          onApply: () => _apply(reno),
                          onDismiss: () => _dismiss(reno),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de propuesta: diagnóstico de la IA + acciones aplicar/descartar.
/// Reutilizado como item dentro del inbox. (Antes vivía en habit_card.dart
/// pegado bajo cada HabitCard.)
class CoachBanner extends StatelessWidget {
  final RenegotiationModel renegotiation;
  final VoidCallback? onApply;
  final VoidCallback? onDismiss;

  const CoachBanner({
    super.key,
    required this.renegotiation,
    this.onApply,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: scheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                s.habitCardCoachLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${renegotiation.diagnosis}"',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
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
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    s.habitCardCoachApply,
                    style: const TextStyle(
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
                    foregroundColor: scheme.onSurfaceVariant,
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    s.habitCardCoachDismiss,
                    style: const TextStyle(
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
