import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/presentation/achievement_overlay.dart';
import '../../auth/data/user_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_log_model.dart';
import '../../habits/domain/habit_model.dart';
import '../../profile/data/public_profile_repository.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge_model.dart';
import '../domain/challenge_participant_model.dart';
import '../domain/challenge_progress_model.dart';

// Detalle del reto con grid de progreso dual
class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late final String _uid;
  late final ChallengeRepository _repo;
  late final HabitRepository _habitRepo;

  ChallengeModel? _challenge;
  // participante que soy yo (null si aún no acepté)
  ChallengeParticipantModel? _myParticipant;
  // el otro participante (quien nos retó o a quien retamos)
  ChallengeParticipantModel? _partner;
  bool _loading = true;
  bool _accepting = false;

  StreamSubscription? _challengeSub;
  StreamSubscription? _myProgressSub;
  StreamSubscription? _partnerProgressSub;

  ChallengeProgressModel? _myProgress;
  ChallengeProgressModel? _partnerProgress;

  // hábito mío vinculado al reto (para el botón de check-in)
  HabitModel? _myHabit;
  bool _completedToday = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = ChallengeRepository(uid: _uid);
    _habitRepo = HabitRepository(uid: _uid);
    _load();
  }

  Future<void> _load() async {
    final challenge = await _repo.getChallenge(widget.challengeId);
    if (challenge == null || !mounted) return;

    final participants = await _repo.getParticipants(widget.challengeId);
    final myP = participants.where((p) => p.uid == _uid).firstOrNull;
    // para pending: si soy el invitado, _partner = el creador (único en participants)
    final partnerP = participants.where((p) => p.uid != _uid).firstOrNull;

    setState(() {
      _challenge = challenge;
      _myParticipant = myP;
      _partner = partnerP;
      _loading = false;
    });

    // cargar hábito vinculado si ya acepté
    if (myP?.habitId != null) {
      await _loadMyHabit(myP!.habitId!);
    }

    // rellenar días perdidos
    if (challenge.isActive) {
      await _repo.fillMissedDays(widget.challengeId);
    }

    // auto-complete si ya pasó la fecha
    if (challenge.isActive && challenge.endDate != null) {
      final now = DateTime.now();
      if (now.isAfter(challenge.endDate!)) {
        await _repo.completeChallenge(widget.challengeId);
        await _onChallengeCompleted();
      }
    }

    // streams en tiempo real
    _challengeSub = _repo.watchChallenge(widget.challengeId).listen((c) {
      if (mounted && c != null) setState(() => _challenge = c);
    }, onError: (_) {});

    _myProgressSub =
        _repo.watchProgress(widget.challengeId, _uid).listen((p) {
      if (mounted) setState(() => _myProgress = p);
    }, onError: (_) {});

    if (partnerP != null) {
      _partnerProgressSub =
          _repo.watchProgress(widget.challengeId, partnerP.uid).listen((p) {
        if (mounted) setState(() => _partnerProgress = p);
      }, onError: (_) {});
    }
  }

  Future<void> _loadMyHabit(String habitId) async {
    final habit = await _habitRepo.getHabit(habitId);
    if (habit == null || !mounted) return;
    final log = await _habitRepo.getTodayLog(habitId);
    setState(() {
      _myHabit = habit;
      _completedToday = log?.completed ?? false;
    });
  }

  // ── ACEPTAR RETO ────────────────────────────────────────────────────────────

  Future<void> _acceptChallenge() async {
    if (_challenge == null) return;
    setState(() => _accepting = true);

    try {
      // crear hábito personal vinculado al reto
      final habitId = await _habitRepo.createHabit(
        HabitModel(
          id: '',
          title: _challenge!.habitTitle,
          description: _challenge!.habitDescription,
          category: _challenge!.habitCategory,
          frequency: 'daily',
          targetDays: [1, 2, 3, 4, 5, 6, 7],
          createdAt: DateTime.now(),
          challengeId: widget.challengeId,
        ),
      );

      final me = FirebaseAuth.instance.currentUser!;
      final profileRepo = PublicProfileRepository(uid: _uid);
      final myProfile = await profileRepo.getPublicProfile(_uid);

      final participant = ChallengeParticipantModel(
        uid: _uid,
        username: myProfile?.username ?? me.displayName ?? '',
        displayName: me.displayName ?? '',
        photoUrl: me.photoURL,
        habitId: habitId,
        joinedAt: DateTime.now(),
      );

      await _repo.acceptChallenge(
        challengeId: widget.challengeId,
        inviteeParticipant: participant,
        habitId: habitId,
      );

      if (!mounted) return;
      AppSnackBar.showSuccess(context, S.of(context).challengeDetailAccepted);
      // recargar para mostrar progreso
      await _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).challengeDetailAcceptError);
        setState(() => _accepting = false);
      }
    }
  }

  // ── RECHAZAR RETO ───────────────────────────────────────────────────────────

  Future<void> _declineChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.challengeDetailDeclineTitle),
          content: Text(s.challengeDetailDeclineContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(s.challengeDetailDeclineConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    await _repo.declineChallenge(widget.challengeId);
    if (mounted) Navigator.of(context).pop();
  }

  // ── TOGGLE CHECK-IN ─────────────────────────────────────────────────────────

  Future<void> _toggleCheckIn() async {
    if (_myHabit == null || _challenge == null) return;

    final wasCompleted = _completedToday;
    setState(() => _completedToday = !wasCompleted);

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(
            id: '', date: DateTime.now(), completed: true);
        await _habitRepo.addLog(_myHabit!.id, log);
        await _habitRepo.updateStreak(_myHabit!.id);
      } else {
        await _habitRepo.uncheckAndRecalculate(_myHabit!.id);
      }

      // sync progreso al reto
      await _repo.syncProgressFromToggle(
        challengeId: widget.challengeId,
        completed: !wasCompleted,
      );
    } catch (e) {
      if (mounted) setState(() => _completedToday = wasCompleted);
    }
  }

  // ── ABANDONAR ───────────────────────────────────────────────────────────────

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.challengeDetailAbandonTitle),
          content: Text(s.challengeDetailAbandonContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(s.challengeDetailAbandonConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    await _repo.abandonChallenge(widget.challengeId);

    if (_myParticipant?.habitId != null) {
      await _habitRepo.updateHabit(_myParticipant!.habitId!, {
        'challengeId': null,
      });
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onChallengeCompleted() async {
    final checker = AchievementChecker(
      achievementRepo: AchievementRepository(uid: _uid),
      habitRepo: _habitRepo,
      userRepo: UserRepository(uid: _uid),
      publicProfileRepo: PublicProfileRepository(uid: _uid),
    );
    final unlocked = await checker.checkAfterChallengeComplete();
    if (unlocked.isNotEmpty && mounted) {
      AchievementOverlay.showUnlocked(context, unlocked);
    }
  }

  @override
  void dispose() {
    _challengeSub?.cancel();
    _myProgressSub?.cancel();
    _partnerProgressSub?.cancel();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_challenge == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(S.of(context).challengeDetailNotFound)),
      );
    }

    final challenge = _challenge!;
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final catBg = AppTheme.categoryBg(challenge.habitCategory, scheme.brightness);
    final catFg = AppTheme.categoryFg(challenge.habitCategory, scheme.brightness);
    final amInvited = challenge.invitedUid == _uid;
    final isPending = challenge.isPending;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.challengeDetailTitle),
        actions: [
          if (challenge.isActive)
            IconButton(
              icon: const Icon(Icons.flag_rounded),
              tooltip: s.challengeDetailAbandonTooltip,
              onPressed: _abandon,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── quién retó a quién ──
          if (_partner != null) _buildChallengerBanner(challenge, scheme),
          const SizedBox(height: 16),

          // ── categoría + duración ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppTheme.categoryIcon(challenge.habitCategory),
                        size: 14, color: catFg),
                    const SizedBox(width: 4),
                    Text(
                      AppTheme.categoryLabel(challenge.habitCategory),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: catFg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.daysLabel(challenge.durationDays),
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── título del hábito ──
          Text(
            challenge.habitTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (challenge.habitDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.habitDescription,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 24),

          // ── bloque PENDIENTE (soy el invitado) ──
          if (isPending && amInvited)
            _buildAcceptDeclinePanel(scheme)
          else ...[
            // ── botón de check-in diario ──
            if (challenge.isActive && _myHabit != null)
              _buildCheckInButton(scheme),

            // ── mi progreso ──
            _ProgressSection(
              label: s.challengeDetailYourProgress,
              progress: _myProgress,
              durationDays: challenge.durationDays,
              color: const Color(0xFF38BDF8),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // ── progreso del compañero ──
            if (_partner != null) ...[
              Row(
                children: [
                  AvatarCircle(
                    initials: _initials(_partner!.displayName),
                    photoUrl: _partner!.photoUrl,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '@${_partner!.username}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ProgressSection(
                label: s.challengeDetailPartner,
                progress: _partnerProgress,
                durationDays: challenge.durationDays,
                color: const Color(0xFF8B5CF6),
                showLabel: false,
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],

          // ── estado final ──
          if (challenge.status == ChallengeStatus.completed) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFF59E0B), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.challengeDetailCompletedTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          s.challengeDetailCompletedSubtitle,
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.9, 0.9),
                  curve: Curves.elasticOut,
                  duration: 600.ms,
                ),
          ],

          if (challenge.status == ChallengeStatus.abandoned ||
              challenge.status == ChallengeStatus.declined) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Text(
                    challenge.status == ChallengeStatus.declined
                        ? s.challengeDetailDeclinedState
                        : s.challengeDetailAbandonedState,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          // ── pendiente esperando al compañero ──
          if (isPending && !amInvited) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.challengeDetailWaitingPartner(_partner?.displayName ?? s.challengeDetailFallbackPartner),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // banner que muestra quién reta a quién
  Widget _buildChallengerBanner(ChallengeModel challenge, ColorScheme scheme) {
    final s = S.of(context);
    final amCreator = challenge.creatorUid == _uid;
    final otherName = _partner?.displayName ?? _partner?.username ?? s.challengeDetailFallbackPartnerCap;
    final label = amCreator
        ? s.challengeDetailYouChallenged(otherName)
        : s.challengeDetailChallengedYou(_partner?.displayName ?? s.challengeDetailFallbackSomeone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AvatarCircle(
            initials: _initials(_partner?.displayName ?? '?'),
            photoUrl: _partner?.photoUrl,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_partner?.username != null)
                  Text(
                    '@${_partner!.username}',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const Icon(Icons.handshake_rounded,
              color: Color(0xFF6366F1), size: 20),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }

  // panel de aceptar / rechazar (solo visible para el invitado en pending)
  Widget _buildAcceptDeclinePanel(ColorScheme scheme) {
    final s = S.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.handshake_rounded,
                  size: 40, color: Color(0xFF6366F1)),
              const SizedBox(height: 8),
              Text(
                s.challengeDetailAcceptQuestion,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                s.challengeDetailAcceptHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _accepting ? null : _declineChallenge,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(s.challengeDetailDeclineConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GradientButton(
                onPressed: _accepting ? null : _acceptChallenge,
                label: s.challengeDetailAcceptCta,
                loading: _accepting,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  // botón de check-in del día
  Widget _buildCheckInButton(ColorScheme scheme) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: _toggleCheckIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: _completedToday
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _completedToday
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _completedToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(_completedToday),
                  color: _completedToday
                      ? const Color(0xFF10B981)
                      : scheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _completedToday
                    ? s.challengeDetailCompletedToday
                    : s.challengeDetailMarkToday,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _completedToday
                      ? const Color(0xFF10B981)
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 80.ms);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── SECCIONES DE PROGRESO ────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final String label;
  final ChallengeProgressModel? progress;
  final int durationDays;
  final Color color;
  final bool showLabel;

  const _ProgressSection({
    required this.label,
    required this.progress,
    required this.durationDays,
    required this.color,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = progress?.completedCount ?? 0;
    final ratio = durationDays > 0 ? completed / durationDays : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  S.of(context).challengeDetailProgressDays(completed, durationDays),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 12),
        _DaysGrid(
          days: progress?.days ?? {},
          durationDays: durationDays,
          color: color,
        ),
      ],
    );
  }
}

class _DaysGrid extends StatelessWidget {
  final Map<int, DayStatus> days;
  final int durationDays;
  final Color color;

  const _DaysGrid({
    required this.days,
    required this.durationDays,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(durationDays, (i) {
        final status = days[i] ?? DayStatus.pending;
        final (bg, icon, iconColor) = switch (status) {
          DayStatus.completed => (
              color.withValues(alpha: 0.2),
              Icons.check_rounded,
              color,
            ),
          DayStatus.missed => (
              const Color(0xFFEF4444).withValues(alpha: 0.15),
              Icons.close_rounded,
              const Color(0xFFEF4444),
            ),
          DayStatus.shielded => (
              const Color(0xFFF59E0B).withValues(alpha: 0.15),
              Icons.shield_rounded,
              const Color(0xFFF59E0B),
            ),
          DayStatus.pending => (
              scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              null as IconData?,
              null as Color?,
            ),
        };

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 16, color: iconColor)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
