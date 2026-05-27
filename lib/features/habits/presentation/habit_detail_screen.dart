import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/renegotiation_model.dart';
import 'widgets/edit_habit_sheet.dart';
import '../../challenges/data/challenge_repository.dart';

// Pantalla de detalle de un hábito con diseño Editorial Vitality
class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late final HabitRepository _habitRepo;
  late final UserRepository _userRepo;
  late final AIRepository _aiRepo;
  late final ChallengeRepository _challengeRepo;
  HabitModel? _habit;
  UserModel? _userData;
  List<HabitLogModel> _recentLogs = [];
  bool _completedToday = false;
  bool _shieldedToday = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _habitRepo = HabitRepository(uid: uid);
    _userRepo = UserRepository(uid: uid);
    _aiRepo = AIRepository(uid: uid);
    _challengeRepo = ChallengeRepository(uid: uid);
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _habitRepo.getHabit(widget.habitId),
      _habitRepo.getTodayLog(widget.habitId),
      _userRepo.getUser(),
      _habitRepo.getLogsByDateRange(
        habitId: widget.habitId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      ),
    ]);

    if (!mounted) return;

    final habit = results[0] as HabitModel?;
    if (habit == null) return;

    final todayLog = results[1] as HabitLogModel?;
    final user = results[2] as UserModel;
    final logs = results[3] as List<HabitLogModel>;

    setState(() {
      _habit = habit;
      _userData = user;
      _completedToday = todayLog?.completed ?? false;
      _shieldedToday = todayLog?.shielded ?? false;
      _recentLogs = logs;
      _loading = false;
    });
  }

  Future<void> _toggleToday() async {
    if (_habit == null) return;
    final wasCompleted = _completedToday;
    HapticFeedback.mediumImpact();

    setState(() => _completedToday = !wasCompleted);

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(
          id: '',
          date: DateTime.now(),
          completed: true,
        );
        await _habitRepo.addLog(widget.habitId, log);
        await _habitRepo.updateStreak(widget.habitId);
        AnalyticsService.instance.logHabitCheckin(widget.habitId);
      } else {
        await _habitRepo.uncheckAndRecalculate(widget.habitId);
      }
      await _loadData();

      // sync progreso al reto compartido
      if (_habit?.challengeId != null) {
        try {
          await _challengeRepo.syncProgressFromToggle(
            challengeId: _habit!.challengeId!,
            completed: !wasCompleted,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) setState(() => _completedToday = wasCompleted);
    }
  }

  // Usar un escudo para proteger la racha de hoy
  Future<void> _useShield() async {
    if (_habit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usar escudo de racha'),
        content: Text(
          'Gastarás 1 escudo para proteger la racha de "${_habit!.title}" hoy.\n\n'
          'Te quedan ${_userData?.shieldsCount ?? 0} escudos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usar escudo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await _habitRepo.useShield(widget.habitId, DateTime.now());
    if (!mounted) return;

    if (ok) {
      HapticFeedback.lightImpact();
      AppSnackBar.showSuccess(context, '🛡️ Escudo usado — racha protegida');
      await _loadData();
    } else {
      AppSnackBar.showInfo(context, 'No tienes escudos disponibles');
    }
  }

  // Retirar el escudo de hoy (recuperar el escudo)
  Future<void> _removeShield() async {
    await _habitRepo.removeShield(widget.habitId, DateTime.now());
    if (mounted) await _loadData();
  }

  Future<void> _editHabit() async {
    if (_habit == null) return;
    final updated = await EditHabitSheet.show(context, _habit!);
    if (updated == null) return;

    await _habitRepo.updateHabit(_habit!.id, {
      'title': updated.title,
      'description': updated.description,
      'category': updated.category,
      'frequency': updated.frequency,
      'targetDays': updated.targetDays,
      'reminderTime': updated.reminderTime,
    });
    if (updated.groupId != _habit!.groupId) {
      await _habitRepo.reassignGroup(_habit!.id, _habit!.groupId, updated.groupId);
    }
    await _loadData();
  }

  Future<void> _deleteHabit() async {
    if (_habit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Seguro que quieres eliminar "${_habit!.title}"?\n\n'
          'Se desactivará y no aparecerá en tu lista, '
          'pero se conservará el historial.',
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

    if (confirmed != true || !mounted) return;

    await _habitRepo.deactivateHabit(_habit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  // Aplica los campos no nulos de la sugerencia sobre el hábito base
  HabitModel _applyRenegotiationOverrides(
      HabitModel base, RenegotiationModel reno) {
    return base.copyWith(
      title: reno.suggestedTitle,
      description: reno.suggestedDescription,
      reminderTime: reno.suggestedReminderTime,
      targetDays: reno.suggestedTargetDays,
    );
  }

  Widget _buildRenegotiationBanner() {
    return StreamBuilder<RenegotiationModel?>(
      stream: _aiRepo.watchRenegotiationForHabit(widget.habitId),
      builder: (context, snapshot) {
        final reno = snapshot.data;
        if (reno == null) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: AppTheme.ambientShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.handshake_outlined,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sugerencia de la IA',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            reno.strategy.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reno.diagnosis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  reno.encouragement,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (_habit == null) return;
                          final prefilled =
                              _applyRenegotiationOverrides(_habit!, reno);
                          final updated =
                              await EditHabitSheet.show(context, prefilled);
                          if (updated == null || !mounted) return;
                          await _habitRepo.updateHabit(_habit!.id, {
                            'title': updated.title,
                            'description': updated.description,
                            'category': updated.category,
                            'frequency': updated.frequency,
                            'targetDays': updated.targetDays,
                            'reminderTime': updated.reminderTime,
                          });
                          await _aiRepo
                              .markRenegotiationApplied(widget.habitId);
                          await _loadData();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          minimumSize: const Size(0, 40),
                        ),
                        child: const Text('Aplicar ajuste'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          _aiRepo.dismissRenegotiation(widget.habitId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Ahora no'),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.04, curve: Curves.easeOutCubic),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SectionSkeleton(itemCount: 4),
          ),
        ),
      );
    }

    if (_habit == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(),
        body: const ErrorStateView(
          message: 'El hábito no existe o fue eliminado.',
          icon: Icons.help_outline_rounded,
        ),
      );
    }

    final habit = _habit!;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
    final catIcon = AppTheme.categoryIcon(habit.category);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // header hero con gradiente
          _HeroHeader(
            habit: habit,
            catBg: catBg,
            catFg: catFg,
            catIcon: catIcon,
            isCompleted: _completedToday,
            onEdit: _editHabit,
            onDelete: _deleteHabit,
          ),

          // contenido principal
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // tarjeta de rachas con números display-lg
                _StreakCard(habit: habit)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 16),

                // banner de renegociación si la IA sugiere un ajuste
                _buildRenegotiationBanner(),

                // descripción del hábito (si existe)
                if (habit.description != null &&
                    habit.description!.trim().isNotEmpty) ...[
                  _DescriptionCard(description: habit.description!)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 300.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: 16),
                ],

                // botón check-in
                _CheckInButton(
                  isCompleted: _completedToday,
                  isShielded: _shieldedToday,
                  shieldsAvailable: _userData?.shieldsCount ?? 0,
                  onToggle: _completedToday ? _toggleToday : (_shieldedToday ? null : _toggleToday),
                  onUseShield: (!_completedToday && !_shieldedToday)
                      ? _useShield
                      : null,
                  onRemoveShield: _shieldedToday ? _removeShield : null,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 24),

                // sección actividad últimos 30 días
                _SectionLabel(label: 'Últimos 30 días')
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 12),

                _ActivityGrid(
                  logs: _recentLogs,
                  sickModeStart: _userData?.sickModeStart,
                  sickModeUntil: _userData?.sickModeUntil,
                ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
                const SizedBox(height: 24),

                // info adicional
                _SectionLabel(label: 'Información')
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms),
                const SizedBox(height: 12),

                _InfoCard(habit: habit)
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 300.ms)
                    .slideY(begin: 0.05),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HEADER HERO ====================

