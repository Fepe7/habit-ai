import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_habit_model.dart';
import '../domain/public_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla de detalle de un perfil público.
/// Solo lectura — sin check-in ni edición.
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late final PublicProfileRepository _repo;
  PublicProfileModel? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = PublicProfileRepository(uid: uid);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await _repo.getPublicProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: scheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Perfil no disponible',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // cabecera con gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: scheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Row(
                      children: [
                        AvatarCircle(
                          initials: _profile!.avatarInitials,
                          size: 72,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${_profile!.username}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // stats chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _StatPill(
                    icon: Icons.checklist_rounded,
                    label: '${_profile!.totalHabits} hábitos',
                  ),
                  _StatPill(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Mejor racha ${_profile!.bestStreakEver} días',
                  ),
                  _StatPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Nivel ${_profile!.averageLevel.toStringAsFixed(1)}',
                  ),
                  _StatPill(
                    icon: Icons.emoji_events_rounded,
                    label: '${_profile!.unlockedAchievements} logros',
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          // lista de hábitos agrupados por categoría
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text(
                'Hábitos activos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          StreamBuilder<List<PublicHabitModel>>(
            stream: _repo.watchPublicHabits(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final habits = snapshot.data ?? [];
              if (habits.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Sin hábitos activos',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                );
              }

              // agrupar por categoría
              final Map<String, List<PublicHabitModel>> byCategory = {};
              for (final habit in habits) {
                byCategory.putIfAbsent(habit.category, () => []).add(habit);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = byCategory.keys.elementAt(index);
                    final categoryHabits = byCategory[category]!;

                    return _CategorySection(
                      category: category,
                      habits: categoryHabits,
                      animationIndex: index,
                    );
                  },
                  childCount: byCategory.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ==================== WIDGETS INTERNOS ====================

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<PublicHabitModel> habits;
  final int animationIndex;

  const _CategorySection({
    required this.category,
    required this.habits,
    required this.animationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header de categoría
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppTheme.categoryIcon(category),
                  size: 15,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppTheme.categoryLabel(category),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${habits.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // tarjetas de hábitos
          ...habits.map(
            (habit) => _PublicHabitTile(habit: habit).animate().fadeIn(
                  delay: Duration(milliseconds: animationIndex * 60),
                  duration: 300.ms,
                ),
          ),
        ],
      ),
    );
  }
}

class _PublicHabitTile extends StatelessWidget {
  final PublicHabitModel habit;
  const _PublicHabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // emoji o icono de categoría como widget Icon
            habit.emoji != null
                ? Text(habit.emoji!, style: const TextStyle(fontSize: 20))
                : Icon(
                    AppTheme.categoryIcon(habit.category),
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            const SizedBox(width: 12),

            // título
            Expanded(
              child: Text(
                habit.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),

            // rachas
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'máx ${habit.bestStreak}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
