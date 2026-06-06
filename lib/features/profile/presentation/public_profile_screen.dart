import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../achievements/presentation/achievement_l10n.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../achievements/domain/achivement_model.dart';
import '../../social/data/follow_repository.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/user_directory_entry.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_challenge_model.dart';
import '../domain/public_habit_model.dart';
import '../domain/public_profile_model.dart';

/// Pantalla de detalle de perfil — soporta públicos, privados y estados de follow.
///
/// Flujo:
///  1. Lee user_directory/{uid} para saber si privado + ajustes granulares.
///  2. Lee isFollowing + hasPendingFollowRequest + isMutual + follower/following counts.
///  3. Decide qué mostrar según la tabla del plan.
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

enum _FollowState { none, following, pending }

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late final PublicProfileRepository _repo;
  late final FollowRepository _followRepo;
  late final UserDirectoryRepository _dirRepo;

  PublicProfileModel? _profile;
  UserDirectoryEntry? _dirEntry;
  _FollowState _followState = _FollowState.none;
  bool _isMutual = false;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _loading = true;
  bool _followLoading = false;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isOwnProfile => widget.userId == _myUid;

  @override
  void initState() {
    super.initState();
    _repo = PublicProfileRepository(uid: _myUid);
    _followRepo = FollowRepository(uid: _myUid);
    _dirRepo = UserDirectoryRepository(uid: _myUid);
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      // los counts se piden en paralelo pero con fallback a 0 si fallan
      final coreResults = await Future.wait([
        _repo.getPublicProfile(widget.userId),
        _dirRepo.getEntry(widget.userId),
        _followRepo.isFollowing(widget.userId),
        _followRepo.hasPendingFollowRequest(widget.userId),
      ]);

      if (!mounted) return;

      final profile = coreResults[0] as PublicProfileModel?;
      final dirEntry = coreResults[1] as UserDirectoryEntry?;
      final isFollowing = coreResults[2] as bool;
      final hasPending = coreResults[3] as bool;

      setState(() {
        _profile = profile;
        _dirEntry = dirEntry;
        _followState = isFollowing
            ? _FollowState.following
            : hasPending
                ? _FollowState.pending
                : _FollowState.none;
        _loading = false;
      });

      // counts e isMutual no bloquean la pantalla — se cargan después
      final extraResults = await Future.wait([
        _followRepo.getFollowerCount(widget.userId).catchError((_) => 0),
        _followRepo.getFollowingCount(widget.userId).catchError((_) => 0),
        if (!_isOwnProfile)
          _followRepo.isMutual(widget.userId).catchError((_) => false),
      ]);

      if (!mounted) return;
      setState(() {
        _followersCount = extraResults[0] as int;
        _followingCount = extraResults[1] as int;
        _isMutual = !_isOwnProfile ? extraResults[2] as bool : false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleFollowTap() async {
    if (_followLoading || _dirEntry == null) return;
    final entry = _dirEntry!;

    setState(() => _followLoading = true);
    try {
      final myUser = FirebaseAuth.instance.currentUser!;
      final myEntry = await _dirRepo.getEntry(_myUid);
      final myUsername = myEntry?.username ?? '';

      if (_followState == _FollowState.following) {
        await _followRepo.unfollow(widget.userId);
        if (mounted) {
          setState(() {
            _followState = _FollowState.none;
            _isMutual = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
        }
      } else if (_followState == _FollowState.pending) {
        await _followRepo.cancelFollowRequest(widget.userId);
        if (mounted) setState(() => _followState = _FollowState.none);
      } else if (_followState == _FollowState.none) {
        if (entry.isProfilePublic) {
          await _followRepo.follow(
            targetUid: widget.userId,
            targetUsername: entry.username,
            targetDisplayName: entry.displayName,
            targetPhotoUrl: entry.photoUrl,
            myUsername: myUsername,
            myDisplayName: myUser.displayName ?? '',
            myPhotoUrl: myUser.photoURL,
          );
          if (mounted) {
            setState(() {
              _followState = _FollowState.following;
              _followersCount++;
            });
          }
        } else {
          await _followRepo.sendFollowRequest(
            toUid: widget.userId,
            fromUsername: myUsername,
            fromDisplayName: myUser.displayName ?? '',
            fromPhotoUrl: myUser.photoURL,
            toUsername: entry.username,
            toDisplayName: entry.displayName,
            toPhotoUrl: entry.photoUrl,
          );
          if (mounted) setState(() => _followState = _FollowState.pending);
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null && _dirEntry == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined,
                  size: 64, color: scheme.outlineVariant),
              const SizedBox(height: 16),
              Text(S.of(context).publicProfileNotAvailable,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final isPrivate = _dirEntry != null
        ? !_dirEntry!.isProfilePublic
        : (_profile != null ? !_profile!.isProfilePublic : false);

    final canSeeContent = !isPrivate ||
        _isOwnProfile ||
        _followState == _FollowState.following;

    final showStats = _dirEntry?.showStats ?? true;
    final showHabits = _dirEntry?.showHabits ?? true;
    final showAchievements = _dirEntry?.showAchievements ?? true;
    final showFollowerCount = _dirEntry?.showFollowerCount ?? true;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '@${_dirEntry?.username ?? _profile?.username ?? ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              profile: _profile,
              dirEntry: _dirEntry,
              followState: _followState,
              followLoading: _followLoading,
              isOwnProfile: _isOwnProfile,
              isMutual: _isMutual,
              followersCount: _followersCount,
              followingCount: _followingCount,
              showFollowerCount: showFollowerCount,
              onFollowTap: _handleFollowTap,
            )
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.05, end: 0, duration: 360.ms),
          ),

          if (!canSeeContent)
            SliverToBoxAdapter(
              child: _PrivateProfileMessage(
                isPending: _followState == _FollowState.pending,
              ).animate().fadeIn(delay: 100.ms),
            )
          else ...[
            if (_profile != null && showStats)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _StatsBento(
                    profile: _profile!,
                    showAchievements: showAchievements,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 320.ms),
              ),

            if (_profile != null &&
                showAchievements &&
                _profile!.unlockedAchievementTypes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _AchievementsShowcase(
                    types: _profile!.unlockedAchievementTypes,
                  ),
                ).animate().fadeIn(delay: 140.ms, duration: 320.ms),
              ),

            if (showHabits)
              StreamBuilder<List<PublicHabitModel>>(
                stream: _repo.watchPublicHabits(
                  widget.userId,
                  // el owner y sus seguidores ven hábitos 'followers'
                  viewerIsFollower: _isOwnProfile ||
                      _followState == _FollowState.following,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final habits = snap.data ?? [];
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: _HabitsGrid(habits: habits),
                    ),
                  );
                },
              ),

            // sección de retos públicos
            StreamBuilder<List<PublicChallengeModel>>(
              stream: _repo.watchPublicChallenges(widget.userId),
              builder: (context, snap) {
                final challenges = snap.data ?? [];
                if (challenges.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _ChallengesSection(
                      challenges: challenges,
                      ownerUid: widget.userId,
                      publicRepo: _repo,
                    ),
                  ),
                );
              },
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ==================== WIDGETS INTERNOS ====================

class _ProfileHeader extends StatelessWidget {
  final PublicProfileModel? profile;
  final UserDirectoryEntry? dirEntry;
  final _FollowState followState;
  final bool followLoading;
  final bool isOwnProfile;
  final bool isMutual;
  final int followersCount;
  final int followingCount;
  final bool showFollowerCount;
  final VoidCallback onFollowTap;

  const _ProfileHeader({
    required this.profile,
    required this.dirEntry,
    required this.followState,
    required this.followLoading,
    required this.isOwnProfile,
    required this.isMutual,
    required this.followersCount,
    required this.followingCount,
    required this.showFollowerCount,
    required this.onFollowTap,
  });

  String get _displayName =>
      profile?.displayName ?? dirEntry?.displayName ?? 'Usuario';
  String get _username => profile?.username ?? dirEntry?.username ?? '';
  String? get _photoUrl => profile?.photoUrl ?? dirEntry?.photoUrl;
  String get _initials =>
      profile?.avatarInitials ?? dirEntry?.avatarInitials ?? 'U';
  int get _unlockedAchievements => profile?.unlockedAchievements ?? 0;
  DateTime? get _createdAt => profile?.createdAt;
  String? get _bio => profile?.bio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          // Avatar con badge de verificado (solo para veteranos con 5+ logros)
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
                  child: AvatarCircle(
                    initials: _initials,
                    size: 96,
                    photoUrl: _photoUrl,
                    backgroundColor: scheme.primaryContainer,
                    textColor: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (_unlockedAchievements >= 5)
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
            '@$_username',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),

          // "Miembro desde"
          if (_createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              S.of(context).publicProfileMemberSince(_formatMonth(_createdAt!, S.of(context))),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],

          // bio del usuario
          if (_bio != null && _bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _bio!.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ),
          ],

          // Contadores de seguidores / siguiendo (tapeables solo en perfil propio)
          if (showFollowerCount) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterChip(
                  value: followersCount,
                  label: S.of(context).profileFollowers,
                  onTap: isOwnProfile
                      ? () => context.push('/followers?tab=0')
                      : null,
                ),
                const SizedBox(width: 24),
                _CounterChip(
                  value: followingCount,
                  label: S.of(context).profileFollowing,
                  onTap: isOwnProfile
                      ? () => context.push('/followers?tab=1')
                      : null,
                ),
              ],
            ),
          ],

          if (!isOwnProfile) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMutual) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded,
                            size: 13, color: AppTheme.success),
                        const SizedBox(width: 5),
                        Text(
                          S.of(context).publicProfileMutualFollower,
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                _FollowButton(
                  state: followState,
                  loading: followLoading,
                  onTap: onFollowTap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMonth(DateTime date, S l10n) {
    final meses = [
      l10n.monthFullJan, l10n.monthFullFeb, l10n.monthFullMar, l10n.monthFullApr,
      l10n.monthFullMay, l10n.monthFullJun, l10n.monthFullJul, l10n.monthFullAug,
      l10n.monthFullSep, l10n.monthFullOct, l10n.monthFullNov, l10n.monthFullDec,
    ];
    return '${meses[date.month - 1]} ${date.year}';
  }
}

class _CounterChip extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _CounterChip({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final column = Column(
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
                color: onTap != null
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
    if (onTap == null) return column;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: column,
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _FollowButton extends StatelessWidget {
  final _FollowState state;
  final bool loading;
  final VoidCallback onTap;

  const _FollowButton({
    required this.state,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String label;
    Color bg;
    Color fg;
    IconData icon;

    final l10n = S.of(context);
    switch (state) {
      case _FollowState.following:
        label = l10n.exploreFollowing;
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurface;
        icon = Icons.check_rounded;
        break;
      case _FollowState.pending:
        label = l10n.exploreRequested;
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        icon = Icons.hourglass_top_rounded;
        break;
      case _FollowState.none:
        label = l10n.exploreFollow;
        bg = scheme.primary;
        fg = scheme.onPrimary;
        icon = Icons.person_add_rounded;
        break;
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(50),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PrivateProfileMessage extends StatelessWidget {
  final bool isPending;

  const _PrivateProfileMessage({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).publicProfilePrivate,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? S.of(context).publicProfileRequestPending
                : S.of(context).publicProfileFollowToSee,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatsBento extends StatelessWidget {
  final PublicProfileModel profile;
  final bool showAchievements;

  const _StatsBento({
    required this.profile,
    required this.showAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${profile.totalHabits}',
                label: S.of(context).profileHabits,
                icon: Icons.track_changes_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: '${profile.bestStreakEver}d',
                label: S.of(context).profileBestStreak,
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.tertiaryContainer,
                highlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: profile.averageLevel.toStringAsFixed(1),
                label: S.of(context).publicProfileAverageLevel,
                icon: Icons.bar_chart_rounded,
              ),
            ),
            if (showAchievements) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: '${profile.unlockedAchievements}',
                  label: S.of(context).achievementsTitle,
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ],
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
            ? Border.all(
                color: scheme.primary.withValues(alpha: 0.3), width: 1)
            : Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16,
                    color: iconColor ?? scheme.onSurfaceVariant),
                const SizedBox(width: 5),
              ],
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _AchievementsShowcase extends StatelessWidget {
  final List<String> types;

  const _AchievementsShowcase({required this.types});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // máximo 5 visibles en el scroll
    final visible = types.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              S.of(context).achievementsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${types.length}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                _AchievementBadge(type: visible[i], index: i),
                if (i < visible.length - 1) const SizedBox(width: 16),
              ],
              if (types.length > 5) ...[
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '+${types.length - 5}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      S.of(context).publicProfileMore,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String type;
  final int index;

  const _AchievementBadge({required this.type, required this.index});

  @override
  Widget build(BuildContext context) {
    final info = AchievementCatalog.getInfo(type);
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(info.icon, size: 24, color: info.color),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 56,
          child: Text(
            AchievementL10n.title(type, S.of(context)),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 280.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1),
            duration: 280.ms, curve: Curves.easeOut);
  }
}

class _HabitsGrid extends StatelessWidget {
  final List<PublicHabitModel> habits;

  const _HabitsGrid({required this.habits});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            S.of(context).publicProfileNoHabits,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              S.of(context).profileActiveHabits,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < habits.length; i++)
                  SizedBox(
                    width: chipWidth,
                    child: _HabitChip(habit: habits[i], index: i),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HabitChip extends StatelessWidget {
  final PublicHabitModel habit;
  final int index;

  const _HabitChip({required this.habit, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final streakActive = habit.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              habit.emoji != null
                  ? Text(habit.emoji!, style: const TextStyle(fontSize: 28))
                  : Icon(
                      AppTheme.categoryIcon(habit.category),
                      size: 28,
                      color: scheme.primary,
                    ),
              const Spacer(),
              if (streakActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: AppTheme.tertiaryContainer,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}d',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppTheme.tertiaryContainer,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            habit.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            AppTheme.categoryLabel(habit.category),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, end: 0, duration: 280.ms);
  }
}

// ==================== RETOS PÚBLICOS ====================

class _ChallengesSection extends StatelessWidget {
  final List<PublicChallengeModel> challenges;
  final String ownerUid;
  final PublicProfileRepository publicRepo;

  const _ChallengesSection({
    required this.challenges,
    required this.ownerUid,
    required this.publicRepo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.challengesSectionTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ...challenges.map((c) => _ChallengeCard(
              challenge: c,
              publicRepo: publicRepo,
            )),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final PublicChallengeModel challenge;
  final PublicProfileRepository publicRepo;

  const _ChallengeCard({required this.challenge, required this.publicRepo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = AppTheme.categoryBg(
        challenge.habitCategory, Theme.of(context).brightness);
    final fg = AppTheme.categoryFg(
        challenge.habitCategory, Theme.of(context).brightness);
    final s = S.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppTheme.categoryIcon(challenge.habitCategory),
                    size: 15,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    challenge.habitTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${challenge.durationDays}d',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 14, color: AppTheme.tertiaryContainer),
                const SizedBox(width: 4),
                Text(
                  '${challenge.currentStreak}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${challenge.completedCount}/${challenge.durationDays}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                // progreso del compañero (si también lo hizo público)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('public_profiles')
                      .doc(challenge.partnerUid)
                      .collection('challenges')
                      .doc(challenge.challengeId)
                      .snapshots(),
                  builder: (ctx, snap) {
                    final partnerPublic = snap.data?.exists ?? false;
                    if (partnerPublic && snap.data != null) {
                      final partnerData = PublicChallengeModel.fromFirestore(
                          snap.data!.data()!, snap.data!.id);
                      return Text(
                        '${challenge.partnerDisplayName ?? s.challengeAnonymousPartner}: ${partnerData.completedCount}/${challenge.durationDays}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      );
                    }
                    return Text(
                      s.challengeAnonymousPartner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
