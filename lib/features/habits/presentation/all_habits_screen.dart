import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../data/group_collapse_store.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import 'widgets/edit_habit_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../core/router/main_shell.dart';

/// Catálogo completo de hábitos: activos y archivados, agrupados igual que HabitsScreen.
/// No incluye lógica de check-in — es una vista de gestión, no de progreso diario.
class AllHabitsScreen extends StatefulWidget {
  const AllHabitsScreen({super.key});

  @override
  State<AllHabitsScreen> createState() => _AllHabitsScreenState();
}

class _AllHabitsScreenState extends State<AllHabitsScreen> {
  late HabitRepository _habitRepo;
  late HabitGroupRepository _groupRepo;

  late Stream<List<HabitModel>> _habitsStream;
  late Stream<List<HabitGroupModel>> _groupsStream;

  // pestaña activa
  bool _showActive = true;
  bool _showGroups = false;
  final Map<String, bool> _expandedGroups = {};
  String? _uid;
  bool _initialized = false;

  // modo selección múltiple
  bool _selectionMode = false;
  final Set<String> _selectedHabitIds = {};
  final Set<String> _selectedGroupIds = {};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      if (_showGroups) {
        _selectedGroupIds.add(id);
      } else {
        _selectedHabitIds.add(id);
      }
    });
  }

  void _toggleHabitSelection(String id) {
    setState(() {
      if (_selectedHabitIds.contains(id)) {
        _selectedHabitIds.remove(id);
      } else {
        _selectedHabitIds.add(id);
      }
    });
  }

  void _toggleGroupSelection(String id) {
    setState(() {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
      } else {
        _selectedGroupIds.add(id);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedHabitIds.clear();
      _selectedGroupIds.clear();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _uid = uid;
      _loadCollapsedGroups(uid);
      _habitRepo = HabitRepository(uid: uid);
      _groupRepo = HabitGroupRepository(uid: uid);
      _habitsStream = _habitRepo.watchAllHabits();
      _groupsStream = _groupRepo.watchGroups();
    }
    _initialized = true;
  }

  // Restaura el estado colapsado de grupos persistido entre sesiones.
  Future<void> _loadCollapsedGroups(String uid) async {
    final collapsed = await GroupCollapseStore.load(uid);
    if (collapsed.isEmpty || !mounted) return;
    setState(() {
      for (final id in collapsed) {
        _expandedGroups[id] = false;
      }
    });
  }

  // Guarda los grupos actualmente colapsados.
  void _persistCollapsedGroups() {
    final uid = _uid;
    if (uid == null) return;
    final collapsed = _expandedGroups.entries
        .where((e) => e.value == false)
        .map((e) => e.key)
        .toSet();
    GroupCollapseStore.save(uid, collapsed);
  }

  Future<void> _editHabit(HabitModel habit) async {
    final updated = await EditHabitSheet.show(context, habit);
    if (updated == null) return;
    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      if (updated.groupId != habit.groupId) {
        await _habitRepo.reassignGroup(habit.id, habit.groupId, updated.groupId);
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, S.of(context).habitsUpdated);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).habitsUpdateError);
      }
    }
  }

  Future<void> _hardDelete(HabitModel habit) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.allHabitsHardDeleteTitle),
        content: Text(s.allHabitsHardDeleteContent(habit.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(s.allHabitsHardDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _habitRepo.hardDeleteHabit(habit.id);
      if (mounted) {
        AppSnackBar.showSuccess(context, S.of(context).allHabitsHardDeleted(habit.title));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).allHabitsHardDeleteError);
      }
    }
  }

  Future<void> _bulkDeleteHabits() async {
    final s = S.of(context);
    final count = _selectedHabitIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.allHabitsBulkDeleteTitle(count)),
        content: Text(s.allHabitsBulkDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(s.allHabitsDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = List<String>.from(_selectedHabitIds);
    _exitSelection();
    try {
      for (final id in ids) {
        await _habitRepo.hardDeleteHabit(id);
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, S.of(context).allHabitsBulkDeleted(count));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).allHabitsBulkDeleteError);
      }
    }
  }

  Future<void> _bulkDeleteGroups() async {
    final s = S.of(context);
    final count = _selectedGroupIds.length;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.allHabitsBulkDeleteGroupsTitle(count)),
        content: Text(s.allHabitsBulkDeleteGroupsContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('group_only'),
            child: Text(s.allHabitsBulkDeleteGroupsOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('group_and_habits'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(s.allHabitsBulkDeleteGroupsAndHabits),
          ),
        ],
      ),
    );
    if (choice == null) return;
    final ids = List<String>.from(_selectedGroupIds);
    _exitSelection();
    try {
      for (final id in ids) {
        if (choice == 'group_and_habits') {
          await _groupRepo.deleteGroupAndHabits(id);
        } else {
          await _groupRepo.deleteGroup(id);
        }
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, S.of(context).allHabitsGroupsDeleted(count));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).allHabitsGroupsDeleteError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: Stack(
        children: [
          Positioned.fill(
           child: SafeArea(
            bottom: false,
            child: StreamBuilder<List<HabitGroupModel>>(
              stream: _groupsStream,
              builder: (context, groupsSnap) {
                return StreamBuilder<List<HabitModel>>(
                  stream: _habitsStream,
                  builder: (context, habitsSnap) {
                    if (habitsSnap.connectionState == ConnectionState.waiting) {
                      return const SectionSkeleton(itemCount: 4);
                    }

                    final allHabits = habitsSnap.data ?? [];
                    final filtered = allHabits
                        .where((h) => h.isActive == _showActive)
                        .toList();

                    final groups = groupsSnap.data ?? [];
                    final groupIds = groups.map((g) => g.id).toSet();
                    final groupsLoaded = groupsSnap.hasData;

                    final habitsByGroup = <String, List<HabitModel>>{};
                    final ungrouped = <HabitModel>[];
                    for (final h in filtered) {
                      final gid = h.groupId;
                      if (gid == null) {
                        ungrouped.add(h);
                      } else if (groupsLoaded && !groupIds.contains(gid)) {
                        ungrouped.add(h);
                      } else {
                        habitsByGroup.putIfAbsent(gid, () => []).add(h);
                      }
                    }

                    final activeGroups = groups
                        .where((g) => habitsByGroup.containsKey(g.id))
                        .toList();

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                            child: _buildHeader(context, allHabits.length)),
                        SliverToBoxAdapter(
                            child: _buildTabs(context, scheme)),

                        if (_showGroups) ...[
                          if (groups.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyGroupsState(),
                            )
                          else ...[
                            ...groups.map((group) => SliverToBoxAdapter(
                              key: ValueKey('routinecard_${group.id}'),
                              child: _RoutineCard(
                                group: group,
                                selectionMode: _selectionMode,
                                isSelected:
                                    _selectedGroupIds.contains(group.id),
                                onTap: _selectionMode
                                    ? () => _toggleGroupSelection(group.id)
                                    : () => context.push('/group/${group.id}'),
                                onLongPress: _selectionMode
                                    ? null
                                    : () => _enterSelection(group.id),
                              ),
                            )),
                            SliverToBoxAdapter(child: SizedBox(height: context.bottomNavInset)),
                          ],
                        ] else ...[
                          if (filtered.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(isActive: _showActive),
                            )
                          else ...[
                            ...activeGroups.map((group) {
                              final groupHabits =
                                  habitsByGroup[group.id] ?? [];
                              return SliverToBoxAdapter(
                                key: ValueKey('group_${group.id}'),
                                child: _AllHabitsGroupSection(
                                  group: group,
                                  habits: groupHabits,
                                  isExpanded:
                                      _expandedGroups[group.id] ?? true,
                                  onToggleExpanded: () {
                                    setState(() {
                                      _expandedGroups[group.id] =
                                          !(_expandedGroups[group.id] ?? true);
                                    });
                                    _persistCollapsedGroups();
                                  },
                                  onTapHabit: (h) =>
                                      context.push('/habit/${h.id}'),
                                  onEditHabit: _editHabit,
                                  onDeleteHabit: _hardDelete,
                                  selectionMode: _selectionMode,
                                  selectedIds: _selectedHabitIds,
                                  onToggleSelect: (id) =>
                                      _toggleHabitSelection(id),
                                  onEnterSelection: (id) =>
                                      _enterSelection(id),
                                ),
                              );
                            }),

                            if (ungrouped.isNotEmpty)
                              SliverToBoxAdapter(
                                key: const ValueKey('ungrouped'),
                                child: _UngroupedAllSection(
                                  habits: ungrouped,
                                  onTapHabit: (h) =>
                                      context.push('/habit/${h.id}'),
                                  onEditHabit: _editHabit,
                                  onDeleteHabit: _hardDelete,
                                  selectionMode: _selectionMode,
                                  selectedIds: _selectedHabitIds,
                                  onToggleSelect: (id) =>
                                      _toggleHabitSelection(id),
                                  onEnterSelection: (id) =>
                                      _enterSelection(id),
                                ),
                              ),

                            SliverToBoxAdapter(child: SizedBox(height: context.bottomNavInset)),
                          ],
                        ],

                      ],
                    );
                  },
                );
              },
            ),
          ),
          ), // Positioned.fill
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    if (_selectionMode) {
      final selCount = _showGroups
          ? _selectedGroupIds.length
          : _selectedHabitIds.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _exitSelection,
              tooltip: s.allHabitsCancelSelection,
            ),
            Expanded(
              child: Text(
                s.habitsSelected(selCount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: selCount > 0 ? AppTheme.error : scheme.onSurfaceVariant),
              tooltip: s.habitsDeleteSelected,
              onPressed: selCount > 0
                  ? (_showGroups ? _bulkDeleteGroups : _bulkDeleteHabits)
                  : null,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const DrawerMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.drawerAllHabits,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  s.allHabitsTotal(total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, ColorScheme scheme) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _TabChip(
            label: s.allHabitsTabActive,
            selected: !_showGroups && _showActive,
            onTap: () => setState(() {
              _showGroups = false;
              _showActive = true;
            }),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: s.allHabitsTabArchived,
            selected: !_showGroups && !_showActive,
            onTap: () => setState(() {
              _showGroups = false;
              _showActive = false;
            }),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: s.allHabitsTabRoutines,
            selected: _showGroups,
            onTap: () => setState(() => _showGroups = true),
          ),
        ],
      ),
    );
  }
}

