import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/level_model.dart';
import '../category_l10n.dart';

/// Card de nivel de maestría para una categoría, reutilizable en
/// LevelsScreen y ProfileScreen.
class CategoryLevelCard extends StatelessWidget {
  final CategoryLevel level;
  final VoidCallback onTap;

  const CategoryLevelCard({
    super.key,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgColor = AppTheme.categoryFg(level.category);
    final bgColor = AppTheme.categoryBg(level.category);
    final l10n = S.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.12)),
          boxShadow: AppTheme.ambientShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(AppTheme.categoryIcon(level.category), color: fgColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CategoryL10n.label(level.category, l10n),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: fgColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.levelNvl(level.level),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: fgColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CategoryL10n.levelTitle(level.category, level.level, l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: level.progressToNext,
                            minHeight: 5,
                            backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(fgColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level.level < 5 ? '${level.xpToNext} XP' : l10n.levelMaxShort,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet con detalle de nivel para una categoría.
class CategoryDetailSheet extends StatelessWidget {
  final CategoryLevel level;

  const CategoryDetailSheet({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgColor = AppTheme.categoryFg(level.category);
    final bgColor = AppTheme.categoryBg(level.category);
    final l10n = S.of(context);
    final titleCurrent = CategoryL10n.levelTitle(level.category, level.level, l10n);
    final titleNext = level.level < 5
        ? CategoryL10n.levelTitle(level.category, level.level + 1, l10n)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(AppTheme.categoryIcon(level.category), color: fgColor, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CategoryL10n.label(level.category, l10n),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    titleCurrent,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text(
                    l10n.levelNvlShort,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '${level.level}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: fgColor,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.levelXpAccum,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                '${level.xp} XP',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (level.level < 5) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titleCurrent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  titleNext ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: level.progressToNext,
                minHeight: 10,
                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(fgColor),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.levelXpToNext(level.xpToNext, titleNext ?? ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: fgColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.levelMaxReached,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.levelHowToEarnXp,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _XpTip(
            icon: Icons.check_circle_outline_rounded,
            text: l10n.levelXpTipCheckin,
            color: fgColor,
          ),
          const SizedBox(height: 6),
          _XpTip(
            icon: Icons.local_fire_department_rounded,
            text: l10n.levelXpTipStreak,
            color: fgColor,
          ),
          const SizedBox(height: 6),
          _XpTip(
            icon: Icons.emoji_events_rounded,
            text: l10n.levelXpTipAchievement,
            color: fgColor,
          ),
        ],
      ),
    );
  }
}

class _XpTip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _XpTip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
