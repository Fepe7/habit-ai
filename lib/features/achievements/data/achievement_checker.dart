import '../../auth/data/user_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../domain/achivement_model.dart';
import 'archivement_repository.dart';

// Comprueba condiciones y desbloquea logros tras cada accion
class AchievementChecker {
  final AchievementRepository _achievementRepo;
  final HabitRepository _habitRepo;
  final UserRepository _userRepo;

  AchievementChecker({
    required AchievementRepository achievementRepo,
    required HabitRepository habitRepo,
    required UserRepository userRepo,
  })  : _achievementRepo = achievementRepo,
        _habitRepo = habitRepo,
        _userRepo = userRepo;

  // comprobar todo tras completar un habito
  Future<List<String>> checkAfterToggle({
    required HabitModel habit,
    required List<HabitModel> todayHabits,
    required Map<String, bool> completedToday,
  }) async {
    final unlocked = <String>[];

    // racha de 3
    if (habit.currentStreak >= 3) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.streak3,
        habitId: habit.id,
      )) {
        unlocked.add(AchievementModel.streak3);
      }
    }

    // racha de 7
    if (habit.currentStreak >= 7) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.streak7,
        habitId: habit.id,
      )) {
        unlocked.add(AchievementModel.streak7);
      }
    }

    // racha de 14
    if (habit.currentStreak >= 14) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.streak14,
        habitId: habit.id,
      )) {
        unlocked.add(AchievementModel.streak14);
      }
    }

    // racha de 30
    if (habit.currentStreak >= 30) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.streak30,
        habitId: habit.id,
      )) {
        unlocked.add(AchievementModel.streak30);
      }
    }

    // conceder escudos por hitos de racha (con deduplicacion)
    await _grantShieldsForStreak(habit);

    // dia perfecto: todos los de hoy completados
    final allDone = todayHabits.every(
      (h) => completedToday[h.id] == true,
    );
    if (allDone && todayHabits.isNotEmpty) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.allCompleted,
      )) {
        unlocked.add(AchievementModel.allCompleted);
      }
    }

    // check-ins totales (50 y 100)
    await _checkTotalCompletions(unlocked);

    // semana impecable: comprobar si los ultimos 7 dias fueron perfectos
    await _checkPerfectWeek(unlocked);

    return unlocked;
  }

  // comprobar tras crear un habito
  Future<List<String>> checkAfterCreate() async {
    final unlocked = <String>[];

    // primer habito
    if (await _achievementRepo.unlockAchievement(
      type: AchievementModel.firstHabit,
    )) {
      unlocked.add(AchievementModel.firstHabit);
    }

    // 5 habitos activos
    await _checkHabitCount(unlocked);

    return unlocked;
  }

  // comprobar tras generar plan con IA
  Future<List<String>> checkAfterAIPlan() async {
    final unlocked = <String>[];

    if (await _achievementRepo.unlockAchievement(
      type: AchievementModel.aiPlan,
    )) {
      unlocked.add(AchievementModel.aiPlan);
    }

    // tambien comprobar primer habito y cantidad
    if (await _achievementRepo.unlockAchievement(
      type: AchievementModel.firstHabit,
    )) {
      unlocked.add(AchievementModel.firstHabit);
    }

    await _checkHabitCount(unlocked);

    return unlocked;
  }

  // comprobar si tiene 5+ habitos activos
  Future<void> _checkHabitCount(List<String> unlocked) async {
    // escuchar una vez para contar
    final habits = await _habitRepo.watchActiveHabits().first;
    if (habits.length >= 5) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.habits5,
      )) {
        unlocked.add(AchievementModel.habits5);
      }
    }
  }

  // comprobar check-ins totales
  Future<void> _checkTotalCompletions(List<String> unlocked) async {
    final habits = await _habitRepo.watchActiveHabits().first;
    int total = 0;

    for (final habit in habits) {
      final logs = await _habitRepo.getLogsByDateRange(
        habitId: habit.id,
        startDate: habit.createdAt,
        endDate: DateTime.now(),
      );
      total += logs.where((l) => l.completed).length;
    }

    if (total >= 50) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.total50,
      )) {
        unlocked.add(AchievementModel.total50);
      }
    }

    if (total >= 100) {
      if (await _achievementRepo.unlockAchievement(
        type: AchievementModel.total100,
      )) {
        unlocked.add(AchievementModel.total100);
      }
    }
  }

  // conceder escudos al alcanzar hitos de racha (7→1, 30→2, 90→3)
  // usa shield_grants para no repetir la concesion
  Future<void> _grantShieldsForStreak(HabitModel habit) async {
    final milestones = <int, int>{7: 1, 30: 2, 90: 3};
    for (final entry in milestones.entries) {
      final milestone = entry.key;
      final shields = entry.value;
      if (habit.currentStreak >= milestone) {
        final alreadyGranted =
            await _userRepo.hasShieldGrant(habit.id, milestone);
        if (!alreadyGranted) {
          await _userRepo.grantShields(shields);
          await _userRepo.recordShieldGrant(habit.id, milestone);
        }
      }
    }
  }

  // comprobar tras completar un reto compartido
  Future<List<String>> checkAfterChallengeComplete() async {
    final unlocked = <String>[];

    if (await _achievementRepo.unlockAchievement(
      type: AchievementModel.challengeCompleted,
    )) {
      unlocked.add(AchievementModel.challengeCompleted);
    }

    // recompensa: 1 escudo de racha
    await _userRepo.grantShields(1);

    return unlocked;
  }

  // comprobar si los ultimos 7 dias fueron todos perfectos
  Future<void> _checkPerfectWeek(List<String> unlocked) async {
    final habits = await _habitRepo.watchActiveHabits().first;
    if (habits.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final weekday = day.weekday;

      final scheduled = habits.where(
        (h) => h.targetDays.contains(weekday),
      ).toList();

      // si no habia habitos ese dia, no cuenta como perfecto
      if (scheduled.isEmpty) return;

      for (final habit in scheduled) {
        final logs = await _habitRepo.getLogsByDateRange(
          habitId: habit.id,
          startDate: day,
          endDate: dayEnd,
        );
        if (!logs.any((l) => l.completed)) return;
      }
    }

    // si llego aqui, todos los dias fueron perfectos
    if (await _achievementRepo.unlockAchievement(
      type: AchievementModel.perfectWeek,
    )) {
      unlocked.add(AchievementModel.perfectWeek);
    }
  }
}
