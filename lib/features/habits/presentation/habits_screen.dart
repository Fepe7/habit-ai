import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/router/main_shell.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import '../domain/habit_log_model.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_stack_connector.dart';
import 'widgets/stack_complete_overlay.dart';
import 'widgets/empty_habits_view.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import 'widgets/create_choice_sheet.dart';
import 'widgets/create_group_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../features/profile/data/public_profile_repository.dart';
import '../../../core/widgets/ux/gradient_fab.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/presentation/achievement_overlay.dart';
import '../../auth/data/user_repository.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/renegotiation_model.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../challenges/data/challenge_repository.dart';

/// Pantalla principal — grupos de habitos y hábitos sueltos
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late HabitRepository _habitRepo;
  late HabitGroupRepository _groupRepo;
  late AchievementChecker _achievementChecker;
  late AIRepository _aiRepo;
  late ChallengeRepository _challengeRepo;

  late Stream<List<HabitModel>> _habitsStream;
  late Stream<List<HabitGroupModel>> _groupsStream;

  final Map<String, bool> _completedToday = {};
  final Set<String> _logsFetched = {};
  final Map<String, bool> _expandedGroups = {};
  bool _initialized = false;
  String? _userName;
  List<HabitModel> _currentTodayHabits = [];
  Map<String, RenegotiationModel> _pendingRenegotiations = {};
  StreamSubscription? _renoSub;
  final List<StreamSubscription> _notifSubs = [];

  bool _hasNewNotifs = false;

  // IDs de hábitos que deben mostrar el nudge (siguiente en cadena)
  final Set<String> _nudgeHabitIds = {};
  // título del hábito completado que disparó el nudge, por ID del receptor
  final Map<String, String> _nudgeFromTitles = {};

  // modo selección múltiple
  bool _selectionMode = false;
  final Set<String> _selectedHabitIds = {};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedHabitIds.add(id);
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

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedHabitIds.clear();
    });
  }

  Future<void> _bulkDeleteHabits() async {
    final count = _selectedHabitIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar $count hábito${count == 1 ? '' : 's'}'),
        content: const Text(
          'Se desactivarán pero se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = List<String>.from(_selectedHabitIds);
    _exitSelection();
    try {
      for (final id in ids) {
        await _habitRepo.deactivateHabit(id);
        _completedToday.remove(id);
        _logsFetched.remove(id);
      }
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          '$count hábito${count == 1 ? '' : 's'} eliminado${count == 1 ? '' : 's'}',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al eliminar los hábitos');
      }
    }
  }

  Future<void> _checkNewNotifs(String uid) async {
    final hasNew = await NotificationsService.hasNew(uid);
    if (mounted) setState(() => _hasNewNotifs = hasNew);
  }

  void _watchNotifs(String uid) {
    final db = FirebaseFirestore.instance;

    void recheck(_) => _checkNewNotifs(uid);

    _notifSubs.addAll([
      // nuevo logro desbloqueado
      db.collection('users').doc(uid).collection('achievements')
          .snapshots().listen(recheck),
      // solicitud de seguimiento recibida
      db.collection('follow_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots().listen(recheck),
      // solicitud enviada que fue aceptada
      db.collection('follow_requests')
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots().listen(recheck),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        // Firebase Auth directamente — displayName puede ser null si no se configuró
        final fbUser = FirebaseAuth.instance.currentUser;
        _userName = fbUser?.displayName?.isNotEmpty == true
            ? fbUser!.displayName
            : fbUser?.email?.split('@').first;
        _habitRepo = HabitRepository(uid: user.uid);
        _groupRepo = HabitGroupRepository(uid: user.uid);
        _habitsStream = _habitRepo.watchTodayHabits();
        _groupsStream = _groupRepo.watchGroups();
        _achievementChecker = AchievementChecker(
          achievementRepo: AchievementRepository(uid: user.uid),
          habitRepo: _habitRepo,
          userRepo: UserRepository(uid: user.uid),
          publicProfileRepo: PublicProfileRepository(uid: user.uid),
        );
        _aiRepo = AIRepository(uid: user.uid);
        _challengeRepo = ChallengeRepository(uid: user.uid);
        _checkNewNotifs(user.uid);
        _watchNotifs(user.uid);
        _renoSub = _aiRepo.watchActiveRenegotiations().listen((list) {
          if (mounted) {
            setState(() {
              _pendingRenegotiations = {
                for (final r in list) r.habitId: r,
              };
            });
          }
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _renoSub?.cancel();
    for (final sub in _notifSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _habitsStream = _habitRepo.watchTodayHabits();
      _groupsStream = _groupRepo.watchGroups();
      _logsFetched.clear();
      _completedToday.clear();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _fetchLogsIfNeeded(List<HabitModel> habits) {
    for (final habit in habits) {
      if (_logsFetched.contains(habit.id)) continue;
      _logsFetched.add(habit.id);
      _habitRepo.getTodayLog(habit.id).then((log) {
        if (mounted) {
          setState(() => _completedToday[habit.id] = log?.completed ?? false);
        }
      });
    }
  }

  Future<void> _toggleHabit(HabitModel habit) async {
    final wasCompleted = _completedToday[habit.id] ?? false;
    setState(() => _completedToday[habit.id] = !wasCompleted);

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(id: '', date: DateTime.now(), completed: true);
        await _habitRepo.addLog(habit.id, log);
        await _habitRepo.updateStreak(habit.id);
      } else {
        await _habitRepo.uncheckAndRecalculate(habit.id);
      }
    } catch (e) {
      if (mounted) setState(() => _completedToday[habit.id] = wasCompleted);
      return;
    }

    if (!wasCompleted) {
      // feedback de XP extra por ser hábito atómico (encadenado)
      if (habit.isInStack && mounted) {
        _showStackXpToast(context);
      }

      // nudge al siguiente hábito de la cadena (si existe y no está completado)
      if (habit.stackId != null) {
        final stackHabits = _currentTodayHabits
            .where((h) => h.stackId == habit.stackId && h.isActive)
            .toList()
          ..sort((a, b) => a.stackOrder.compareTo(b.stackOrder));

        final idx = stackHabits.indexWhere((h) => h.id == habit.id);
        if (idx >= 0 && idx < stackHabits.length - 1) {
          final nextHabit = stackHabits[idx + 1];
          if (!(_completedToday[nextHabit.id] ?? false)) {
            setState(() {
              _nudgeHabitIds.add(nextHabit.id);
              // guardar el título del hábito que dispara el nudge
              _nudgeFromTitles[nextHabit.id] = habit.title;
            });
            // quitar el nudge tras 4 segundos
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                setState(() {
                  _nudgeHabitIds.remove(nextHabit.id);
                  _nudgeFromTitles.remove(nextHabit.id);
                });
              }
            });
          }
        } else if (idx == stackHabits.length - 1) {
          // era el último: comprobar si toda la cadena está completa
          final allDone = stackHabits.every((h) => _completedToday[h.id] == true);
          if (allDone && mounted) {
            StackCompleteOverlay.show(context, habitCount: stackHabits.length);
          }
        }
      }

      try {
        final updated = await _habitRepo.getHabit(habit.id);
        if (updated != null && mounted) {
          final unlocked = await _achievementChecker.checkAfterToggle(
            habit: updated,
            todayHabits: _currentTodayHabits,
            completedToday: _completedToday,
          );
          if (unlocked.isNotEmpty && mounted) {
            AchievementOverlay.showUnlocked(context, unlocked);
          }
        }
      } catch (_) {}
    }

    // sync progreso al reto compartido
    if (habit.challengeId != null) {
      try {
        await _challengeRepo.syncProgressFromToggle(
          challengeId: habit.challengeId!,
          completed: !wasCompleted,
        );
      } catch (_) {}
    }
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
      // reasignar grupo si cambió (actualiza groupId y contadores)
      if (updated.groupId != habit.groupId) {
        await _habitRepo.reassignGroup(habit.id, habit.groupId, updated.groupId);
      }
      // los cambios de cadena se gestionan directamente desde EditHabitSheet
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Hábito actualizado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al actualizar el hábito');
      }
    }
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Seguro que quieres eliminar "${habit.title}"?\n\n'
          'Se desactivará pero se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _habitRepo.deactivateHabit(habit.id);
      _completedToday.remove(habit.id);
      _logsFetched.remove(habit.id);
      if (habit.groupId != null) {
        try {
          await _groupRepo.incrementHabitCount(habit.groupId!, -1);
        } catch (_) {}
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, '"${habit.title}" eliminado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al eliminar el hábito');
      }
    }
  }

  Future<void> _applyRenegotiation(HabitModel habit) async {
    final reno = _pendingRenegotiations[habit.id];
    if (reno == null) return;
    await _aiRepo.markRenegotiationApplied(habit.id);
    if (!mounted) return;
    final prefilled = habit.copyWith(
      title: reno.suggestedTitle,
      description: reno.suggestedDescription ?? habit.description,
      reminderTime: reno.suggestedReminderTime ?? habit.reminderTime,
      targetDays: reno.suggestedTargetDays ?? habit.targetDays,
    );
    final updated = await EditHabitSheet.show(context, prefilled);
    if (updated == null || !mounted) return;
    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      if (mounted) AppSnackBar.showSuccess(context, 'Hábito ajustado ✓');
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, 'Error al actualizar el hábito');
    }
  }

  Future<void> _dismissRenegotiation(String habitId) async {
    await _aiRepo.dismissRenegotiation(habitId);
  }

  Future<void> _handleFabTap() async {
    final choice = await CreateChoiceSheet.show(context);
    if (choice == null) return;

    if (choice == CreateChoice.habit) {
      await _doCreateHabit();
    } else {
      await _doCreateGroup();
    }
  }

  Future<void> _doCreateHabit() async {
    final habit = await CreateHabitSheet.show(context);
    if (habit == null) return;

    // guardar si el usuario encadenó este hábito (para el onboarding)
    final encadenado = habit.stackAfterHabitId != null;

    try {
      await _habitRepo.createHabit(habit);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al crear el hábito');
      return;
    }
    if (mounted) AppSnackBar.showSuccess(context, 'Hábito creado');

    // onboarding: mostrar la primera vez que se usa el encadenamiento
    if (encadenado && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('stack_onboarding_shown') ?? false;
      if (!shown && mounted) {
        await prefs.setBool('stack_onboarding_shown', true);
        _showStackOnboarding();
      }
    }

    try {
      final unlocked = await _achievementChecker.checkAfterCreate();
      if (unlocked.isNotEmpty && mounted) {
        AchievementOverlay.showUnlocked(context, unlocked);
      }
    } catch (_) {}
  }

  void _showStackOnboarding() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _StackOnboardingSheet(),
    );
  }

  // Toast flotante ligero que muestra el bonus de XP por hábito atómico
  void _showStackXpToast(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _XpToast(onDone: () {
        if (entry.mounted) entry.remove();
      }),
    );
    overlay.insert(entry);
  }

  Future<void> _doCreateGroup() async {
    final group = await CreateGroupSheet.show(context);
    if (group == null || !mounted) return;
    try {
      final groupId = await _groupRepo.createGroup(group);
      if (mounted) {
        context.go('/group/$groupId');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al crear la rutina');
    }
  }

  Future<void> _deleteGroup(HabitGroupModel group) async {
    // 'group_only' | 'group_and_habits' | null (cancelar)
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${group.title}"'),
        content: const Text(
          '¿Qué quieres hacer con los hábitos de esta rutina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('group_only'),
            child: const Text('Solo la rutina'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('group_and_habits'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Rutina y hábitos'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    try {
      if (choice == 'group_and_habits') {
        await _groupRepo.deleteGroupAndHabits(group.id);
      } else {
        await _groupRepo.deleteGroup(group.id);
      }
      if (mounted) AppSnackBar.showSuccess(context, 'Rutina "${group.title}" eliminada');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al eliminar la rutina');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      floatingActionButton: _selectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: GradientFab(
                tooltip: 'Crear',
                onTap: _handleFabTap,
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<HabitGroupModel>>(
          stream: _groupsStream,
          builder: (context, groupsSnapshot) {
            return StreamBuilder<List<HabitModel>>(
              stream: _habitsStream,
              builder: (context, habitsSnapshot) {
                if (habitsSnapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    children: [
                      _buildHeader(context),
                      SectionSkeleton(itemCount: 4),
                    ],
                  );
                }
                if (habitsSnapshot.hasError) {
                  return _buildError(context, habitsSnapshot.error);
                }

                final allHabits = habitsSnapshot.data ?? [];
                _currentTodayHabits = allHabits;

                // grupos antes del early-return para poder mostrarlos aunque no haya hábitos hoy
                final groups = groupsSnapshot.data ?? [];
                final groupsLoaded = groupsSnapshot.hasData;

                // estado vacío solo si no hay hábitos NI grupos activos
                if (allHabits.isEmpty && groups.isEmpty) {
                  return Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: EmptyHabitsView(
                          onCreatePlan: () => context.go('/ai'),
                        ),
                      ),
                    ],
                  );
                }

                _fetchLogsIfNeeded(allHabits);

                final groupIds = groups.map((g) => g.id).toSet();
                final completedCount =
                    allHabits.where((h) => _completedToday[h.id] == true).length;

                final habitsByGroup = <String, List<HabitModel>>{};
                final ungroupedHabits = <HabitModel>[];

                for (final habit in allHabits) {
                  final gid = habit.groupId;
                  if (gid == null) {
                    ungroupedHabits.add(habit);
                  } else if (groupsLoaded && !groupIds.contains(gid)) {
                    ungroupedHabits.add(habit);
                  } else {
                    habitsByGroup.putIfAbsent(gid, () => []).add(habit);
                  }
                }

                // todos los grupos activos, incluyendo los vacíos
                final activeGroups = groups.toList();

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // header editorial asimetrico
                      SliverToBoxAdapter(child: _buildHeader(context)),

                      // hero de progreso diario
                      SliverToBoxAdapter(
                        child: _DailyProgressHero(
                          completed: completedCount,
                          total: allHabits.length,
                        ),
                      ),

                      // grupos como acordeones
                      ...activeGroups.map((group) {
                        final groupHabits = habitsByGroup[group.id] ?? [];
                        final groupCompleted = groupHabits
                            .where((h) => _completedToday[h.id] == true)
                            .length;
                        return SliverToBoxAdapter(
                          key: ValueKey('group_${group.id}'),
                          child: _GroupSection(
                            group: group,
                            habits: groupHabits,
                            completedCount: groupCompleted,
                            isExpanded: _expandedGroups[group.id] ?? true,
                            onToggleExpanded: () => setState(() {
                              _expandedGroups[group.id] =
                                  !(_expandedGroups[group.id] ?? true);
                            }),
                            onEditGroup: () => context.go('/group/${group.id}'),
                            onDeleteGroup: () => _deleteGroup(group),
                            completedToday: _completedToday,
                            onToggleHabit: _toggleHabit,
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _deleteHabit,
                            selectionMode: _selectionMode,
                            selectedIds: _selectedHabitIds,
                            onToggleSelect: _toggleHabitSelection,
                            onEnterSelection: _enterSelection,
                            pendingRenegotiations: _pendingRenegotiations,
                            onApplyRenegotiation: _applyRenegotiation,
                            onDismissRenegotiation: _dismissRenegotiation,
                            nudgeHabitIds: _nudgeHabitIds,
                            nudgeFromTitles: _nudgeFromTitles,
                          ),
                        );
                      }),

                      // habitos sin grupo
                      if (ungroupedHabits.isNotEmpty)
                        SliverToBoxAdapter(
                          key: const ValueKey('ungrouped'),
                          child: _UngroupedSection(
                            habits: ungroupedHabits,
                            completedToday: _completedToday,
                            onToggleHabit: _toggleHabit,
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _deleteHabit,
                            selectionMode: _selectionMode,
                            selectedIds: _selectedHabitIds,
                            onToggleSelect: _toggleHabitSelection,
                            onEnterSelection: _enterSelection,
                            pendingRenegotiations: _pendingRenegotiations,
                            onApplyRenegotiation: _applyRenegotiation,
                            onDismissRenegotiation: _dismissRenegotiation,
                            nudgeHabitIds: _nudgeHabitIds,
                            nudgeFromTitles: _nudgeFromTitles,
                          ),
                        ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: context.bottomNavInset),
                    ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // header asimetrico: saludo izquierda, fecha derecha (o barra de selección)
  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_selectionMode) {
      final count = _selectedHabitIds.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _exitSelection,
              tooltip: 'Cancelar selección',
            ),
            Expanded(
              child: Text(
                '$count seleccionado${count == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: count > 0 ? AppTheme.error : scheme.onSurfaceVariant,
              ),
              tooltip: 'Eliminar seleccionados',
              onPressed: count > 0 ? _bulkDeleteHabits : null,
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final dayName = days[now.weekday - 1];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const DrawerMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName != null ? 'Hola, $_userName' : 'HabitAI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _userName != null ? scheme.onSurface : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName, $dateStr',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // boton de notificaciones con badge de nuevas
          GestureDetector(
            onTap: () {
              setState(() => _hasNewNotifs = false);
              NotificationsBottomSheet.show(context);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.ambientShadow(),
                  ),
                  child: Icon(
                    _hasNewNotifs
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                if (_hasNewNotifs)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.surfaceContainerLowest,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object? error) {
    return ErrorStateView(
      message: 'No se pudieron cargar tus hábitos. Comprueba tu conexión.',
      onRetry: _refresh,
    );
  }
}

// ==================== HELPER DE CADENAS DE HÁBITOS ====================

/// Convierte una lista plana de hábitos en widgets, agrupando los encadenados
/// (mismo stackId) con conectores visuales entre ellos. Los hábitos sin cadena
/// se renderizan como cards normales. Las cadenas se renderizan primero, luego
/// los hábitos individuales.
List<Widget> _buildStackedHabitWidgets({
  required List<HabitModel> habits,
  required Map<String, bool> completedToday,
  required Set<String> nudgeHabitIds,
  Map<String, String> nudgeFromTitles = const {},
  required void Function(HabitModel) onToggleHabit,
  required void Function(HabitModel) onTapHabit,
  required void Function(HabitModel) onEditHabit,
  required void Function(HabitModel) onDeleteHabit,
  required bool selectionMode,
  required Set<String> selectedIds,
  required void Function(String) onToggleSelect,
  required void Function(String) onEnterSelection,
  required Map<String, RenegotiationModel> pendingRenegotiations,
  required void Function(HabitModel) onApplyRenegotiation,
  required void Function(String) onDismissRenegotiation,
}) {
  // separar encadenados de individuales
  final Map<String, List<HabitModel>> byStack = {};
  final List<HabitModel> individuals = [];

  for (final h in habits) {
    if (h.stackId != null) {
      byStack.putIfAbsent(h.stackId!, () => []).add(h);
    } else {
      individuals.add(h);
    }
  }

  // ordenar cada cadena por stackOrder
  for (final list in byStack.values) {
    list.sort((a, b) => a.stackOrder.compareTo(b.stackOrder));
  }

  Widget buildCard(
    HabitModel habit, {
    int stackPosition = 0,
    int stackTotal = 0,
  }) =>
      HabitCard(
        key: ValueKey(habit.id),
        habit: habit,
        isCompletedToday: completedToday[habit.id] ?? false,
        onToggle: () => onToggleHabit(habit),
        onTap: () => onTapHabit(habit),
        onEdit: () => onEditHabit(habit),
        onDelete: () => onDeleteHabit(habit),
        isInsideGroup: true,
        selectionMode: selectionMode,
        isSelected: selectedIds.contains(habit.id),
        onEnterSelection: () => onEnterSelection(habit.id),
        onToggleSelect: () => onToggleSelect(habit.id),
        renegotiation: pendingRenegotiations[habit.id],
        onApplyRenegotiation: () => onApplyRenegotiation(habit),
        onDismissRenegotiation: () => onDismissRenegotiation(habit.id),
        isNextInStack: nudgeHabitIds.contains(habit.id),
        stackPosition: stackPosition,
        stackTotal: stackTotal,
        nudgeFromHabitTitle: nudgeFromTitles[habit.id],
      );

  final widgets = <Widget>[];

  // cadenas primero: header + cards con conectores
  for (final stackHabits in byStack.values) {
    final total = stackHabits.length;
    final completed =
        stackHabits.where((h) => completedToday[h.id] == true).length;

    // header de cadena con progreso
    widgets.add(_StackHeader(total: total, completed: completed));

    for (int i = 0; i < total; i++) {
      widgets.add(buildCard(stackHabits[i], stackPosition: i, stackTotal: total));
      if (i < total - 1) {
        widgets.add(const HabitStackConnector());
      }
    }

    // separador sutil tras cada cadena (si después vienen más hábitos)
    widgets.add(const _StackDivider());
  }

  // hábitos individuales (sin cadena)
  for (final h in individuals) {
    widgets.add(buildCard(h));
  }

  return widgets;
}

// ==================== STACK HEADER ====================

/// Cabecera de una cadena de hábitos: etiqueta + barra de progreso.
class _StackHeader extends StatelessWidget {
  final int total;
  final int completed;

  const _StackHeader({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allDone = completed == total;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // icono de cadena
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: allDone
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : scheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allDone ? Icons.check_rounded : Icons.link_rounded,
              size: 14,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          // etiqueta
          Text(
            'CADENA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '·  $total hábitos',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // contador completados
          Text(
            '$completed/$total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: allDone ? AppTheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          // barra de progreso compacta
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 56,
              height: 5,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    allDone ? AppTheme.primary : scheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador sutil entre cadenas o entre cadena e hábitos individuales.
class _StackDivider extends StatelessWidget {
  const _StackDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: scheme.outlineVariant.withValues(alpha: 0.15),
    );
  }
}

// ==================== HERO DE PROGRESO ====================

class _DailyProgressHero extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyProgressHero({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;
    final pct = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: allDone
              ? AppTheme.streakGradient
              : AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.ambientShadow(opacity: 0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? '¡Todo listo!' : 'Progreso de hoy',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '${(v * 100).toInt()}%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed de $total hábitos completados',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // circulo de progreso
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: allDone && pct == 100
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 28)
                            : Text(
                                '$pct%',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SECCIÓN DE GRUPO ====================

class _GroupSection extends StatelessWidget {
  final HabitGroupModel group;
  final List<HabitModel> habits;
  final int completedCount;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEditGroup;
  final VoidCallback onDeleteGroup;
  final Map<String, bool> completedToday;
  final void Function(HabitModel) onToggleHabit;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;
  final Map<String, RenegotiationModel> pendingRenegotiations;
  final void Function(HabitModel) onApplyRenegotiation;
  final void Function(String) onDismissRenegotiation;
  final Set<String> nudgeHabitIds;
  final Map<String, String> nudgeFromTitles;

  const _GroupSection({
    required this.group,
    required this.habits,
    required this.completedCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEditGroup,
    required this.onDeleteGroup,
    required this.completedToday,
    required this.onToggleHabit,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
    this.pendingRenegotiations = const {},
    required this.onApplyRenegotiation,
    required this.onDismissRenegotiation,
    this.nudgeHabitIds = const {},
    this.nudgeFromTitles = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allDone = completedCount == habits.length && habits.isNotEmpty;
    final progress = habits.isNotEmpty ? completedCount / habits.length : 0.0;

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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      allDone ? AppTheme.tertiaryContainer : scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                habits.isEmpty ? '–' : '$completedCount/${habits.length}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: allDone
                                      ? AppTheme.tertiaryContainer
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (v) {
                        if (v == 'edit') onEditGroup();
                        if (v == 'delete') onDeleteGroup();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Editar grupo'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                              const SizedBox(width: 12),
                              Text('Eliminar grupo', style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            // lista de habitos (colapso animado)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.12)),
                  if (habits.isEmpty)
                    // grupo vacío: invitar a añadir hábitos
                    InkWell(
                      onTap: onEditGroup,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                size: 16, color: scheme.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              'Toca para añadir hábitos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildStackedHabitWidgets(
                      habits: habits,
                      completedToday: completedToday,
                      nudgeHabitIds: nudgeHabitIds,
                      nudgeFromTitles: nudgeFromTitles,
                      onToggleHabit: onToggleHabit,
                      onTapHabit: onTapHabit,
                      onEditHabit: onEditHabit,
                      onDeleteHabit: onDeleteHabit,
                      selectionMode: selectionMode,
                      selectedIds: selectedIds,
                      onToggleSelect: onToggleSelect,
                      onEnterSelection: onEnterSelection,
                      pendingRenegotiations: pendingRenegotiations,
                      onApplyRenegotiation: onApplyRenegotiation,
                      onDismissRenegotiation: onDismissRenegotiation,
                    ),
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

class _UngroupedSection extends StatelessWidget {
  final List<HabitModel> habits;
  final Map<String, bool> completedToday;
  final void Function(HabitModel) onToggleHabit;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;
  final Map<String, RenegotiationModel> pendingRenegotiations;
  final void Function(HabitModel) onApplyRenegotiation;
  final void Function(String) onDismissRenegotiation;
  final Set<String> nudgeHabitIds;
  final Map<String, String> nudgeFromTitles;

  const _UngroupedSection({
    required this.habits,
    required this.completedToday,
    required this.onToggleHabit,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
    this.pendingRenegotiations = const {},
    required this.onApplyRenegotiation,
    required this.onDismissRenegotiation,
    this.nudgeHabitIds = const {},
    this.nudgeFromTitles = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header seccion "Mis habitos"
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

          // cards de habitos sueltos en contenedor (con soporte de cadenas)
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.ambientShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _buildStackedHabitWidgets(
                habits: habits,
                completedToday: completedToday,
                nudgeHabitIds: nudgeHabitIds,
                nudgeFromTitles: nudgeFromTitles,
                onToggleHabit: onToggleHabit,
                onTapHabit: onTapHabit,
                onEditHabit: onEditHabit,
                onDeleteHabit: onDeleteHabit,
                selectionMode: selectionMode,
                selectedIds: selectedIds,
                onToggleSelect: onToggleSelect,
                onEnterSelection: onEnterSelection,
                pendingRenegotiations: pendingRenegotiations,
                onApplyRenegotiation: onApplyRenegotiation,
                onDismissRenegotiation: onDismissRenegotiation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ONBOARDING CADENAS ====================

/// Bottom sheet explicativo que aparece la primera vez que el usuario crea una cadena.
class _StackOnboardingSheet extends StatelessWidget {
  const _StackOnboardingSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Primera cadena creada!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Así funciona el hábito atómico',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _OnboardingStep(
            number: '1',
            title: 'Completa el hábito ancla',
            subtitle: 'El primer hábito de la cadena se resalta cuando lo terminas.',
            scheme: scheme,
          ),
          const SizedBox(height: 16),
          _OnboardingStep(
            number: '2',
            title: 'El siguiente se ilumina',
            subtitle: 'Verás "Después de X" en el hábito encadenado. Es tu señal.',
            scheme: scheme,
          ),
          const SizedBox(height: 16),
          _OnboardingStep(
            number: '3',
            title: 'Completa toda la cadena',
            subtitle: 'Cuando terminas todos recibes una celebración especial 🔥',
            scheme: scheme,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('¡Entendido!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final ColorScheme scheme;

  const _OnboardingStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== XP TOAST ====================

/// Toast ligero "+5 XP 🔗" que aparece al completar un hábito encadenado.
class _XpToast extends StatefulWidget {
  final VoidCallback onDone;
  const _XpToast({required this.onDone});

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_ctrl);

    _slide = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.4))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom + 120;

    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, child) => FractionalTranslation(
            translation: _slide.value,
            child: Opacity(opacity: _opacity.value, child: child),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '+5 XP · Hábito atómico',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('⚡', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
