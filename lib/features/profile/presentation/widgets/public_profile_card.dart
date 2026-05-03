import 'package:flutter/material.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../domain/public_profile_model.dart';

/// Card de un perfil público en el feed.
/// Muestra avatar, @username, displayName, nivel y stats básicos.
class PublicProfileCard extends StatelessWidget {
  final PublicProfileModel profile;
  final VoidCallback onTap;

  const PublicProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // avatar
              AvatarCircle(
                initials: profile.avatarInitials,
                size: 52,
                backgroundColor: scheme.primaryContainer,
                textColor: scheme.onPrimaryContainer,
                photoUrl: profile.photoUrl,
              ),
              const SizedBox(width: 14),

              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // chips de stats
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _StatChip(
                          icon: Icons.checklist_rounded,
                          label: '${profile.totalHabits} hábitos',
                        ),
                        _StatChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '${profile.bestStreakEver} días',
                        ),
                        _StatChip(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Niv. ${profile.averageLevel.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
