import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/habit_model.dart';

// Bottom sheet para editar un hábito existente
class EditHabitSheet extends StatefulWidget {
  final HabitModel habit;

  const EditHabitSheet({super.key, required this.habit});

  // abrir el sheet y devolver el hábito editado (o null si cancela)
  static Future<HabitModel?> show(BuildContext context, HabitModel habit) {
    return showAppBottomSheet<HabitModel>(
      context: context,
      // limitar altura para que SingleChildScrollView pueda hacer scroll hasta el botón
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => EditHabitSheet(habit: habit),
    );
  }

  @override
  State<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends State<EditHabitSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late String _frequency;
  late List<int> _targetDays;
  late String? _reminderTime;

  static const _dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.habit.title);
    _descCtrl = TextEditingController(text: widget.habit.description);
    _category = widget.habit.category;
    _frequency = widget.habit.frequency;
    _targetDays = List.from(widget.habit.targetDays);
    _reminderTime = widget.habit.reminderTime;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final updated = widget.habit.copyWith(
      title: title,
      description: _descCtrl.text.trim(),
      category: _category,
      frequency: _frequency,
      targetDays: _targetDays,
      reminderTime: _reminderTime,
    );

    Navigator.of(context).pop(updated);
  }

  Future<void> _pickTime() async {
    // parsear hora actual o usar 8:00 por defecto
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    if (_reminderTime != null) {
      final parts = _reminderTime!.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
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
                  'Editar hábito',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

            // título
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Correr 30 minutos',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // descripción
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Opcional',
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 6,
            ),
            const SizedBox(height: 24),

            // sección categoría
            _SheetLabel(label: 'Categoría'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.categories.map((cat) {
                final selected = cat == _category;
                final bg = AppTheme.categoryBg(cat);
                final fg = AppTheme.categoryFg(cat);
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? bg
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.15),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppTheme.categoryIcon(cat),
                          size: 14,
                          color: selected ? fg : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppTheme.categoryLabel(cat),
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? fg : scheme.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // sección días
            _SheetLabel(label: 'Días de la semana'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _targetDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _targetDays.remove(day);
                      } else {
                        _targetDays.add(day);
                        _targetDays.sort();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[i],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // recordatorio
            _SheetLabel(label: 'Recordatorio'),
            const SizedBox(height: 12),
            _ReminderTile(
              reminderTime: _reminderTime,
              onPickTime: _pickTime,
              onClear: () => setState(() => _reminderTime = null),
            ),
          const SizedBox(height: 28),

          // botón guardar debajo del recordatorio
          GradientButton(
            onPressed: _save,
            label: 'Guardar cambios',
            icon: Icons.save_rounded,
            gradient: AppTheme.heroGradient,
          ),
        ],
      ),
    );
  }
}

// ==================== HELPERS ====================

class _SheetLabel extends StatelessWidget {
  final String label;
  const _SheetLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final String? reminderTime;
  final VoidCallback onPickTime;
  final VoidCallback onClear;

  const _ReminderTile({
    required this.reminderTime,
    required this.onPickTime,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasReminder = reminderTime != null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.schedule_rounded, size: 18, color: scheme.primary),
        ),
        title: Text(
          hasReminder ? reminderTime! : 'Sin recordatorio',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: hasReminder ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasReminder)
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
                onPressed: onClear,
              ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
              onPressed: onPickTime,
            ),
          ],
        ),
        onTap: onPickTime,
      ),
    );
  }
}
