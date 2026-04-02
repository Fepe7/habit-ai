import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';

/// Repositorio que encapsula todas las operaciones de hábitos en Firestore.
/// La UI nunca accede a Firestore directamente, solo a través de este repositorio.
class HabitRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HabitRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la colección de hábitos del usuario actual
  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _firestore.collection('users').doc(_uid).collection('habits');

  /// Referencia a los logs de un hábito específico
  CollectionReference<Map<String, dynamic>> _logsRef(String habitId) =>
      _habitsRef.doc(habitId).collection('logs');

  // ==================== CRUD DE HÁBITOS ====================

  /// Stream reactivo de hábitos activos, ordenados por fecha de creación.
  /// StreamBuilder se suscribe a esto para actualizar la UI automáticamente.
  Stream<List<HabitModel>> watchActiveHabits() {
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Stream de hábitos que tocan hoy según sus targetDays.
  /// Filtra en Firestore para traer solo los relevantes.
  Stream<List<HabitModel>> watchTodayHabits() {
    // EFICIENCIA: arrayContains filtra en el servidor,
    // solo descarga los hábitos que tocan hoy
    final today = DateTime.now().weekday; // 1=Lunes, 7=Domingo
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .where('targetDays', arrayContains: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Obtener un hábito por su ID
  Future<HabitModel?> getHabit(String habitId) async {
    final doc = await _habitsRef.doc(habitId).get();
    if (!doc.exists) return null;
    return HabitModel.fromJson(doc.data()!, doc.id);
  }

  /// Crear un nuevo hábito y devolver su ID generado por Firestore
  Future<String> createHabit(HabitModel habit) async {
    final docRef = await _habitsRef.add(habit.toJson());
    return docRef.id;
  }

  /// Crear múltiples hábitos de golpe (usado al aceptar un plan de IA).
  /// Usa batch para enviar todas las escrituras en una sola operación.
  Future<void> createHabits(List<HabitModel> habits) async {
    // EFICIENCIA: WriteBatch agrupa escrituras en una sola petición de red
    final batch = _firestore.batch();
    for (final habit in habits) {
      final docRef = _habitsRef.doc();
      batch.set(docRef, habit.toJson());
    }
    await batch.commit();
  }

  /// Actualizar campos específicos de un hábito
  Future<void> updateHabit(String habitId, Map<String, dynamic> data) async {
    await _habitsRef.doc(habitId).update(data);
  }

  /// Soft delete: marcar como inactivo en vez de borrar.
  /// Conserva el historial de logs y estadísticas.
  Future<void> deactivateHabit(String habitId) async {
    await _habitsRef.doc(habitId).update({'isActive': false});
  }

  // ==================== LOGS DIARIOS ====================

  /// Registrar que un hábito se completó o no en una fecha
  Future<String> addLog(String habitId, HabitLogModel log) async {
    final docRef = await _logsRef(habitId).add(log.toJson());
    return docRef.id;
  }

  /// Obtener el log de hoy para un hábito específico.
  /// Devuelve null si no se ha registrado hoy.
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

  /// Obtener logs de un hábito en un rango de fechas.
  /// Usado para calcular rachas y estadísticas del dashboard.
  Future<List<HabitLogModel>> getLogsByDateRange({
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // EFICIENCIA: filtramos por rango en el servidor,
    // solo descargamos los logs del periodo solicitado
    final snapshot = await _logsRef(habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => HabitLogModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // ==================== RACHAS ====================

  /// Actualiza la racha del hábito después de completar un log.
  /// Incrementa currentStreak y actualiza bestStreak si se supera el récord.
  Future<void> updateStreak(String habitId) async {
    final habit = await getHabit(habitId);
    if (habit == null) return;

    final newStreak = habit.currentStreak + 1;
    final newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    await updateHabit(habitId, {
      'currentStreak': newStreak,
      'bestStreak': newBest,
    });
  }

  /// Rompe la racha de un hábito (cuando no se completa un día).
  Future<void> resetStreak(String habitId) async {
    await updateHabit(habitId, {'currentStreak': 0});
  }
}