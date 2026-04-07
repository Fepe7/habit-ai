import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/habit_model.dart';

// Bottom sheet para editar un habito existente
class EditHabitSheet extends StatefulWidget {
  final HabitModel habit;

  const EditHabitSheet({super.key, required this.habit});

  // abrir el sheet y devolver el habito editado (o null si cancela)
  static Future<HabitModel?> show(BuildContext context, HabitModel habit) {
    return showModalBottomSheet<HabitModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // barra indicadora
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Editar hábito',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // titulo
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Correr 30 minutos',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // descripcion
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Opcional',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // categoria
            Text(
              'Categoría',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.categories.map((cat) {
                final selected = cat == _category;
                final bg = AppTheme.categoryBg(cat);
                final fg = AppTheme.categoryFg(cat);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppTheme.categoryIcon(cat),
                        size: 16,
                        color: selected ? fg : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(AppTheme.categoryLabel(cat)),
                    ],
                  ),
                  selected: selected,
                  selectedColor: bg,
                  labelStyle: TextStyle(
                    color: selected ? fg : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // dias de la semana
            Text(
              'Días de la semana',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
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
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[i],
                        style: TextStyle(
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // hora recordatorio
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule, color: colorScheme.primary),
              title: Text(
                _reminderTime != null
                    ? 'Recordatorio: $_reminderTime'
                    : 'Sin recordatorio',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reminderTime != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _reminderTime = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _pickTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // boton guardar
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar cambios'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
