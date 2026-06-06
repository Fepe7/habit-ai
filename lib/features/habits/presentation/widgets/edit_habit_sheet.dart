import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/habit_group_repository.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit_group_model.dart';
import '../../domain/habit_model.dart';
import '../../domain/habit_visibility.dart';
import 'habit_visibility_selector.dart';

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
  // grupo asignado: null = sin rutina
  String? _selectedGroupId;
  List<HabitGroupModel> _groups = [];
  late HabitVisibility _visibility;

  // cadena: hábitos en la misma cadena que este (para mostrar contexto)
  List<HabitModel> _stackSiblings = [];
  bool _stackLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.habit.title);
    _descCtrl = TextEditingController(text: widget.habit.description);
    _category = widget.habit.category;
    _frequency = widget.habit.frequency;
    _targetDays = List.from(widget.habit.targetDays);
    _reminderTime = widget.habit.reminderTime;
    _selectedGroupId = widget.habit.groupId;
    _visibility = widget.habit.visibility;
    _loadGroups();
    _loadStackSiblings();
  }

  Future<void> _loadGroups() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final groups =
          await HabitGroupRepository(uid: uid).watchGroups().first;
      if (mounted) setState(() => _groups = groups);
    } catch (_) {}
  }

  Future<void> _loadStackSiblings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.habit.stackId == null) {
      if (mounted) setState(() => _stackLoaded = true);
      return;
    }
    try {
      final siblings = await HabitRepository(uid: uid)
          .watchStackHabits(widget.habit.stackId!)
          .first;
      if (mounted) {
        setState(() {
          _stackSiblings = siblings;
          _stackLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _stackLoaded = true);
    }
  }

  Future<void> _removeFromStack() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await HabitRepository(uid: uid).removeFromStack(widget.habit.id);
      if (mounted) {
        setState(() {
          _stackSiblings = [];
          _stackLoaded = true;
        });
      }
    } catch (_) {}
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

    // construir explícitamente para permitir groupId null (copyWith no lo soporta)
    final updated = HabitModel(
      id: widget.habit.id,
      title: title,
      description: _descCtrl.text.trim(),
      category: _category,
      frequency: _frequency,
      targetDays: _targetDays,
      reminderTime: _reminderTime,
      currentStreak: widget.habit.currentStreak,
      bestStreak: widget.habit.bestStreak,
      isAIGenerated: widget.habit.isAIGenerated,
      createdAt: widget.habit.createdAt,
      isActive: widget.habit.isActive,
      groupId: _selectedGroupId,
      visibility: _visibility,
      // preservar campos de cadena
      stackId: widget.habit.stackId,
      stackOrder: widget.habit.stackOrder,
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
    final s = S.of(context);
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
                  s.editHabitTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

            // título
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: s.habitFieldTitle,
                hintText: s.editHabitTitleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // descripción
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: s.habitFieldDescription,
                hintText: s.habitFieldOptional,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 6,
            ),
            const SizedBox(height: 24),

            // sección categoría
            _SheetLabel(label: s.habitFieldCategory),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.categories.map((cat) {
                final selected = cat == _category;
                final bg = AppTheme.categoryBg(cat, scheme.brightness);
                final fg = AppTheme.categoryFg(cat, scheme.brightness);
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
            _SheetLabel(label: s.habitFieldWeekdays),
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
                        _weekdayInitials(s)[i],
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
            _SheetLabel(label: s.habitFieldReminder),
            const SizedBox(height: 12),
            _ReminderTile(
              reminderTime: _reminderTime,
              onPickTime: _pickTime,
              onClear: () => setState(() => _reminderTime = null),
            ),
            const SizedBox(height: 24),

            // sección rutina (grupo)
            if (_groups.isNotEmpty) ...[
              _SheetLabel(label: s.editHabitRoutineLabel),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // opción "sin rutina"
                  _GroupChip(
                    label: s.editHabitNoRoutine,
                    emoji: null,
                    selected: _selectedGroupId == null,
                    onTap: () => setState(() => _selectedGroupId = null),
                    scheme: scheme,
                  ),
                  ..._groups.map((g) => _GroupChip(
                        label: g.title,
                        emoji: g.emoji,
                        selected: _selectedGroupId == g.id,
                        onTap: () =>
                            setState(() => _selectedGroupId = g.id),
                        scheme: scheme,
                      )),
                ],
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 4),

            // sección cadena de hábitos
            if (_stackLoaded) ...[
              _SheetLabel(label: s.editHabitChainLabel),
              const SizedBox(height: 12),
              if (_stackSiblings.isNotEmpty) ...[
                // mostrar los hábitos de la cadena con indicador de posición
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            s.editHabitChainedCount(_stackSiblings.length),
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._stackSiblings.map((h) {
                        final isThis = h.id == widget.habit.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isThis
                                      ? scheme.primary
                                      : scheme.outlineVariant.withValues(
                                          alpha: 0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    '${h.stackOrder + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isThis
                                          ? Colors.white
                                          : scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  h.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isThis
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                        fontWeight: isThis
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              if (isThis)
                                Text(
                                  s.editHabitChainThis,
                                  style:
                                      Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: scheme.primary,
                                          ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      // botón para salir de la cadena
                      GestureDetector(
                        onTap: _removeFromStack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_off_rounded,
                                  size: 14, color: AppTheme.error),
                              const SizedBox(width: 6),
                              Text(
                                s.editHabitChainRemove,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Text(
                  s.editHabitNoChain,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 28),
            ],

          // sección visibilidad
          _SheetLabel(label: s.createHabitVisibilityLabel),
          const SizedBox(height: 12),
          HabitVisibilitySelector(
            value: _visibility,
            onChanged: (v) => setState(() => _visibility = v),
          ),
          const SizedBox(height: 24),

          // botón guardar debajo del recordatorio
          GradientButton(
            onPressed: _save,
            label: s.editHabitSaveCta,
            icon: Icons.save_rounded,
            gradient: AppTheme.heroGradient,
          ),
        ],
      ),
    );
  }
}

// iniciales de los días de la semana (lun→dom) localizadas
List<String> _weekdayInitials(S s) => [
      s.weekdayLShort,
      s.weekdayMShort,
      s.weekdayXShort,
      s.weekdayJShort,
      s.weekdayVShort,
      s.weekdaySShort,
      s.weekdayDShort,
    ];

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

class _GroupChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _GroupChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ] else ...[
              Icon(Icons.folder_off_outlined,
                  size: 14,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
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
          hasReminder ? reminderTime! : S.of(context).habitNoReminder,
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
