import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../social/data/follow_repository.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/user_directory_entry.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_habit_model.dart';
import '../domain/public_profile_model.dart';

/// Pantalla de detalle de perfil — soporta públicos, privados y estados de follow.
///
/// Flujo:
///  1. Lee user_directory/{uid} para saber si privado + ajustes granulares.
///  2. Lee isFollowing + hasPendingFollowRequest.
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
    final results = await Future.wait([
      _repo.getPublicProfile(widget.userId),
      _dirRepo.getEntry(widget.userId),
      _followRepo.isFollowing(widget.userId),
      _followRepo.hasPendingFollowRequest(widget.userId),
    ]);

    if (!mounted) return;

    final profile = results[0] as PublicProfileModel?;
    final dirEntry = results[1] as UserDirectoryEntry?;
    final isFollowing = results[2] as bool;
    final hasPending = results[3] as bool;

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
  }

  Future<void> _handleFollowTap() async {
    if (_followLoading || _dirEntry == null) return;
    final entry = _dirEntry!;

    setState(() => _followLoading = true);
    try {
      final myUser = FirebaseAuth.instance.currentUser!;

      if (_followState == _FollowState.following) {
        await _followRepo.unfollow(widget.userId);
        if (mounted) setState(() => _followState = _FollowState.none);
      } else if (_followState == _FollowState.none) {
        if (entry.isProfilePublic) {
          // follow directo
          await _followRepo.follow(
            targetUid: widget.userId,
            targetUsername: entry.username,
            targetDisplayName: entry.displayName,
            targetPhotoUrl: entry.photoUrl,
            myUsername: '', // se obtiene en el repo
            myDisplayName: myUser.displayName ?? '',
            myPhotoUrl: myUser.photoURL,
          );
          if (mounted) setState(() => _followState = _FollowState.following);
        } else {
          // solicitud
          await _followRepo.sendFollowRequest(
            toUid: widget.userId,
            fromUsername: '',
            fromDisplayName: myUser.displayName ?? '',
            fromPhotoUrl: myUser.photoURL,
            toUsername: entry.username,
            toDisplayName: entry.displayName,
            toPhotoUrl: entry.photoUrl,
          );
          if (mounted) setState(() => _followState = _FollowState.pending);
        }
      }
      // pending: no hay acción (el usuario no puede cancelar solicitudes desde aquí)
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

    // Si no hay datos en ninguna colección: perfil inexistente
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
              Text('Perfil no disponible',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    // Determinar si puede ver el contenido completo
    final isPrivate = _dirEntry != null
        ? !_dirEntry!.isProfilePublic
        : (_profile != null ? !_profile!.isProfilePublic : false);

    final canSeeContent = !isPrivate ||
        _isOwnProfile ||
        _followState == _FollowState.following;

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
          // header siempre visible
          SliverToBoxAdapter(
            child: _ProfileHeader(
              profile: _profile,
              dirEntry: _dirEntry,
              followState: _followState,
              followLoading: _followLoading,
              isOwnProfile: _isOwnProfile,
              onFollowTap: _handleFollowTap,
            )
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.05, end: 0, duration: 360.ms),
          ),

          if (!canSeeContent)
            // perfil privado no seguido
            SliverToBoxAdapter(
              child: _PrivateProfileMessage(
                isPrivate: isPrivate,
                isPending: _followState == _FollowState.pending,
              ).animate().fadeIn(delay: 100.ms),
            )
          else ...[
            // stats (si el usuario los tiene habilitados)
            if (_profile != null &&
                (_dirEntry?.showStats ?? true))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: _StatsBento(profile: _profile!),
                ).animate().fadeIn(delay: 80.ms, duration: 320.ms),
              ),

            // hábitos (si el usuario los tiene habilitados)
            if (_dirEntry?.showHabits ?? true)
              StreamBuilder<List<PublicHabitModel>>(
                stream: _repo.watchPublicHabits(widget.userId),
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
                  if (habits.isEmpty) {
                    return SliverToBoxAdapter(
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
                              'Sin hábitos visibles',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final byCategory = <String, List<PublicHabitModel>>{};
                  for (final h in habits) {
                    byCategory.putIfAbsent(h.category, () => []).add(h);
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            child: Row(
                              children: [
                                Text(
                                  'Hábitos activos',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
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
                          );
                        }
                        final catIndex = index - 1;
                        final category = byCategory.keys.elementAt(catIndex);
                        return _CategorySection(
                          category: category,
                          habits: byCategory[category]!,
                          animationIndex: catIndex,
                        );
                      },
                      childCount: byCategory.length + 1,
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
  final VoidCallback onFollowTap;

  const _ProfileHeader({
    required this.profile,
    required this.dirEntry,
    required this.followState,
    required this.followLoading,
    required this.isOwnProfile,
    required this.onFollowTap,
  });

  String get _displayName =>
      profile?.displayName ?? dirEntry?.displayName ?? 'Usuario';
  String get _username =>
      profile?.username ?? dirEntry?.username ?? '';
  String? get _photoUrl => profile?.photoUrl ?? dirEntry?.photoUrl;
  String get _initials =>
      profile?.avatarInitials ?? dirEntry?.avatarInitials ?? 'U';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
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

          // Botón de follow (no mostrar en perfil propio)
          if (!isOwnProfile) ...[
            const SizedBox(height: 16),
            _FollowButton(
              state: followState,
              loading: followLoading,
              onTap: onFollowTap,
            ),
          ],
        ],
      ),
    );
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

    switch (state) {
      case _FollowState.following:
        label = 'Siguiendo';
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurface;
        icon = Icons.check_rounded;
        break;
      case _FollowState.pending:
        label = 'Solicitado';
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        icon = Icons.hourglass_top_rounded;
        break;
      case _FollowState.none:
        label = 'Seguir';
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
  final bool isPrivate;
  final bool isPending;

  const _PrivateProfileMessage({
    required this.isPrivate,
    required this.isPending,
  });

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
            'Esta cuenta es privada',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Tu solicitud está pendiente de aprobación.'
                : 'Síguelo para ver sus hábitos y estadísticas.',
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
  const _StatsBento({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${profile.totalHabits}',
            label: 'Hábitos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${profile.bestStreakEver}',
            label: 'Mejor racha',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppTheme.tertiaryContainer,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: profile.averageLevel.toStringAsFixed(1),
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
              child: _PublicHabitCard(habit: h).animate().fadeIn(
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

class _PublicHabitCard extends StatelessWidget {
  final PublicHabitModel habit;
  const _PublicHabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final denom = habit.bestStreak > 0 ? habit.bestStreak : 7;
    final progress =
        (habit.currentStreak / denom).clamp(0.0, 1.0).toDouble();
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                habit.emoji != null
                    ? Text(habit.emoji!, style: const TextStyle(fontSize: 18))
                    : Icon(
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