class _HeroHeader extends StatelessWidget {
  final HabitModel habit;
  final Color catBg;
  final Color catFg;
  final IconData catIcon;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroHeader({
    required this.habit,
    required this.catBg,
    required this.catFg,
    required this.catIcon,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: onDelete,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isCompleted
                ? AppTheme.streakGradient
                : AppTheme.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // icono categoría grande
                  Hero(
                    tag: 'habit_cat_${habit.id}',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(catIcon, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // chip categoría
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppTheme.categoryLabel(habit.category),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          habit.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (habit.isAIGenerated) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Generado por IA',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DESCRIPTION CARD ====================

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Descripción',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STREAK CARD ====================

class _StreakCard extends StatelessWidget {
  final HabitModel habit;

  const _StreakCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Row(
        children: [
          // racha actual con glow terciario
          Expanded(
            child: _StreakColumn(
              icon: Icons.local_fire_department_rounded,
              iconColor: scheme.tertiary,
              glowColor: scheme.tertiaryContainer.withValues(alpha: 0.4),
              value: '${habit.currentStreak}',
              label: 'Racha actual',
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
          // mejor racha
          Expanded(
            child: _StreakColumn(
              icon: Icons.emoji_events_rounded,
              iconColor: scheme.tertiary,
              glowColor: scheme.tertiaryContainer.withValues(alpha: 0.3),
              value: '${habit.bestStreak}',
              label: 'Mejor racha',
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String value;
  final String label;

  const _StreakColumn({
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ícono con glow
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: glowColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 12),
        // número grande display-lg
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'días',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==================== CHECK-IN BUTTON ====================

class _CheckInButton extends StatelessWidget {
  final bool isCompleted;
  final bool isShielded;
  final int shieldsAvailable;
  final VoidCallback? onToggle;
  final VoidCallback? onUseShield;
  final VoidCallback? onRemoveShield;

  const _CheckInButton({
    required this.isCompleted,
    required this.isShielded,
    required this.shieldsAvailable,
    this.onToggle,
    this.onUseShield,
    this.onRemoveShield,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isCompleted) {
      return GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.tertiary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: scheme.tertiary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Completado hoy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // estado escudo activo
    if (isShielded) {
      return GestureDetector(
        onTap: onRemoveShield,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Racha protegida hoy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // estado sin completar: botón principal + botón escudo si hay disponibles
    return Column(
      children: [
        GradientButton(
          onPressed: onToggle ?? () {},
          label: 'Marcar como completado',
          icon: Icons.radio_button_unchecked_rounded,
          gradient: AppTheme.heroGradient,
        ),
        if (shieldsAvailable > 0) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onUseShield,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Usar escudo ($shieldsAvailable disponible${shieldsAvailable == 1 ? '' : 's'})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== ACTIVITY GRID ====================

class _ActivityGrid extends StatelessWidget {
  final List<HabitLogModel> logs;
  final DateTime? sickModeStart;
  final DateTime? sickModeUntil;

  const _ActivityGrid({
    required this.logs,
    this.sickModeStart,
    this.sickModeUntil,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // sets de fechas por tipo para búsqueda O(1)
    final completedDates = <String>{};
    final shieldedDates = <String>{};
    for (final log in logs) {
      if (log.shielded) {
        shieldedDates.add(_dateKey(log.date));
      } else if (log.completed) {
        completedDates.add(_dateKey(log.date));
      }
    }

    // días cubiertos por sick mode
    final sickDates = <String>{};
    if (sickModeStart != null && sickModeUntil != null) {
      var day = DateTime(
          sickModeStart!.year, sickModeStart!.month, sickModeStart!.day);
      final end = DateTime(
          sickModeUntil!.year, sickModeUntil!.month, sickModeUntil!.day);
      while (!day.isAfter(end)) {
        sickDates.add(_dateKey(day));
        day = day.add(const Duration(days: 1));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // leyenda
          Wrap(
            spacing: 12,
            children: [
              _LegendDot(color: scheme.tertiary, label: 'Completado'),
              _LegendDot(color: scheme.primary, label: 'Escudo'),
              if (sickDates.isNotEmpty)
                _LegendDot(color: scheme.secondary, label: 'Enfermedad'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (i) {
              final date = now.subtract(Duration(days: 29 - i));
              final key = _dateKey(date);
              final done = completedDates.contains(key);
              final shielded = shieldedDates.contains(key);
              final sick = sickDates.contains(key) && !done && !shielded;
              final isToday = i == 29;

              String tooltip;
              if (done) {
                tooltip = '${date.day}/${date.month} — Completado';
              } else if (shielded) {
                tooltip = '${date.day}/${date.month} — Protegido por escudo';
              } else if (sick) {
                tooltip = '${date.day}/${date.month} — Modo enfermedad';
              } else {
                tooltip = '${date.day}/${date.month} — No completado';
              }

              return Tooltip(
                message: tooltip,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: done ? AppTheme.heroGradient : null,
                    color: done
                        ? null
                        : shielded
                            ? scheme.primaryContainer.withValues(alpha: 0.4)
                            : sick
                                ? scheme.secondaryContainer
                                    .withValues(alpha: 0.35)
                                : isToday
                                    ? scheme.primaryContainer
                                        .withValues(alpha: 0.15)
                                    : scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: shielded
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : sick
                            ? Border.all(
                                color: scheme.secondary.withValues(alpha: 0.4),
                                width: 1.5,
                              )
                            : isToday && !done
                                ? Border.all(
                                    color: scheme.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  )
                                : null,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : shielded
                          ? Icon(Icons.shield_rounded,
                              size: 13, color: scheme.primary)
                          : sick
                              ? Icon(Icons.medical_services_outlined,
                                  size: 12, color: scheme.secondary)
                              : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ==================== INFO CARD ====================

class _InfoCard extends StatelessWidget {
  final HabitModel habit;

  const _InfoCard({required this.habit});

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days =
        habit.targetDays.map((d) => _dayNames[d - 1]).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.repeat_rounded,
            label: 'Frecuencia',
            value: habit.frequency == 'daily' ? 'Diario' : habit.frequency,
          ),
          Divider(
            height: 1,
            indent: 56,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Días',
            value: days.isNotEmpty ? days : 'Todos',
          ),
          if (habit.reminderTime != null) ...[
            Divider(
              height: 1,
              indent: 56,
              color: scheme.outlineVariant.withValues(alpha: 0.12),
            ),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Recordatorio',
              value: habit.reminderTime!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPERS ====================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
