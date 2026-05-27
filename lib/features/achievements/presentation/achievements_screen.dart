import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../data/archivement_repository.dart';
import '../domain/achivement_model.dart';
import '../../../l10n/app_localizations.dart';

// Pantalla con todos los logros (desbloqueados y bloqueados)
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late AchievementRepository _achievementRepo;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _achievementRepo = AchievementRepository(uid: user.uid);
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)!.achievementsTitle)),
      body: StreamBuilder<List<AchievementModel>>(
        stream: _achievementRepo.watchAchievements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SectionSkeleton(itemCount: 5),
            );
          }

          final unlocked = snapshot.data ?? [];
          final unlockedTypes = unlocked.map((a) => a.type).toSet();
          final catalog = AchievementCatalog.all;
          final unlockedCount = unlockedTypes.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // resumen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.streakGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.ambientShadow(opacity: 0.14),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$unlockedCount / ${catalog.length}',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context)!.achievementsUnlocked(unlockedCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                      const SizedBox(height: 12),
                      // barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: catalog.isEmpty
                              ? 0
                              : unlockedCount / catalog.length,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),

                const SizedBox(height: 24),

                // grid de logros
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: catalog.length,
                  itemBuilder: (context, index) {
                    final info = catalog[index];
                    final isUnlocked = unlockedTypes.contains(info.type);
                    final achievement = isUnlocked
                        ? unlocked.firstWhere((a) => a.type == info.type)
                        : null;

                    return _AchievementTile(
                      info: info,
                      isUnlocked: isUnlocked,
                      unlockedAt: achievement?.unlockedAt,
                    )
                        .animate()
                        .fadeIn(
                          delay: (100 + index * 60).ms,
                          duration: 400.ms,
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          delay: (100 + index * 60).ms,
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementInfo info;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.info,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? info.color.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: isUnlocked
            ? Border.all(color: info.color.withValues(alpha: 0.25), width: 1)
            : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // icono
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? info.color.withValues(alpha: 0.15)
                  : colorScheme.outlineVariant.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isUnlocked ? info.icon : Icons.lock_rounded,
              color: isUnlocked
                  ? info.color
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),

          // titulo
          Text(
            info.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isUnlocked
                      ? null
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // descripcion
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // fecha
          if (isUnlocked && unlockedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${unlockedAt!.day}/${unlockedAt!.month}/${unlockedAt!.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: info.color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