// ==================== CHIP DE PESTAÑA ====================

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? AppTheme.ambientShadow(opacity: 0.12) : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ==================== ESTADO VACÍO ====================

class _EmptyState extends StatelessWidget {
  final bool isActive;
  const _EmptyState({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EmptyStateView(
      icon: isActive ? Icons.checklist_rounded : Icons.archive_outlined,
      title: isActive ? s.allHabitsEmptyActiveTitle : s.allHabitsEmptyArchivedTitle,
      subtitle: isActive ? s.allHabitsEmptyActiveSubtitle : null,
    );
  }
}

// ==================== SECCIÓN DE GRUPO (SIN BARRA DE PROGRESO DIARIO) ====================

class _AllHabitsGroupSection extends StatelessWidget {
  final HabitGroupModel group;
  final List<HabitModel> habits;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;

  const _AllHabitsGroupSection({
    required this.group,
    required this.habits,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // cabecera del grupo
            InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    if (group.emoji != null)
                      Text(group.emoji!, style: const TextStyle(fontSize: 24))
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 18),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            S.of(context).exploreHabitCount(habits.length),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded,
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            // lista de hábitos (colapso animado)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.12)),
                  ...habits.map((habit) => _AllHabitTile(
                        key: ValueKey(habit.id),
                        habit: habit,
                        onTap: () => onTapHabit(habit),
                        onEdit: () => onEditHabit(habit),
                        onDelete: () => onDeleteHabit(habit),
                        selectionMode: selectionMode,
                        isSelected: selectedIds.contains(habit.id),
                        onSelect: () => selectionMode
                            ? onToggleSelect(habit.id)
                            : onEnterSelection(habit.id),
                      )),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SECCIÓN SIN GRUPO ====================

class _UngroupedAllSection extends StatelessWidget {
  final List<HabitModel> habits;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;

  const _UngroupedAllSection({
    required this.habits,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 6),
            child: Row(
              children: [
                Text(
                  S.of(context).habitsTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${habits.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.ambientShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: habits
                  .map((habit) => _AllHabitTile(
                        key: ValueKey(habit.id),
                        habit: habit,
                        onTap: () => onTapHabit(habit),
                        onEdit: () => onEditHabit(habit),
                        onDelete: () => onDeleteHabit(habit),
                        selectionMode: selectionMode,
                        isSelected: selectedIds.contains(habit.id),
                        onSelect: () => selectionMode
                            ? onToggleSelect(habit.id)
                            : onEnterSelection(habit.id),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TILE DE HÁBITO (sin checkbox de hoy) ====================

class _AllHabitTile extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool isSelected;
  // onSelect: toggle en modo selección o entrar en modo selección
  final VoidCallback? onSelect;

  const _AllHabitTile({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final dayLetters = [
      s.weekdayLShort,
      s.weekdayMShort,
      s.weekdayXShort,
      s.weekdayJShort,
      s.weekdayVShort,
      s.weekdaySShort,
      s.weekdayDShort,
    ];
    final bgColor = AppTheme.categoryBg(habit.category, scheme.brightness);
    final fgColor = AppTheme.categoryFg(habit.category, scheme.brightness);

    return GestureDetector(
      onLongPress: selectionMode ? null : onSelect,
      child: ColoredBox(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.25)
            : Colors.transparent,
        child: InkWell(
          onTap: selectionMode ? onSelect : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // checkbox en modo selección, badge de categoría si no
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onSelect?.call(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(AppTheme.categoryIcon(habit.category), size: 18, color: fgColor),
                  ),
            const SizedBox(width: 12),

            // título + días
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // mini L-M-X-J-V-S-D
                  Row(
                    children: List.generate(7, (i) {
                      final dayNum = i + 1; // 1=Lunes…7=Domingo
                      final active = habit.targetDays.contains(dayNum);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: active
                                ? scheme.primary.withValues(alpha: 0.15)
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayLetters[i],
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      color: active
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // menú contextual solo si no está en modo selección
            if (!selectionMode)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
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
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever_outlined,
                            size: 20, color: AppTheme.error),
                        const SizedBox(width: 12),
                        Text(s.allHabitsHardDeleteConfirm,
                            style: const TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CARD DE RUTINA (PESTAÑA RUTINAS) ====================

class _RoutineCard extends StatelessWidget {
  final HabitGroupModel group;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const _RoutineCard({
    required this.group,
    required this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Card(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // checkbox o emoji/icono
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: group.emoji != null
                        ? Text(group.emoji!, style: const TextStyle(fontSize: 22))
                        : Icon(Icons.folder_special_rounded,
                            size: 22, color: scheme.primary),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.habitCount == 0
                            ? S.of(context).allHabitsNoHabitsYet
                            : S.of(context).exploreHabitCount(group.habitCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}


// ==================== ESTADO VACÍO (SIN RUTINAS) ====================

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EmptyStateView(
      icon: Icons.folder_special_outlined,
      title: s.allHabitsEmptyRoutinesTitle,
      subtitle: s.allHabitsEmptyRoutinesSubtitle,
    );
  }
}
