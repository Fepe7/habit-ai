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

// Bottom sheet para crear un hábito manualmente
class CreateHabitSheet extends StatefulWidget {
  // si se pasa groupId el hábito queda asociado a ese grupo
  final String? groupId;

  const CreateHabitSheet({super.key, this.groupId});

  static Future<HabitModel?> show(BuildContext context, {String? groupId}) {
    return showAppBottomSheet<HabitModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => CreateHabitSheet(groupId: groupId),
    );
  }

  @override
  State<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<CreateHabitSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'productividad';
  final List<int> _targetDays = [1, 2, 3, 4, 5, 6, 7];
  String? _reminderTime;

  // hábito seleccionado como ancla de cadena (opcional)
  HabitModel? _stackAnchor;
  List<HabitModel> _availableHabits = [];
  bool _habitsLoaded = false;

  // grupo seleccionado (opcional)
  HabitGroupModel? _selectedGroup;
  List<HabitGroupModel> _availableGroups = [];
  bool _groupsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableHabits();
    _loadAvailableGroups();
  }

  Future<void> _loadAvailableHabits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final habits = await HabitRepository(uid: uid).getActiveHabits();
      if (mounted) {
        setState(() {
          _availableHabits = habits;
          _habitsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _habitsLoaded = true);
    }
  }

  Future<void> _loadAvailableGroups() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _groupsLoaded = true);
      return;
    }
    try {
      final groups = await HabitGroupRepository(uid: uid).watchGroups().first;
      if (!mounted) return;
      setState(() {
        _availableGroups = groups;
        // pre-seleccionar si viene groupId desde el constructor
        if (widget.groupId != null) {
          _selectedGroup = groups.where((g) => g.id == widget.groupId).firstOrNull;
        }
        _groupsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _groupsLoaded = true);
    }
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

    final habit = HabitModel(
      id: '',
      title: title,
      description: _descCtrl.text.trim(),
      category: _category,
      frequency: 'daily',
      targetDays: _targetDays,
      reminderTime: _reminderTime,
      createdAt: DateTime.now(),
      groupId: _selectedGroup?.id,
      // stackAfterHabitId transitorio: el repo lo procesa al crear
      stackAfterHabitId: _stackAnchor?.id,
    );

    Navigator.of(context).pop(habit);
  }

  Future<void> _pickTime() async {
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
            // barra indicadora con hitbox grande para cerrar deslizando
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                // cierra si el gesto baja con suficiente velocidad
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
            const SizedBox(height: 10),

            Text(
              s.createHabitTitle,
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
                hintText: s.createHabitTitleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
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
              maxLines: 2,
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
                          color: selected
                              ? fg
                              : scheme.onSurfaceVariant,
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

            // sección grupos
            if (!_groupsLoaded) ...[
              _SheetLabel(label: s.createHabitGroupLabel),
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: 28),
            ] else if (_availableGroups.isNotEmpty) ...[
              _SheetLabel(label: s.createHabitGroupLabel),
              const SizedBox(height: 6),
              Text(
                s.createHabitGroupHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StackChip(
                    label: s.createHabitNoGroup,
                    icon: Icons.folder_off_rounded,
                    selected: _selectedGroup == null,
                    onTap: () => setState(() => _selectedGroup = null),
                    scheme: scheme,
                  ),
                  ..._availableGroups.map((g) => _StackChip(
                        label: '${g.emoji ?? '📁'} ${g.title}',
                        icon: Icons.folder_rounded,
                        selected: _selectedGroup?.id == g.id,
                        onTap: () => setState(() => _selectedGroup = g),
                        scheme: scheme,
                      )),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // sección encadenamiento
            if (!_habitsLoaded) ...[
              _SheetLabel(label: s.createHabitChainLabel),
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: 28),
            ] else if (_availableHabits.isNotEmpty) ...[
              _SheetLabel(label: s.createHabitChainLabel),
              const SizedBox(height: 6),
              Text(
                s.createHabitChainHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // chip "Ninguno" (quitar ancla)
                  _StackChip(
                    label: s.createHabitChainNone,
                    icon: Icons.link_off_rounded,
                    selected: _stackAnchor == null,
                    onTap: () => setState(() => _stackAnchor = null),
                    scheme: scheme,
                  ),
                  ..._availableHabits.map((h) => _StackChip(
                        label: h.title,
                        icon: Icons.link_rounded,
                        selected: _stackAnchor?.id == h.id,
                        onTap: () => setState(() => _stackAnchor = h),
                        scheme: scheme,
                      )),
                ],
              ),
              const SizedBox(height: 28),
            ] else
              const SizedBox(height: 4),

            // CTA
            GradientButton(
              onPressed: _save,
              label: s.createHabitCta,
              icon: Icons.add_rounded,
              gradient: AppTheme.heroGradient,
            ),
            const SizedBox(height: 8),
          ],
        ),
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

// ==================== HELPERS COMPARTIDOS ====================

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

class _StackChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _StackChip({
    required this.label,
    required this.icon,
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
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
