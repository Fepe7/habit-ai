import 'package:cloud_firestore/cloud_firestore.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_log_model.dart';
import '../../habits/domain/habit_model.dart';
import '../../mood/data/mood_repository.dart';
import '../../mood/domain/mood_math.dart';

// Agrega estadisticas de habitos para el dashboard.
// Optimizado para minimizar lecturas Firestore: una sola carga de habitos,
// una query de logs por habito (ventana fija) y agregaciones count() para
// totales historicos en vez de bajar todos los logs.
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

  // carga completa del dashboard en una sola pasada:
  // 1 lectura de habitos + N logs (ventana 7 dias) + N count() agregados.
  // Todo en paralelo. Sustituye a las 4 llamadas separadas que releian habitos.
  Future<DashboardData> loadDashboard() async {
    final habits = await _getActiveHabits();
    if (habits.isEmpty) return DashboardData.empty;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final weekEnd = today.add(const Duration(days: 1));

    // logs de los ultimos 7 dias + conteo historico, en paralelo
    final logsByHabit = _fetchLogsWindow(habits, weekStart, weekEnd);
    final totalCompleted = _countCompletedAllTime(habits);
    final results = await Future.wait([logsByHabit, totalCompleted]);
    final logs = results[0] as Map<String, List<HabitLogModel>>;
    final total = results[1] as int;

    final weekly = _bucketDailyProgress(habits, logs, weekStart, 7);

    // completados hoy a partir de los logs ya cargados (sin lecturas extra)
    final todayHabits =
        habits.where((h) => h.targetDays.contains(today.weekday)).toList();
    int completedToday = 0;
    for (final h in todayHabits) {
      final hlogs = logs[h.id];
      if (hlogs != null &&
          hlogs.any((l) => l.completed && _sameDay(l.date, today))) {
        completedToday++;
      }
    }

    // mejor racha de los campos del habito, sin tocar logs
    int bestStreak = 0;
    for (final h in habits) {
      if (h.bestStreak > bestStreak) bestStreak = h.bestStreak;
      if (h.currentStreak > bestStreak) bestStreak = h.currentStreak;
    }

    final top = [...habits]
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

    return DashboardData(
      generalStats: {
        'totalActive': habits.length,
        'completedToday': completedToday,
        'todayTotal': todayHabits.length,
        'bestStreak': bestStreak,
        'totalCompletedAllTime': total,
      },
      weeklyProgress: weekly,
      categoryStats: _categoryDistribution(habits),
      topStreaks: top.where((h) => h.currentStreak > 0).take(3).toList(),
    );
  }

  // progreso de los ultimos N dias (vista detallada de 30 dias).
  // 1 query de logs por habito (ventana entera) + agrupado en memoria.
  Future<List<DailyProgress>> getExtendedProgress({int days = 30}) async {
    final habits = await _getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    final logs = await _fetchLogsWindow(habits, start, end);
    return _bucketDailyProgress(habits, logs, start, days);
  }

  // stats detallados por categoria: habitos + % completado ultimos 7 dias.
  // 1 query de logs por habito en vez de 7 queries por habito.
  Future<List<CategoryDetailStat>> getCategoryDetailStats() async {
    final habits = await _getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final weekEnd = today.add(const Duration(days: 1));

    final logs = await _fetchLogsWindow(habits, weekStart, weekEnd);

    final grouped = <String, List<HabitModel>>{};
    for (final habit in habits) {
      grouped.putIfAbsent(habit.category, () => []).add(habit);
    }

    final result = <CategoryDetailStat>[];
    for (final entry in grouped.entries) {
      int totalLogs = 0;
      int completedLogs = 0;

      for (final habit in entry.value) {
        final hlogs = logs[habit.id] ?? const [];
        // recorre los 7 dias de la ventana y cuenta los programados
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          if (!habit.targetDays.contains(day.weekday)) continue;
          totalLogs++;
          if (hlogs.any((l) => l.completed && _sameDay(l.date, day))) {
            completedLogs++;
          }
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

  // todos los habitos con rachas (sin limite) — 1 lectura de habitos
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

  // cruza registros de ánimo con logs de hábitos para detectar correlaciones
  Future<MoodCorrelationData> getMoodHabitCorrelation({int days = 7}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    final habits = await _getActiveHabits();
    // ánimo y logs de hábitos en paralelo
    final moodFuture = MoodRepository(uid: _uid).getEntriesForRange(start, end);
    final logsFuture = _fetchLogsWindow(habits, start, end);
    final moodEntries = await moodFuture;
    final logsByHabit = await logsFuture;

    // mood medio por día (índice 0 = start, ... n-1 = today)
    final moodByDay = <int, List<double>>{};
    for (final e in moodEntries) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) {
        moodByDay.putIfAbsent(idx, () => []).add(e.rating.toDouble());
      }
    }

    // días en que cada hábito se completó (índice de día)
    final habitCompletedByDay = <String, Set<int>>{};
    for (final habit in habits) {
      for (final log in logsByHabit[habit.id] ?? const <HabitLogModel>[]) {
        if (!log.completed) continue;
        final d = DateTime(log.date.year, log.date.month, log.date.day);
        final idx = d.difference(start).inDays;
        if (idx >= 0 && idx < days) {
          habitCompletedByDay.putIfAbsent(habit.id, () => {}).add(idx);
        }
      }
    }

    // agrega % hábitos completados por día
    final completionByDay = <int, double>{};
    for (int i = 0; i < days; i++) {
      if (habits.isEmpty) { completionByDay[i] = 0; continue; }
      final date = start.add(Duration(days: i));
      final scheduled = habits
          .where((h) => h.targetDays.contains(date.weekday))
          .toList();
      if (scheduled.isEmpty) { completionByDay[i] = 0; continue; }
      int done = 0;
      for (final h in scheduled) {
        if (habitCompletedByDay[h.id]?.contains(i) == true) done++;
      }
      completionByDay[i] = done / scheduled.length;
    }

    // datos del gráfico por día
    final dayPoints = List.generate(days, (i) {
      final moodList = moodByDay[i];
      final moodAvg = moodList == null
          ? null
          : moodList.reduce((a, b) => a + b) / moodList.length;
      return DayCorrelation(
        date: start.add(Duration(days: i)),
        habitCompletionPct: completionByDay[i] ?? 0,
        moodAvg: moodAvg,
      );
    });

    // correlación por hábito: días con vs sin
    final correlations = <HabitMoodCorrelation>[];
    for (final habit in habits) {
      final completedDays = habitCompletedByDay[habit.id] ?? {};
      if (completedDays.length < 2) continue; // necesita mínimo 2 días

      // días que forman parte de una racha de 5+ días consecutivos
      final streakDays = _streakDays(completedDays, days, minRun: 5);

      final moodWith = <double>[];
      final moodWithout = <double>[];
      final moodInStreak = <double>[];

      for (int i = 0; i < days; i++) {
        final moodList = moodByDay[i];
        if (moodList == null) continue;
        final avg = moodList.reduce((a, b) => a + b) / moodList.length;
        if (completedDays.contains(i)) {
          moodWith.add(avg);
          if (streakDays.contains(i)) moodInStreak.add(avg);
        } else {
          moodWithout.add(avg);
        }
      }

      if (moodWith.length < 2 || moodWithout.isEmpty) continue;

      final avgWith = moodWith.reduce((a, b) => a + b) / moodWith.length;
      final avgWithout =
          moodWithout.reduce((a, b) => a + b) / moodWithout.length;
      // solo fiable con 2+ días de ánimo dentro de la racha
      final avgInStreak = moodInStreak.length >= 2
          ? moodInStreak.reduce((a, b) => a + b) / moodInStreak.length
          : null;

      correlations.add(HabitMoodCorrelation(
        habit: habit,
        moodWithHabit: avgWith,
        moodWithoutHabit: avgWithout,
        diff: avgWith - avgWithout,
        daysCompleted: completedDays.length,
        moodInStreak: avgInStreak,
      ));
    }

    // ordena por diferencia descendente
    correlations.sort((a, b) => b.diff.compareTo(a.diff));

    // correlación con retardo: ¿completar el hábito hoy mejora el ánimo de mañana?
    final delayed = <HabitMoodCorrelation>[];
    for (final habit in habits) {
      final completedDays = habitCompletedByDay[habit.id] ?? {};
      if (completedDays.length < 2) continue;

      final nextWith = <double>[];
      final nextWithout = <double>[];
      for (int i = 0; i < days - 1; i++) {
        final nextMood = moodByDay[i + 1];
        if (nextMood == null) continue;
        final avg = nextMood.reduce((a, b) => a + b) / nextMood.length;
        if (completedDays.contains(i)) {
          nextWith.add(avg);
        } else {
          nextWithout.add(avg);
        }
      }

      if (nextWith.length < 2 || nextWithout.isEmpty) continue;

      final avgWith = nextWith.reduce((a, b) => a + b) / nextWith.length;
      final avgWithout =
          nextWithout.reduce((a, b) => a + b) / nextWithout.length;

      delayed.add(HabitMoodCorrelation(
        habit: habit,
        moodWithHabit: avgWith,
        moodWithoutHabit: avgWithout,
        diff: avgWith - avgWithout,
        daysCompleted: completedDays.length,
      ));
    }
    delayed.sort((a, b) => b.diff.compareTo(a.diff));

    return MoodCorrelationData(
      days: dayPoints,
      habitCorrelations: correlations,
      delayedCorrelations: delayed,
    );
  }

  // devuelve los índices de día que pertenecen a una racha de minRun+ días seguidos
  Set<int> _streakDays(Set<int> completed, int totalDays, {int minRun = 5}) {
    final result = <int>{};
    int run = 0;
    for (int d = 0; d < totalDays; d++) {
      if (completed.contains(d)) {
        run++;
      } else {
        if (run >= minRun) {
          for (int k = d - run; k < d; k++) {
            result.add(k);
          }
        }
        run = 0;
      }
    }
    if (run >= minRun) {
      for (int k = totalDays - run; k < totalDays; k++) {
        result.add(k);
      }
    }
    return result;
  }

  // ==================== HELPERS ====================

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

  // baja los logs de una ventana de fechas para todos los habitos en paralelo.
  // 1 query por habito (vs 7-30 antes). Mapa habitId -> logs.
  Future<Map<String, List<HabitLogModel>>> _fetchLogsWindow(
    List<HabitModel> habits,
    DateTime start,
    DateTime end,
  ) async {
    final lists = await Future.wait(habits.map(
      (h) => _habitRepo.getLogsByDateRange(
        habitId: h.id,
        startDate: start,
        endDate: end,
      ),
    ));
    return {
      for (int i = 0; i < habits.length; i++) habits[i].id: lists[i],
    };
  }

  // total historico de completados via count() agregado: 1 lectura facturada
  // por habito en vez de bajar todos los documentos de log.
  Future<int> _countCompletedAllTime(List<HabitModel> habits) async {
    final counts = await Future.wait(habits.map((h) async {
      final agg = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('habits')
          .doc(h.id)
          .collection('logs')
          .where('completed', isEqualTo: true)
          .count()
          .get();
      return agg.count ?? 0;
    }));
    return counts.fold<int>(0, (a, b) => a + b);
  }

  // construye el progreso diario a partir de logs ya cargados, sin lecturas
  List<DailyProgress> _bucketDailyProgress(
    List<HabitModel> habits,
    Map<String, List<HabitLogModel>> logsByHabit,
    DateTime startDay,
    int days,
  ) {
    final result = <DailyProgress>[];
    for (int i = 0; i < days; i++) {
      final day = startDay.add(Duration(days: i));
      final scheduled =
          habits.where((h) => h.targetDays.contains(day.weekday)).toList();

      if (scheduled.isEmpty) {
        result.add(DailyProgress(date: day, completed: 0, total: 0));
        continue;
      }

      int completed = 0;
      for (final h in scheduled) {
        final hlogs = logsByHabit[h.id];
        if (hlogs == null) continue;
        if (hlogs.any((l) => l.completed && _sameDay(l.date, day))) {
          completed++;
        }
      }

      result.add(DailyProgress(
        date: day,
        completed: completed,
        total: scheduled.length,
      ));
    }
    return result;
  }

  // distribucion de habitos por categoria (en memoria, 0 lecturas)
  List<CategoryStat> _categoryDistribution(List<HabitModel> habits) {
    final counts = <String, int>{};
    for (final habit in habits) {
      counts[habit.category] = (counts[habit.category] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => CategoryStat(category: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// paquete de datos del dashboard cargado en una sola pasada
class DashboardData {
  final Map<String, dynamic> generalStats;
  final List<DailyProgress> weeklyProgress;
  final List<CategoryStat> categoryStats;
  final List<HabitModel> topStreaks;

  const DashboardData({
    required this.generalStats,
    required this.weeklyProgress,
    required this.categoryStats,
    required this.topStreaks,
  });

  static const empty = DashboardData(
    generalStats: {
      'totalActive': 0,
      'completedToday': 0,
      'todayTotal': 0,
      'bestStreak': 0,
      'totalCompletedAllTime': 0,
    },
    weeklyProgress: [],
    categoryStats: [],
    topStreaks: [],
  );
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

// datos de correlación ánimo-hábitos para el período analizado
class MoodCorrelationData {
  final List<DayCorrelation> days;
  final List<HabitMoodCorrelation> habitCorrelations;
  // correlación con retardo: efecto del hábito de hoy sobre el ánimo de mañana
  final List<HabitMoodCorrelation> delayedCorrelations;

  const MoodCorrelationData({
    required this.days,
    required this.habitCorrelations,
    this.delayedCorrelations = const [],
  });

  List<HabitMoodCorrelation> get positiveCorrelations =>
      habitCorrelations.where((c) => c.diff > 0).toList();

  List<HabitMoodCorrelation> get negativeCorrelations =>
      habitCorrelations.where((c) => c.diff < 0).toList();

  // solo retardos positivos relevantes (mejoran el ánimo del día siguiente)
  List<HabitMoodCorrelation> get positiveDelayedCorrelations =>
      delayedCorrelations.where((c) => c.diff > 0.2).toList();

  bool get hasEnoughData =>
      days.where((d) => d.moodAvg != null).length >= 3 &&
      habitCorrelations.isNotEmpty;
}

class DayCorrelation {
  final DateTime date;
  final double habitCompletionPct; // 0.0-1.0
  final double? moodAvg; // null = sin registros

  const DayCorrelation({
    required this.date,
    required this.habitCompletionPct,
    required this.moodAvg,
  });
}

class HabitMoodCorrelation {
  final HabitModel habit;
  final double moodWithHabit;
  final double moodWithoutHabit;
  final double diff; // positivo = hábito mejora el ánimo
  final int daysCompleted;
  // ánimo medio en días completados dentro de una racha de 5+ días seguidos
  final double? moodInStreak;

  const HabitMoodCorrelation({
    required this.habit,
    required this.moodWithHabit,
    required this.moodWithoutHabit,
    required this.diff,
    required this.daysCompleted,
    this.moodInStreak,
  });

  String get diffLabel => moodDiffLabel(diff);

  // diferencia de ánimo en racha vs días sin el hábito (null si no hay racha)
  double? get streakDiff =>
      moodInStreak == null ? null : moodInStreak! - moodWithoutHabit;

  String? get streakDiffLabel {
    final d = streakDiff;
    return d == null ? null : moodDiffLabel(d);
  }

  // hay efecto racha relevante si la racha mejora el ánimo más que los días sueltos
  bool get hasStreakBoost {
    final sd = streakDiff;
    return sd != null && sd > diff + 0.1;
  }

  // confianza según cuántos días se completó el hábito en el período
  MoodConfidence get confidence => switch (moodConfidenceLevel(daysCompleted)) {
        2 => MoodConfidence.high,
        1 => MoodConfidence.medium,
        _ => MoodConfidence.low,
      };
}

// nivel de fiabilidad de una correlación según el volumen de datos
enum MoodConfidence { low, medium, high }
