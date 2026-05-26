import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

// Opciones al pulsar el FAB "+"
enum CreateChoice { habit, group }

// Bottom sheet de elección: nuevo hábito o nueva rutina
class CreateChoiceSheet {
  static Future<CreateChoice?> show(BuildContext context) {
    return showAppBottomSheet<CreateChoice>(
      context: context,
      builder: (_) => const _CreateChoiceContent(),
    );
  }
}

class _CreateChoiceContent extends StatelessWidget {
  const _CreateChoiceContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // barra indicadora con hitbox grande para cerrar deslizando
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 200) {
                  Navigator.of(context).pop();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _ChoiceTile(
              icon: Icons.add_circle_outline_rounded,
              title: 'Nuevo hábito',
              subtitle: 'Un hábito individual',
              onTap: () => Navigator.of(context).pop(CreateChoice.habit),
            ),
            const SizedBox(height: 8),
            _ChoiceTile(
              icon: Icons.folder_special_rounded,
              title: 'Nueva rutina',
              subtitle: 'Grupo de hábitos relacionados',
              onTap: () => Navigator.of(context).pop(CreateChoice.group),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
