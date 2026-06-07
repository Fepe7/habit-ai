import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../auth/data/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/user_model.dart';
import 'widgets/avatar_picker_sheet.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../../levels/data/levels_repository.dart';
import '../../levels/domain/level_model.dart';
import '../../levels/presentation/widgets/category_level_card.dart';
import '../../levels/presentation/category_l10n.dart';
import '../../social/data/follow_repository.dart';
import '../../social/data/reaction_repository.dart';
import '../../social/domain/reaction_model.dart';
import '../../social/presentation/widgets/reaction_bar.dart';

/// Pantalla de perfil del usuario logueado.
/// Reutiliza la estética de PublicProfileScreen pero con datos propios.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final UserRepository _userRepo;
  late final HabitRepository _habitRepo;
  late final LevelsRepository _levelsRepo;
  late final FollowRepository _followRepo;
  late final ReactionRepository _reactRepo;
  LevelsProfile? _levels;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _levelsRepo = LevelsRepository(uid: uid);
    _followRepo = FollowRepository(uid: uid);
    _reactRepo = ReactionRepository();
    _loadLevels();
    _loadFollowCounts();
  }

  Future<void> _loadLevels() async {
    final profile = await _levelsRepo.computeProfile();
    if (!mounted) return;
    setState(() => _levels = profile);
  }

  Future<void> _loadFollowCounts() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final results = await Future.wait([
      _followRepo.getFollowerCount(uid).catchError((_) => 0),
      _followRepo.getFollowingCount(uid).catchError((_) => 0),
    ]);
    if (!mounted) return;
    setState(() {
      _followersCount = results[0];
      _followingCount = results[1];
    });
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
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: StreamBuilder<UserModel>(
        stream: _userRepo.watchUser(),
        builder: (context, userSnap) {
          final userData = userSnap.data;
          // prioridad: Firestore > Firebase Auth > fallback
          final displayName = (userData?.displayName?.isNotEmpty == true
                  ? userData!.displayName!
                  : null) ??
              (authUser?.displayName?.isNotEmpty == true
                  ? authUser!.displayName!
                  : null) ??
              S.of(context)!.settingsFallbackUsername;
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
                                S.of(context)!.profileTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: S.of(context)!.profileOpenSettings,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => context.pushNamed('settings'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _ProfileHeader(
                        initials: initials,
                        displayName: displayName,
                        username: userData?.username,
                        bio: userData?.bio,
                        isProfilePublic: userData?.isProfilePublic ?? false,
                        photoUrl: userData?.photoUrl,
                        followersCount: _followersCount,
                        followingCount: _followingCount,
                        onAvatarTap: () => AvatarPickerSheet.show(
                          context,
                          currentPhotoUrl: userData?.photoUrl,
                        ),
                        onEditProfile: () => context.pushNamed('edit-profile'),
                      )
                          .animate()
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: 0.05, end: 0, duration: 360.ms),
                    ),

                    StreamBuilder<List<ReactionModel>>(
                      stream: _reactRepo.watchReactionsForProfile(
                          FirebaseAuth.instance.currentUser!.uid),
                      builder: (context, snap) {
                        final reactions = snap.data ?? [];
                        if (reactions.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: ProfileReactionsPill(
                              myUid: FirebaseAuth.instance.currentUser!.uid,
                              reactions: reactions,
                              isOwnProfile: true,
                              onTap: (_) async {},
                            ),
                          ).animate().fadeIn(delay: 60.ms, duration: 280.ms),
                        );
                      },
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
                                S.of(context)!.profileNoHabits,
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

                    SliverToBoxAdapter(child: SizedBox(height: context.bottomNavInset)),
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
                S.of(context)!.profileMastery,
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
                  onTap: () => showAppBottomSheet(
                    context: context,
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
                S.of(context)!.profileActiveHabits,
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
  final String? username;
  final String? bio;
  final bool isProfilePublic;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEditProfile;
  final int followersCount;
  final int followingCount;

  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.isProfilePublic,
    required this.followersCount,
    required this.followingCount,
    this.photoUrl,
    this.onAvatarTap,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUsername = username != null && username!.isNotEmpty;
    final hasBio = bio != null && bio!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          // Avatar con anillo de gradiente y badge discreto de cámara
          GestureDetector(
            onTap: onAvatarTap,
            child: AvatarCircle(
              initials: initials,
              photoUrl: photoUrl,
              size: 96,
              badge: AvatarBadge.camera,
              ringGradient: true,
            ),
          ),
          const SizedBox(height: 18),

          // nombre principal
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),

          // @username + chip de perfil público
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasUsername)
                Text(
                  '@$username',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              if (hasUsername && isProfilePublic)
                const SizedBox(width: 6),
              if (isProfilePublic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded,
                          size: 12, color: scheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Público',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // bio
          if (hasBio) ...[
            const SizedBox(height: 10),
            Text(
              bio!.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],

          // contadores de seguidores / siguiendo
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FollowCounter(
                value: followersCount,
                label: S.of(context)!.profileFollowers,
                onTap: () => context.push('/followers?tab=0'),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              _FollowCounter(
                value: followingCount,
                label: S.of(context)!.profileFollowing,
                onTap: () => context.push('/followers?tab=1'),
              ),
            ],
          ),

          // botón de edición de perfil
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(S.of(context)!.profileEditButton),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
            ),
          ),
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
            label: S.of(context)!.profileHabits,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$bestStreakEver',
            label: S.of(context)!.profileBestStreak,
            icon: Icons.local_fire_department_rounded,
            iconColor: AppTheme.tertiaryContainer,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: averageLevel == null ? '—' : averageLevel!.toStringAsFixed(1),
            label: S.of(context)!.profileLevel,
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
        // racha: gradiente sutil ámbar; resto: superficie
        gradient: highlighted
            ? LinearGradient(
                colors: [
                  AppTheme.tertiaryContainer.withValues(alpha: 0.18),
                  AppTheme.tertiaryContainer.withValues(alpha: 0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: highlighted ? null : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
                      color: highlighted ? AppTheme.tertiaryContainer : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlighted
                      ? AppTheme.tertiaryContainer.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
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
                CategoryL10n.label(category, S.of(context)!).toUpperCase(),
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
        // separación por shift de superficie, sin borde duro
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
                  S.of(context)!.profileBestStreakShort(habit.bestStreak),
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
                S.of(context)!.profileStreak,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
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

/// Contador tapeable de seguidores/siguiendo para el perfil propio.
class _FollowCounter extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onTap;

  const _FollowCounter({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            _format(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
