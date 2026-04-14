import '../../achievements/data/archivement_repository.dart';
import '../../achievements/domain/achivement_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../domain/level_model.dart';

// Calcula el perfil de maestría por categoría en tiempo real
// No persiste nada: XP se deriva de logs y logros existentes
class LevelsRepository {
  final HabitRepository _habitRepo;
  final AchievementRepository _achievementRepo;

  LevelsRepository({
    required String uid,
  })  : _habitRepo = HabitRepository(uid: uid),
        _achievementRepo = AchievementRepository(uid: uid);

  /// Calcula el perfil completo de niveles por categoría
  Future<LevelsProfile> computeProfile() async {
    // Obtener hábitos activos y logros desbloqueados en paralelo
    final results = await Future.wait([
      _habitRepo.watchActiveHabits().first,
      _achievementRepo.watchAchievements().first,
    ]);

    final habits = results[0] as List<HabitModel>;
    final achievements = results[1] as List<AchievementModel>;

    if (habits.isEmpty) {
      return LevelsProfile(categories: {});
    }

    // Acumular XP por categoría
    final xpByCategory = <String, int>{};

    for (final habit in habits) {
      final category = habit.category;

      // 10 XP base por cada log completado histórico
      final logs = await _habitRepo.getLogsByDateRange(
        habitId: habit.id,
        startDate: habit.createdAt,
        endDate: DateTime.now(),
      );
      final completedCount = logs.where((l) => l.completed).length;
      xpByCategory[category] = (xpByCategory[category] ?? 0) + completedCount * 10;

      // +5 XP bonus por cada día de racha actual (máx 50)
      final streakBonus = (habit.currentStreak * 5).clamp(0, 50);
      xpByCategory[category] = xpByCategory[category]! + streakBonus;
    }

    // +50 XP bonus por cada logro asociado a un hábito de esa categoría
    final habitMap = {for (final h in habits) h.id: h};
    for (final achievement in achievements) {
      if (achievement.habitId != null) {
        // logro vinculado a un hábito concreto: bonus a su categoría
        final habit = habitMap[achievement.habitId!];
        if (habit != null) {
          xpByCategory[habit.category] = (xpByCategory[habit.category] ?? 0) + 50;
        }
      } else {
        // logro genérico: repartir entre todas las categorías con hábitos
        final activeCategories = xpByCategory.keys.toList();
        if (activeCategories.isNotEmpty) {
          final bonus = (50 / activeCategories.length).round();
          for (final cat in activeCategories) {
            xpByCategory[cat] = xpByCategory[cat]! + bonus;
          }
        }
      }
    }

    // Construir CategoryLevel para cada categoría con XP
    final levelsByCategory = <String, CategoryLevel>{};
    for (final entry in xpByCategory.entries) {
      levelsByCategory[entry.key] = CategoryLevel.fromXp(entry.key, entry.value);
    }

    return LevelsProfile(categories: levelsByCategory);
  }
}
