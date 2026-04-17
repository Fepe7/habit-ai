import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/habit_group_model.dart';

// Bottom sheet para crear una rutina (grupo de habitos) manualmente
class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  static Future<HabitGroupModel?> show(BuildContext context) {
    return showAppBottomSheet<HabitGroupModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => const CreateGroupSheet(),
    );
  }

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();

  static const _suggestedEmojis = [
    '🏋️', '🏃', '🧘', '📚', '✍️', '💻', '🎨', '🎵',
    '🥗', '💧', '😴', '🌱', '💡', '🎯', '⭐', '🔥',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final emoji = _emojiCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final group = HabitGroupModel(
      id: '',
      title: title,
      emoji: emoji.isEmpty ? null : emoji,
      description: desc.isEmpty ? null : desc,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // barra indicadora
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Nueva rutina',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),

            // nombre de la rutina
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la rutina',
                hintText: 'Ej: Rutina matutina',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // descripcion opcional
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Opcional — para qué sirve esta rutina',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // seccion emoji
            Text(
              'Emoji',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emojiCtrl,
              decoration: const InputDecoration(
                hintText: 'Pega un emoji o selecciona abajo',
              ),
              maxLength: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // chip "sin emoji" para borrarlo de un toque
                InkWell(
                  onTap: () => setState(() => _emojiCtrl.clear()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _emojiCtrl.text.isEmpty
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _emojiCtrl.text.isEmpty
                            ? scheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.do_not_disturb_alt_rounded,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ..._suggestedEmojis.map((e) {
                  final selected = _emojiCtrl.text == e;
                  return InkWell(
                    onTap: () => setState(() => _emojiCtrl.text = e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? scheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 28),

            GradientButton(
              onPressed: _save,
              label: 'Crear rutina',
              icon: Icons.folder_special_rounded,
              gradient: AppTheme.heroGradient,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
