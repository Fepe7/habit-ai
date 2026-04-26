import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/router/main_shell.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../data/stats_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/domain/achivement_model.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/weekly_review_model.dart';
import '../../ai/domain/butterfly_projection_model.dart';
import '../../ai/domain/renegotiation_model.dart';
import '../../levels/data/levels_repository.dart';
import '../../levels/domain/level_model.dart';

/// Dashboard con gráficas de progreso y estadísticas — Editorial Vitality
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StatsRepository _statsRepo;
  late AchievementRepository _achievementRepo;
  late AIRepository _aiRepo;
  late LevelsRepository _levelsRepo;
  bool _initialized = false;
  bool _generatingReview = false;
  bool _generatingButterfly = false;

  Map<String, dynamic> _generalStats = {};
  List<DailyProgress> _weeklyProgress = [];
  List<CategoryStat> _categoryStats = [];
  List<HabitModel> _topStreaks = [];
  List<AchievementModel> _achievements = [];
  bool _loading = true;

  int get _perfectDays =>
      _weeklyProgress.where((d) => d.total > 0 && d.completed == d.total).length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _statsRepo = StatsRepository(uid: user.uid);
        _achievementRepo = AchievementRepository(uid: user.uid);
        _aiRepo = AIRepository(uid: user.uid);
        _levelsRepo = LevelsRepository(uid: user.uid);
        _loadStats();
      }
      _initialized = true;
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _statsRepo.getGeneralStats(),
        _statsRepo.getWeeklyProgress(),
        _statsRepo.getCategoryDistribution(),
        _statsRepo.getTopStreaks(),
        _achievementRepo.watchAchievements().first,
      ]);
      if (mounted) {
        setState(() {
          _generalStats = results[0] as Map<String, dynamic>;
          _weeklyProgress = results[1] as List<DailyProgress>;
          _categoryStats = results[2] as List<CategoryStat>;
          _topStreaks = results[3] as List<HabitModel>;
          _achievements = results[4] as List<AchievementModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? _buildLoadingSkeleton(context)
            : _generalStats['totalActive'] == 0
                ? _buildEmptyState(context)
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(context)),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, context.bottomNavInset),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildTodaySummary(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.05),

                              const SizedBox(height: 14),

                              _buildStatCards(context)
                                  .animate()
                                  .fadeIn(delay: 100.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              const SizedBox(height: 14),

                              _buildRenegotiationsCard(context)
                                  .animate()
                                  .fadeIn(delay: 140.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              _buildWeeklyReviewCard(context)
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              const SizedBox(height: 14),

                              _buildButterflyCard(context)
                                  .animate()
                                  .fadeIn(delay: 175.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              const SizedBox(height: 14),

                              GestureDetector(
                                onTap: () => context.goNamed('levels'),
                                child: _buildMasteryCard(context),
                              )
                                  .animate()
                                  .fadeIn(delay: 190.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              const SizedBox(height: 14),

                              GestureDetector(
                                onTap: () => context.goNamed('dashboard-weekly'),
                                child: _buildWeeklyChart(context),
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),

                              if (_categoryStats.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () =>
                                      context.goNamed('dashboard-categories'),
                                  child: _buildCategoryChart(context),
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms, duration: 400.ms)
                                    .slideY(begin: 0.05),
                              ],

                              if (_topStreaks.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () =>
                                      context.goNamed('dashboard-streaks'),
                                  child: _buildTopStreaks(context),
                                )
                                    .animate()
                                    .fadeIn(delay: 400.ms, duration: 400.ms)
                                    .slideY(begin: 0.05),
                              ],

                              const SizedBox(height: 14),

                              GestureDetector(
                                onTap: () => context.goNamed('achievements'),
                                child: _buildAchievements(context),
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 400.ms)
                                  .slideY(begin: 0.05),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // header asimetrico: titulo izquierda, icono derecha
  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                  'Progreso',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tu avance esta semana',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              boxShadow: AppTheme.ambientShadow(),
            ),
            child: Icon(Icons.insights_rounded, color: scheme.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReviewManually() async {
    setState(() => _generatingReview = true);
    try {
      final weekId = await _aiRepo.generateWeeklyReview();
      if (!mounted) return;
      if (weekId == null) {
        AppSnackBar.showInfo(
          context,
          'Necesitas al menos 3 check-ins esta semana para generar la revisión',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _generatingReview = false);
    }
  }

  Future<void> _generateButterflyManually() async {
    setState(() => _generatingButterfly = true);
    try {
      final monthId = await _aiRepo.generateButterflyProjection();
      if (!mounted) return;
      if (monthId == null) {
        AppSnackBar.showInfo(
          context,
          'Necesitas al menos 10 check-ins este mes para generar la proyección',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _generatingButterfly = false);
    }
  }

  // card de hábitos con renegociación pendiente — solo visible si hay sugerencias
  Widget _buildRenegotiationsCard(BuildContext context) {
    return StreamBuilder<List<RenegotiationModel>>(
      stream: _aiRepo.watchActiveRenegotiations(),
      builder: (context, snapshot) {
        final renos = snapshot.data ?? [];
        if (renos.isEmpty) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final displayed = renos.take(3).toList();

        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hábitos que ajustar (${renos.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...displayed.map((reno) => InkWell(
                    onTap: () => context.goNamed(
                      'habit-detail',
                      pathParameters: {'habitId': reno.habitId},
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reno.habitTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  reno.diagnosis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  // card del simulador efecto mariposa
  Widget _buildButterflyCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<ButterflyProjectionModel?>(
      stream: _aiRepo.watchLatestButterfly(),
      builder: (context, snapshot) {
        final projection = snapshot.data;

        if (projection == null) {
          return _SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🦋', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efecto Mariposa',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Descubre cómo serás en 3 años si mantienes tus hábitos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: FilledButton.tonalIcon(
                          onPressed: _generatingButterfly
                              ? null
                              : _generateButterflyManually,
                          icon: _generatingButterfly
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_rounded,
                                  size: 16),
                          label: Text(
                            _generatingButterfly
                                ? 'Generando…'
                                : 'Generar proyección',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppTheme.tertiary.withValues(alpha: 0.14),
                            foregroundColor: AppTheme.tertiary,
                            minimumSize: const Size(0, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            shape: const StadiumBorder(),
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

        // card con proyección existente — tap navega al detalle
        return GestureDetector(
          onTap: () => context.goNamed(
            'butterfly-projection',
            pathParameters: {'monthId': projection.monthId},
          ),
          child: _SectionCard(
            gradient: LinearGradient(
              colors: [
                AppTheme.tertiary.withValues(alpha: 0.14),
                AppTheme.tertiaryContainer.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🦋', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Efecto Mariposa',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      projection.monthId,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ],
                ),
                if (projection.titleKeep.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          projection.titleKeep,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    projection.storyKeep,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _generatingButterfly
                          ? null
                          : _generateButterflyManually,
                      icon: _generatingButterfly
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        _generatingButterfly ? 'Regenerando…' : 'Regenerar',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // card de revision semanal con IA
  Widget _buildWeeklyReviewCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<WeeklyReviewModel?>(
      stream: _aiRepo.watchLatestWeeklyReview(),
      builder: (context, snapshot) {
        final review = snapshot.data;

        if (review == null) {
          return _SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.insights_rounded,
                      color: AppTheme.tertiary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisión semanal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pide a la IA que analice tu semana: rachas, wins y áreas de mejora',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: FilledButton.tonalIcon(
                          onPressed:
                              _generatingReview ? null : _generateReviewManually,
                          icon: _generatingReview
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: Text(
                            _generatingReview ? 'Generando…' : 'Generar ahora',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primaryContainer.withValues(alpha: 0.3),
                            foregroundColor: scheme.primary,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: const StadiumBorder(),
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

        return GestureDetector(
          onTap: () => context.goNamed(
            'weekly-review',
            pathParameters: {'weekId': review.weekId},
          ),
          child: _SectionCard(
            gradient: LinearGradient(
              colors: [
                AppTheme.tertiaryContainer.withValues(alpha: 0.2),
                scheme.primaryContainer.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded,
                        color: AppTheme.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revisión semanal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      review.weekId,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ],
                ),
                if (review.focus.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    review.focus,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          _generatingReview ? null : _generateReviewManually,
                      icon: _generatingReview
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        _generatingReview ? 'Regenerando…' : 'Regenerar',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.bar_chart_rounded,
      title: 'Sin datos todavía',
      subtitle: 'Crea hábitos y completa check-ins para ver tus estadísticas aquí',
      actionLabel: 'Crear primer hábito',
      onAction: () => context.go('/'),
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, context.bottomNavInset),
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        const ChartSkeleton(height: 120),
        const SizedBox(height: 14),
        const SectionSkeleton(itemCount: 1),
        const SizedBox(height: 14),
        const ChartSkeleton(height: 200),
      ],
    );
  }

  // hero card con progreso de hoy
  Widget _buildTodaySummary(BuildContext context) {
    final completed = _generalStats['completedToday'] ?? 0;
    final total = _generalStats['todayTotal'] ?? 0;
    final percentage = total == 0 ? 0.0 : completed / total;
    final allDone = percentage == 1.0 && total > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: allDone ? AppTheme.streakGradient : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.ambientShadow(opacity: 0.14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (ctx, v, _) => SizedBox(
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
                      child: allDone && percentage == 1.0
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 28)
                          : Text(
                              '${(percentage * 100).round()}%',
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
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone ? '¡Día perfecto!' : 'Hoy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? 'No tienes hábitos programados hoy'
                        : '$completed de $total completados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // fila de 3 stat cards
  Widget _buildStatCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Mejor racha',
            value: '${_generalStats['bestStreak'] ?? 0}',
            suffix: 'd',
            color: AppTheme.tertiary,
            bgColor: AppTheme.tertiaryContainer.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completados',
            value: '${_generalStats['totalCompletedAllTime'] ?? 0}',
            color: AppTheme.primary,
            bgColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            label: 'Días perfectos',
            value: '$_perfectDays',
            color: AppTheme.secondary,
            bgColor: AppTheme.secondaryContainer.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }

  // grafica de barras semanal
  Widget _buildWeeklyChart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.trending_up_rounded,
            label: 'Última semana',
            color: scheme.primary,
            hasChevron: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(12),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final progress = _weeklyProgress[group.x.toInt()];
                      return BarTooltipItem(
                        '${progress.completed}/${progress.total}',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weeklyProgress.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _dayLabel(_weeklyProgress[index].date),
                              style: TextStyle(
                                color: _isToday(_weeklyProgress[index].date)
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: _isToday(_weeklyProgress[index].date)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                // solo lineas horizontales muy sutiles, sin bordes
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_weeklyProgress.length, (i) {
                  final progress = _weeklyProgress[i];
                  final pct = progress.percentage * 100;
                  final isToday = _isToday(progress.date);
                  final isDone = pct >= 100;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: pct == 0 && progress.total > 0 ? 2 : pct,
                        gradient: isDone
                            ? AppTheme.streakGradient
                            : isToday
                                ? AppTheme.heroGradient
                                : LinearGradient(
                                    colors: [
                                      scheme.primary.withValues(alpha: 0.5),
                                      scheme.primaryContainer.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                        color: progress.total == 0
                            ? scheme.outlineVariant.withValues(alpha: 0.2)
                            : null,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // distribucion por categorias con barras horizontales
  Widget _buildCategoryChart(BuildContext context) {
    final totalHabits = _categoryStats.fold<int>(0, (sum, c) => sum + c.count);
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.pie_chart_rounded,
            label: 'Por categoría',
            color: scheme.primary,
            hasChevron: true,
          ),
          const SizedBox(height: 16),
          ..._categoryStats.map((stat) {
            final fraction = stat.count / totalHabits;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.categoryBg(stat.category),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppTheme.categoryIcon(stat.category),
                      size: 18,
                      color: AppTheme.categoryFg(stat.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppTheme.categoryLabel(stat.category),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${stat.count}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 5,
                            backgroundColor: scheme.outlineVariant.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.categoryFg(stat.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // top rachas activas
  Widget _buildTopStreaks(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.local_fire_department_rounded,
            label: 'Rachas activas',
            color: AppTheme.tertiary,
            hasChevron: true,
          ),
          const SizedBox(height: 14),
          ..._topStreaks.map((habit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.categoryBg(habit.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppTheme.categoryIcon(habit.category),
                      size: 18,
                      color: AppTheme.categoryFg(habit.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit.title,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppTheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}d',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // logros recientes
  Widget _buildAchievements(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlockedTypes = _achievements.map((a) => a.type).toSet();
    final total = AchievementCatalog.all.length;
    final count = unlockedTypes.length;
    final recent = _achievements.take(4).toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 20, color: AppTheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Logros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count/$total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Text(
              'Completa hábitos para desbloquear logros',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: recent.map((achievement) {
                final info = AchievementCatalog.getInfo(achievement.type);
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(info.icon, color: info.color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        info.title,
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // card compacto de maestría con mini-radar y nivel medio
  Widget _buildMasteryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      child: FutureBuilder<LevelsProfile>(
        future: _levelsRepo.computeProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech_rounded, size: 20, color: AppTheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perfil de Maestría',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (profile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nvl ${profile.averageLevel.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),

              const SizedBox(height: 16),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (profile == null || profile.categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Completa hábitos para desbloquear tu perfil de maestría.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else ...[
                // mini radar
                SizedBox(
                  height: 160,
                  child: _MiniRadarChart(profile: profile),
                ),
                const SizedBox(height: 12),
                // fila con las 3 categorías más altas
                Builder(
                  builder: (context) {
                    final sorted = AppTheme.categories
                        .map((cat) => profile.categories[cat] ?? CategoryLevel.fromXp(cat, 0))
                        .toList()
                      ..sort((a, b) => b.xp.compareTo(a.xp));
                    final top3 = sorted.take(3).toList();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: top3.map((l) => _MiniLevelBadge(level: l)).toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _dayLabel(DateTime date) {
    if (_isToday(date)) return 'Hoy';
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ==================== WIDGETS INTERNOS ====================

/// Mini radar para el card compacto del dashboard
class _MiniRadarChart extends StatelessWidget {
  final LevelsProfile profile;

  const _MiniRadarChart({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dataEntries = AppTheme.categories.map((cat) {
      final level = profile.categories[cat];
      return RadarEntry(value: level != null ? level.level.toDouble() : 0.0);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: dataEntries,
            fillColor: scheme.primary.withValues(alpha: 0.15),
            borderColor: scheme.primary,
            borderWidth: 2,
            entryRadius: 2,
          ),
        ],
        radarShape: RadarShape.polygon,
        tickCount: 5,
        ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.15),
          width: 1,
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 9,
        ),
        getTitle: (index, angle) {
          final cat = AppTheme.categories[index];
          return RadarChartTitle(
            text: AppTheme.categoryLabel(cat),
            angle: 0,
          );
        },
      ),
    );
  }
}

/// Badge de nivel compacto para el card del dashboard
class _MiniLevelBadge extends StatelessWidget {
  final CategoryLevel level;

  const _MiniLevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final fgColor = AppTheme.categoryFg(level.category);
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.categoryBg(level.category),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(AppTheme.categoryIcon(level.category), color: fgColor, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Nvl ${level.level}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Card de sección reutilizable — surfaceContainerLowest + ambient shadow + sin bordes
class _SectionCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;

  const _SectionCard({required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? scheme.surfaceContainerLowest : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: child,
    );
  }
}

/// Header de sección con icono + label + chevron opcional
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool hasChevron;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    this.hasChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (hasChevron)
          Icon(Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}

/// Stat card compacta para la fila de 3 métricas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
