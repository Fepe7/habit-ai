import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../../levels/data/levels_repository.dart';
import '../../levels/domain/level_model.dart';
import '../../levels/presentation/widgets/category_level_card.dart';

/// Pantalla de perfil del usuario logueado.
/// Reutiliza la estética de PublicProfileScreen pero con datos propios.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepo;
  late final HabitRepository _habitRepo;
  late final LevelsRepository _levelsRepo;
  LevelsProfile? _levels;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _levelsRepo = LevelsRepository(uid: uid);
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final profile = await _levelsRepo.computeProfile();
    if (!mounted) return;
    setState(() => _levels = profile);
  }

  String _initials(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: StreamBuilder<UserModel>(
        stream: _userRepo.watchUser(),
        builder: (context, userSnap) {
          final userData = userSnap.data;
          final displayName = userData?.displayName ?? authUser?.displayName ?? 'Usuario';
          final email = userData?.email ?? authUser?.email ?? '';
          final initials = _initials(displayName, email);

          return SafeArea(
            bottom: false,
            child: StreamBuilder<List<HabitModel>>(
              stream: _habitRepo.watchActiveHabits(),
              builder: (context, habitsSnap) {
                final habits = habitsSnap.data ?? const <HabitModel>[];
                final bestStreakEver = habits.fold<int>(
                  0,
                  (m, h) => h.bestStreak > m ? h.bestStreak : m,
                );

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Row(
                          children: [
                            const DrawerMenuButton(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Perfil',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _ProfileHeader(
                        initials: initials,
                        displayName: displayName,
                        email: email,
                        username: userData?.username,
                        isProfilePublic: userData?.isProfilePublic ?? false,
                      )
                          .animate()
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: 0.05, end: 0, duration: 360.ms),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: _StatsBento(
                          totalHabits: habits.length,
                          bestStreakEver: bestStreakEver,
                          averageLevel: _levels?.averageLevel,
                        ),
                      ).animate().fadeIn(delay: 80.ms, duration: 320.ms),
                    ),

                    // Sección de maestría
                    if (_levels != null && _levels!.categories.isNotEmpty)
                      ..._buildMasterySlivers(_levels!),

                    if (habits.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Sin hábitos activos',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._buildHabitsSlivers(habits, scheme),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMasterySlivers(LevelsProfile profile) {
    final categoriesWithData = AppTheme.categories
        .where((c) => profile.categories.containsKey(c))
        .toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Text(
                'Maestría',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${profile.totalXp} XP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms, duration: 300.ms),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final level = profile.categories[categoriesWithData[index]]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CategoryLevelCard(
                  level: level,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CategoryDetailSheet(level: level),
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 140 + index * 50),
                      duration: 300.ms,
                    ),
              );
            },
            childCount: categoriesWithData.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHabitsSlivers(List<HabitModel> habits, ColorScheme scheme) {
    final byCategory = <String, List<HabitModel>>{};
    for (final h in habits) {
      byCategory.putIfAbsent(h.category, () => []).add(h);
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Text(
                'Hábitos activos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${habits.length}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = byCategory.keys.elementAt(index);
            return _CategorySection(
              category: category,
              habits: byCategory[category]!,
              animationIndex: index,
            );
          },
          childCount: byCategory.length,
        ),
      ),
    ];
  }
}

// ==================== WIDGETS INTERNOS ====================

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final String? username;
  final bool isProfilePublic;

  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.username,
    required this.isProfilePublic,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showUsername = isProfilePublic && username != null && username!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          // avatar con ring gradient
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryContainer, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primaryContainer,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (isProfilePublic)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            showUsername ? '@${username!}' : displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            showUsername ? displayName : email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (showUsername && email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsBento extends StatelessWidget {
  final int totalHabits;
  final int bestStreakEver;
  final double? averageLevel;

  const _StatsBento({
    required this.totalHabits,
    required this.bestStreakEver,
    required this.averageLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$totalHabits',
            label: 'Hábitos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$bestStreakEver',
            label: 'Mejor racha',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppTheme.tertiaryContainer,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: averageLevel == null ? '—' : averageLevel!.toStringAsFixed(1),
            label: 'Nivel',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool highlighted;

  const _StatTile({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: highlighted
            ? Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 1)
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<HabitModel> habits;
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppTheme.categoryIcon(category),
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                AppTheme.categoryLabel(category).toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...habits.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProfileHabitCard(habit: h).animate().fadeIn(
                    delay: Duration(milliseconds: animationIndex * 60),
                    duration: 300.ms,
                  ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ProfileHabitCard extends StatelessWidget {
  final HabitModel habit;
  const _ProfileHabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final denom = habit.bestStreak > 0 ? habit.bestStreak : 7;
    final progress = (habit.currentStreak / denom).clamp(0.0, 1.0).toDouble();
    final streakActive = habit.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                Icon(
                  AppTheme.categoryIcon(habit.category),
                  size: 20,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'máx ${habit.bestStreak}d',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: streakActive
                        ? AppTheme.tertiaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${habit.currentStreak}d',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: streakActive
                          ? AppTheme.tertiaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                'Racha',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
