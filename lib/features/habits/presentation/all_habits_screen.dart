import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import 'widgets/edit_habit_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';

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

  // pestaña activa: true = activos, false = archivados
  bool _showActive = true;
  final Map<String, bool> _expandedGroups = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _habitRepo = HabitRepository(uid: uid);
      _groupRepo = HabitGroupRepository(uid: uid);
      _habitsStream = _habitRepo.watchAllHabits();
      _groupsStream = _groupRepo.watchGroups();
    }
    _initialized = true;
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Hábito actualizado')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al actualizar el hábito'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _hardDelete(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar definitivamente'),
        content: Text(
          '¿Seguro que quieres borrar "${habit.title}" para siempre?\n\n'
          'Esto borra el hábito y todos sus registros. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Borrar definitivo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _habitRepo.hardDeleteHabit(habit.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${habit.title}" borrado permanentemente')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al borrar el hábito'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<HabitGroupModel>>(
          stream: _groupsStream,
          builder: (context, groupsSnap) {
            return StreamBuilder<List<HabitModel>>(
              stream: _habitsStream,
              builder: (context, habitsSnap) {
                if (habitsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allHabits = habitsSnap.data ?? [];
                // filtrar por pestaña activa
                final filtered = allHabits
                    .where((h) => h.isActive == _showActive)
                    .toList();

                final groups = groupsSnap.data ?? [];
                final groupIds = groups.map((g) => g.id).toSet();
                final groupsLoaded = groupsSnap.hasData;

                // particionar en grupos y sueltos
                final habitsByGroup = <String, List<HabitModel>>{};
                final ungrouped = <HabitModel>[];
                for (final h in filtered) {
                  final gid = h.groupId;
                  if (gid == null) {
                    ungrouped.add(h);
                  } else if (groupsLoaded && !groupIds.contains(gid)) {
                    // grupo huérfano — mostrar en sueltos
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
                    SliverToBoxAdapter(child: _buildHeader(context, allHabits.length)),
                    SliverToBoxAdapter(child: _buildTabs(context, scheme)),

                    // estado vacío
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(isActive: _showActive),
                      )
                    else ...[
                      // grupos como acordeones
                      ...activeGroups.map((group) {
                        final groupHabits = habitsByGroup[group.id] ?? [];
                        return SliverToBoxAdapter(
                          key: ValueKey('group_${group.id}'),
                          child: _AllHabitsGroupSection(
                            group: group,
                            habits: groupHabits,
                            isExpanded: _expandedGroups[group.id] ?? true,
                            onToggleExpanded: () => setState(() {
                              _expandedGroups[group.id] =
                                  !(_expandedGroups[group.id] ?? true);
                            }),
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _hardDelete,
                          ),
                        );
                      }),

                      // hábitos sueltos
                      if (ungrouped.isNotEmpty)
                        SliverToBoxAdapter(
                          key: const ValueKey('ungrouped'),
                          child: _UngroupedAllSection(
                            habits: ungrouped,
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _hardDelete,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    final scheme = Theme.of(context).colorScheme;
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
                  'Todos mis hábitos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '$total en total',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _TabChip(
            label: 'Activos',
            selected: _showActive,
            onTap: () => setState(() => _showActive = true),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Archivados',
            selected: !_showActive,
            onTap: () => setState(() => _showActive = false),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.checklist_rounded : Icons.archive_outlined,
              size: 64,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'No tienes hábitos creados'
                  : 'No tienes hábitos archivados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Text(
                'Crea hábitos desde la pantalla principal o con la IA.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
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

  const _AllHabitsGroupSection({
    required this.group,
    required this.habits,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
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
                            '${habits.length} hábito${habits.length == 1 ? '' : 's'}',
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

  const _UngroupedAllSection({
    required this.habits,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
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
                  'Mis hábitos',
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

  const _AllHabitTile({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = AppTheme.categoryBg(habit.category);
    final fgColor = AppTheme.categoryFg(habit.category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // badge de categoría
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
                            _dayLetters[i],
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

            // menú contextual
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_outlined,
                          size: 20, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Text('Borrar definitivo',
                          style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
