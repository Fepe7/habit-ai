import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/challenge_model.dart';
import '../../domain/challenge_participant_model.dart';

// Card de reto para la lista
class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final ChallengeParticipantModel? partner;
  final String myUid;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.partner,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catBg = AppTheme.categoryBg(challenge.habitCategory);
    final catFg = AppTheme.categoryFg(challenge.habitCategory);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // cabecera: categoría + status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppTheme.categoryIcon(challenge.habitCategory),
                        size: 14,
                        color: catFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppTheme.categoryLabel(challenge.habitCategory),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: catFg,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _StatusChip(status: challenge.status),
              ],
            ),
            const SizedBox(height: 12),

            // título del hábito
            Text(
              challenge.habitTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // partner + duración
            Row(
              children: [
                if (partner != null) ...[
                  AvatarCircle(
                    photoUrl: partner!.photoUrl,
                    initials: _initials(partner!.displayName),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '@${partner!.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      S.of(context).challengeCardWaiting,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  S.of(context).daysLabel(challenge.durationDays),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class _StatusChip extends StatelessWidget {
  final ChallengeStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (label, color) = switch (status) {
      ChallengeStatus.pending => (s.challengeStatusPending, const Color(0xFFF59E0B)),
      ChallengeStatus.active => (s.challengeStatusActive, const Color(0xFF10B981)),
      ChallengeStatus.completed => (s.challengeStatusCompleted, const Color(0xFF38BDF8)),
      ChallengeStatus.declined => (s.challengeStatusDeclined, const Color(0xFF64748B)),
      ChallengeStatus.abandoned => (s.challengeStatusAbandoned, const Color(0xFFEF4444)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
