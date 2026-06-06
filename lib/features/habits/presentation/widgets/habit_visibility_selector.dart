import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/habit_visibility.dart';

/// Selector de visibilidad de hábito: 3 opciones (público / seguidores / privado).
class HabitVisibilitySelector extends StatelessWidget {
  final HabitVisibility value;
  final ValueChanged<HabitVisibility> onChanged;

  const HabitVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final options = [
      (v: HabitVisibility.public,    icon: Icons.public_rounded,       label: s.privacyOptionPublic),
      (v: HabitVisibility.followers, icon: Icons.people_rounded,        label: s.privacyOptionFollowers),
      (v: HabitVisibility.private,   icon: Icons.lock_outline_rounded,  label: s.privacyOptionPrivate),
    ];

    return Row(
      children: options.map((opt) {
        final selected = value == opt.v;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: selected ? null : () => onChanged(opt.v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 16,
                      color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opt.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: selected ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
