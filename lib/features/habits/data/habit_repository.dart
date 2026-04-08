import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';

// CRUD de habitos y logs en Firestore
class HabitRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HabitRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Ref a la coleccion de habitos del usuario
  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _firestore.collection('users').doc(_uid).collection('habits');

  // Ref a los logs de un habito
  CollectionReference<Map<String, dynamic>> _logsRef(String habitId) =>
      _habitsRef.doc(habitId).collection('logs');

  // ==================== CRUD DE HÁBITOS ====================

  // Habitos activos en tiempo real
  Stream<List<HabitModel>> watchActiveHabits() {
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // Solo los habitos que tocan hoy
  Stream<List<HabitModel>> watchTodayHabits() {
    // arrayContains filtra en el servidor, asi no baja todo
    final today = DateTime.now().weekday; // 1=Lunes, 7=Domingo
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .where('targetDays', arrayContains: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // Obtener un habito por id
  Future<HabitModel?> getHabit(String habitId) async {
    final doc = await _habitsRef.doc(habitId).get();
    if (!doc.exists) return null;
    return HabitModel.fromJson(doc.data()!, doc.id);
  }

  // Crear habito nuevo
  Future<String> createHabit(HabitModel habit) async {
    final docRef = await _habitsRef.add(habit.toJson());
    return docRef.id;
  }

  // Crear varios habitos a la vez (para cuando la IA genera un plan)
  Future<void> createHabits(List<HabitModel> habits) async {
    // batch manda todo en una sola peticion
    final batch = _firestore.batch();
    for (final habit in habits) {
      final docRef = _habitsRef.doc();
      batch.set(docRef, habit.toJson());
    }
    await batch.commit();
  }

  // Actualizar habito
  Future<void> updateHabit(String habitId, Map<String, dynamic> data) async {
    await _habitsRef.doc(habitId).update(data);
  }

  // No borramos, solo desactivamos para no perder los logs
  Future<void> deactivateHabit(String habitId) async {
    await _habitsRef.doc(habitId).update({'isActive': false});
  }

  // ==================== LOGS DIARIOS ====================

  // Guardar log de un dia
  Future<String> addLog(String habitId, HabitLogModel log) async {
    final docRef = await _logsRef(habitId).add(log.toJson());
    return docRef.id;
  }

  // Log de hoy (null si no hay)
  Future<HabitLogModel?> getTodayLog(String habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _logsRef(habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return HabitLogModel.fromJson(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  // Logs entre dos fechas (para estadisticas)
  Future<List<HabitLogModel>> getLogsByDateRange({
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Filtra en el servidor para no bajar todos los logs
    final snapshot = await _logsRef(habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => HabitLogModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Borrar el log de hoy (para cuando se desmarca un habito)
  Future<void> deleteTodayLog(String habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _logsRef(habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==================== RACHAS ====================

  // Calcular racha real contando dias consecutivos hacia atras
  Future<int> _calculateStreak(String habitId) async {
    // traer los logs completados ordenados de mas reciente a mas antiguo
    final snapshot = await _logsRef(habitId)
        .where('completed', isEqualTo: true)
        .orderBy('date', descending: true)
        .limit(365)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // convertir a set de fechas (solo dia, sin hora)
    final completedDays = <DateTime>{};
    for (final doc in snapshot.docs) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      completedDays.add(DateTime(date.year, date.month, date.day));
    }

    // contar dias consecutivos desde hoy hacia atras
    final today = DateTime.now();
    var current = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // si hoy no esta completado, empezar desde ayer
    if (!completedDays.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    while (completedDays.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Recalcular racha tras completar un habito
  Future<void> updateStreak(String habitId) async {
    final habit = await getHabit(habitId);
    if (habit == null) return;

    final newStreak = await _calculateStreak(habitId);
    final newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    await updateHabit(habitId, {
      'currentStreak': newStreak,
      'bestStreak': newBest,
    });
  }

  // Recalcular racha tras desmarcar (borra log + recalcula)
  Future<void> uncheckAndRecalculate(String habitId) async {
    await deleteTodayLog(habitId);

    final habit = await getHabit(habitId);
    if (habit == null) return;

    final newStreak = await _calculateStreak(habitId);

    await updateHabit(habitId, {
      'currentStreak': newStreak,
    });
  }
}