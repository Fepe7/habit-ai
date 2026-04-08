import 'package:cloud_firestore/cloud_firestore.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';

// Agrega estadisticas de habitos para el dashboard
class StatsRepository {
  final HabitRepository _habitRepo;
  final String _uid;
  final FirebaseFirestore _firestore;

  StatsRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _habitRepo = HabitRepository(uid: uid, firestore: firestore);

  // stats generales: completados hoy, total activos, mejor racha global
  Future<Map<String, dynamic>> getGeneralStats() async {
    final habits = await _getActiveHabits();
    if (habits.isEmpty) {
      return {
        'totalActive': 0,
        'completedToday': 0,
        'bestStreak': 0,
        'totalCompletedAllTime': 0,
      };
    }

    // cuantos completados hoy
    int completedToday = 0;
    final todayHabits = _filterTodayHabits(habits);
    for (final habit in todayHabits) {
      final log = await _habitRepo.getTodayLog(habit.id);
      if (log?.completed == true) completedToday++;
    }

    // mejor racha de todos los habitos
    int bestStreak = 0;
    for (final habit in habits) {
      if (habit.bestStreak > bestStreak) bestStreak = habit.bestStreak;
      if (habit.currentStreak > bestStreak) bestStreak = habit.currentStreak;
    }

    // total completados historico (cuenta todos los logs completed)
    int totalCompleted = 0;
    for (final habit in habits) {
      final logs = await _habitRepo.getLogsByDateRange(
        habitId: habit.id,
        startDate: habit.createdAt,
        endDate: DateTime.now(),
      );
      totalCompleted += logs.where((l) => l.completed).length;
    }

    return {
      'totalActive': habits.length,
      'completedToday': completedToday,
      'todayTotal': todayHabits.length,
      'bestStreak': bestStreak,
      'totalCompletedAllTime': totalCompleted,
    };
  }

  // % de completados por cada dia de los ultimos 7 dias
  Future<List<DailyProgress>> getWeeklyProgress() async {
    final habits = await _getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DailyProgress>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final weekday = day.weekday;

      // solo habitos que tocan ese dia
      final scheduled = habits.where(
        (h) => h.targetDays.contains(weekday),
      ).toList();

      if (scheduled.isEmpty) {
        result.add(DailyProgress(date: day, completed: 0, total: 0));
        continue;
      }

      int completed = 0;
      for (final habit in scheduled) {
        final logs = await _habitRepo.getLogsByDateRange(
          habitId: habit.id,
          startDate: day,
          endDate: dayEnd,
        );
        if (logs.any((l) => l.completed)) completed++;
      }

      result.add(DailyProgress(
        date: day,
        completed: completed,
        total: scheduled.length,
      ));
    }

    return result;
  }

  // distribucion de habitos por categoria
  Future<List<CategoryStat>> getCategoryDistribution() async {
    final habits = await _getActiveHabits();
    final counts = <String, int>{};

    for (final habit in habits) {
      counts[habit.category] = (counts[habit.category] ?? 0) + 1;
    }

    return counts.entries
        .map((e) => CategoryStat(category: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  // top habitos por racha actual
  Future<List<HabitModel>> getTopStreaks({int limit = 3}) async {
    final habits = await _getActiveHabits();
    habits.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return habits.where((h) => h.currentStreak > 0).take(limit).toList();
  }

  // progreso de los ultimos N dias (para la vista detallada)
  Future<List<DailyProgress>> getExtendedProgress({int days = 30}) async {
    final habits = await _getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DailyProgress>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final weekday = day.weekday;

      final scheduled = habits.where(
        (h) => h.targetDays.contains(weekday),
      ).toList();

      if (scheduled.isEmpty) {
        result.add(DailyProgress(date: day, completed: 0, total: 0));
        continue;
      }

      int completed = 0;
      for (final habit in scheduled) {
        final logs = await _habitRepo.getLogsByDateRange(
          habitId: habit.id,
          startDate: day,
          endDate: dayEnd,
        );
        if (logs.any((l) => l.completed)) completed++;
      }

      result.add(DailyProgress(
        date: day,
        completed: completed,
        total: scheduled.length,
      ));
    }

    return result;
  }

  // stats detallados por categoria: habitos + % completado ultimos 7 dias
  Future<List<CategoryDetailStat>> getCategoryDetailStats() async {
    final habits = await _getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final grouped = <String, List<HabitModel>>{};
    for (final habit in habits) {
      grouped.putIfAbsent(habit.category, () => []).add(habit);
    }

    final result = <CategoryDetailStat>[];
    for (final entry in grouped.entries) {
      int totalLogs = 0;
      int completedLogs = 0;

      for (final habit in entry.value) {
        // contar dias programados en la ultima semana
        for (int i = 0; i < 7; i++) {
          final day = weekAgo.add(Duration(days: i));
          if (!habit.targetDays.contains(day.weekday)) continue;
          totalLogs++;
          final logs = await _habitRepo.getLogsByDateRange(
            habitId: habit.id,
            startDate: day,
            endDate: day.add(const Duration(days: 1)),
          );
          if (logs.any((l) => l.completed)) completedLogs++;
        }
      }

      result.add(CategoryDetailStat(
        category: entry.key,
        habits: entry.value,
        completionRate: totalLogs == 0 ? 0 : completedLogs / totalLogs,
        totalCompleted: completedLogs,
        totalScheduled: totalLogs,
      ));
    }

    result.sort((a, b) => b.habits.length.compareTo(a.habits.length));
    return result;
  }

  // todos los habitos con rachas (sin limite)
  Future<List<HabitModel>> getAllHabitsWithStreaks() async {
    final habits = await _getActiveHabits();
    habits.sort((a, b) {
      // primero por racha actual, luego por mejor racha
      final cmp = b.currentStreak.compareTo(a.currentStreak);
      if (cmp != 0) return cmp;
      return b.bestStreak.compareTo(a.bestStreak);
    });
    return habits;
  }

  // helpers
  Future<List<HabitModel>> _getActiveHabits() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  List<HabitModel> _filterTodayHabits(List<HabitModel> habits) {
    final weekday = DateTime.now().weekday;
    return habits.where((h) => h.targetDays.contains(weekday)).toList();
  }
}

// progreso de un dia
class DailyProgress {
  final DateTime date;
  final int completed;
  final int total;

  const DailyProgress({
    required this.date,
    required this.completed,
    required this.total,
  });

  double get percentage => total == 0 ? 0 : completed / total;
}

// habitos por categoria
class CategoryStat {
  final String category;
  final int count;

  const CategoryStat({required this.category, required this.count});
}

// stats detallados por categoria
class CategoryDetailStat {
  final String category;
  final List<HabitModel> habits;
  final double completionRate;
  final int totalCompleted;
  final int totalScheduled;

  const CategoryDetailStat({
    required this.category,
    required this.habits,
    required this.completionRate,
    required this.totalCompleted,
    required this.totalScheduled,
  });
}
