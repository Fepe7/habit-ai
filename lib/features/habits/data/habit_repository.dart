import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import '../../profile/domain/public_habit_model.dart';
import '../../../services/notification_service.dart';

// CRUD de habitos y logs en Firestore
class HabitRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HabitRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Ref al doc del perfil público (para sync dual)
  CollectionReference<Map<String, dynamic>> get _publicHabitsRef =>
      _firestore.collection('public_profiles').doc(_uid).collection('habits');

  // Comprobar si el usuario tiene perfil público activo
  Future<bool> _isProfilePublic() async {
    final snap = await _firestore.collection('users').doc(_uid).get();
    return snap.data()?['isProfilePublic'] as bool? ?? false;
  }


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

  // Todos los hábitos activos del usuario (sin filtrar por día)
  Future<List<HabitModel>> getActiveHabits() async {
    final snap = await _habitsRef.where('isActive', isEqualTo: true).get();
    return snap.docs
        .map((d) => HabitModel.fromJson(d.data(), d.id))
        .toList();
  }

  // Crear habito nuevo (+ sync en perfil público si está activo)
  Future<String> createHabit(HabitModel habit) async {
    final docRef = await _habitsRef.add(habit.toJson());
    final newId = docRef.id;

    // sync al perfil público si corresponde
    if (await _isProfilePublic()) {
      final publicHabit = PublicHabitModel(
        id: newId,
        title: habit.title,
        category: habit.category,
        emoji: null,
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
      );
      try {
        await _publicHabitsRef.doc(newId).set(publicHabit.toJson());
      } catch (_) {
        // error de sync no bloquea la operación principal
      }
    }

    // programar recordatorios locales (el servicio ignora si no hay reminderTime)
    await NotificationService.instance.scheduleHabitReminders(
      _withId(habit, newId),
    );

    return newId;
  }

  // Clona el habito con un id concreto (el original trae id vacio antes de Firestore)
  HabitModel _withId(HabitModel h, String id) => HabitModel(
        id: id,
        title: h.title,
        description: h.description,
        category: h.category,
        frequency: h.frequency,
        targetDays: h.targetDays,
        reminderTime: h.reminderTime,
        currentStreak: h.currentStreak,
        bestStreak: h.bestStreak,
        isAIGenerated: h.isAIGenerated,
        createdAt: h.createdAt,
        isActive: h.isActive,
        groupId: h.groupId,
      );

  // Crear varios habitos a la vez (para cuando la IA genera un plan)
  Future<void> createHabits(List<HabitModel> habits) async {
    final batch = _firestore.batch();
    final withIds = <HabitModel>[];
    for (final habit in habits) {
      final docRef = _habitsRef.doc();
      batch.set(docRef, habit.toJson());
      withIds.add(_withId(habit, docRef.id));
    }
    await batch.commit();
    for (final h in withIds) {
      await NotificationService.instance.scheduleHabitReminders(h);
    }
  }

  // Crear varios habitos asignados a un grupo
  Future<void> createHabitsInGroup(List<HabitModel> habits, String groupId) async {
    final batch = _firestore.batch();
    final withIds = <HabitModel>[];
    for (final habit in habits) {
      final docRef = _habitsRef.doc();
      final json = habit.toJson();
      json['groupId'] = groupId;
      batch.set(docRef, json);
      withIds.add(_withId(habit.copyWith(groupId: groupId), docRef.id));
    }
    await batch.commit();
    for (final h in withIds) {
      await NotificationService.instance.scheduleHabitReminders(h);
    }
  }

  // Habitos de hoy sin grupo (creados manualmente)
  Stream<List<HabitModel>> watchUngroupedTodayHabits() {
    final today = DateTime.now().weekday;
    // filtramos groupId == null en cliente porque Firestore no combina
    // isNull con arrayContains sin indice compuesto
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .where('targetDays', arrayContains: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
            .where((h) => h.groupId == null)
            .toList());
  }

  // Habitos de hoy de un grupo concreto
  Stream<List<HabitModel>> watchTodayHabitsByGroup(String groupId) {
    final today = DateTime.now().weekday;
    // filtramos groupId en cliente para evitar indice compuesto triple
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .where('targetDays', arrayContains: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
            .where((h) => h.groupId == groupId)
            .toList());
  }

  // Todos los habitos del usuario (activos y archivados, sin filtro de dia)
  // util para la pantalla "Todos mis habitos"
  Stream<List<HabitModel>> watchAllHabits() {
    return _habitsRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Borrado total: elimina logs + doc principal + espejo público
  // Solo se llama desde "Todos mis hábitos" tras confirmación fuerte
  Future<void> hardDeleteHabit(String habitId) async {
    // borrar subcoleccion de logs en chunks (Firestore limita a 500 por batch)
    final logsSnap = await _logsRef(habitId).get();
    if (logsSnap.docs.isNotEmpty) {
      const chunkSize = 400;
      for (int i = 0; i < logsSnap.docs.length; i += chunkSize) {
        final chunk = logsSnap.docs.skip(i).take(chunkSize);
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    // borrar doc principal y espejo público en una segunda batch
    final batch = _firestore.batch();
    batch.delete(_habitsRef.doc(habitId));
    if (await _isProfilePublic()) {
      batch.delete(_publicHabitsRef.doc(habitId));
    }
    await batch.commit();
    await NotificationService.instance.cancelHabitReminders(habitId);
  }

  // Todos los habitos activos de un grupo (sin filtrar por dia)
  // util para la pantalla de edicion del grupo
  Stream<List<HabitModel>> watchAllHabitsByGroup(String groupId) {
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
            .where((h) => h.groupId == groupId)
            .toList());
  }

  // Actualizar habito (+ sync de campos públicos si corresponde)
  Future<void> updateHabit(String habitId, Map<String, dynamic> data) async {
    await _habitsRef.doc(habitId).update(data);

    // si cambia algo que afecte al recordatorio, reprogramar
    final affectsReminder = data.containsKey('reminderTime') ||
        data.containsKey('targetDays') ||
        data.containsKey('title') ||
        data.containsKey('description') ||
        data.containsKey('isActive');
    if (affectsReminder) {
      final fresh = await getHabit(habitId);
      if (fresh != null) {
        await NotificationService.instance.scheduleHabitReminders(fresh);
      }
    }

    // sync campos públicos al perfil si está activo
    if (await _isProfilePublic()) {
      final publicFields = <String, dynamic>{};
      if (data.containsKey('title')) publicFields['title'] = data['title'];
      if (data.containsKey('category')) publicFields['category'] = data['category'];
      if (data.containsKey('currentStreak')) {
        publicFields['currentStreak'] = data['currentStreak'];
      }
      if (data.containsKey('bestStreak')) {
        publicFields['bestStreak'] = data['bestStreak'];
      }
      if (publicFields.isNotEmpty) {
        try {
          await _publicHabitsRef.doc(habitId).update(publicFields);
        } catch (_) {
          // el hábito puede no existir en el perfil público
          // (ej: creado por IA vía batch sin sync al espejo)
        }
      }
    }
  }

  // No borramos, solo desactivamos para no perder los logs
  // Si el perfil es público, quitamos el hábito del espejo público
  // Si el hábito está vinculado a un reto, abandonamos el reto
  Future<void> deactivateHabit(String habitId) async {
    // comprobar si el hábito está vinculado a un reto antes del batch
    final habitSnap = await _habitsRef.doc(habitId).get();
    final challengeId = habitSnap.data()?['challengeId'] as String?;

    final batch = _firestore.batch();
    batch.update(_habitsRef.doc(habitId), {'isActive': false});

    if (await _isProfilePublic()) {
      batch.delete(_publicHabitsRef.doc(habitId));
    }

    await batch.commit();
    await NotificationService.instance.cancelHabitReminders(habitId);

    // abandonar reto vinculado
    if (challengeId != null) {
      try {
        await _firestore.collection('challenges').doc(challengeId).update({
          'status': 'abandoned',
        });
      } catch (_) {}
    }
  }

  // Mover un hábito de un grupo a otro (o quitarlo de grupo)
  // Actualiza groupId en el hábito y los contadores de ambos grupos en batch
  Future<void> reassignGroup(
      String habitId, String? oldGroupId, String? newGroupId) async {
    if (oldGroupId == newGroupId) return;

    final batch = _firestore.batch();
    final groupsRef =
        _firestore.collection('users').doc(_uid).collection('habit_groups');

    // actualizar groupId en el hábito
    batch.update(_habitsRef.doc(habitId), {'groupId': newGroupId});

    // decrementar grupo anterior
    if (oldGroupId != null) {
      batch.update(groupsRef.doc(oldGroupId),
          {'habitCount': FieldValue.increment(-1)});
    }

    // incrementar grupo nuevo
    if (newGroupId != null) {
      batch.update(groupsRef.doc(newGroupId),
          {'habitCount': FieldValue.increment(1)});
    }

    await batch.commit();
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

  // Calcular racha real contando dias consecutivos hacia atras.
  // Trata como "dia cumplido" tanto los logs completados como los escudados,
  // y los dias cubiertos por el modo enfermedad.
  Future<int> _calculateStreak(
    String habitId, {
    DateTime? sickModeStart,
    DateTime? sickModeUntil,
  }) async {
    // solo orderBy para evitar indice compuesto, filtramos en codigo
    final snapshot = await _logsRef(habitId)
        .orderBy('date', descending: true)
        .limit(365)
        .get();

    // dias "cumplidos": completados o con escudo
    final doneDays = <DateTime>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final isCompleted = data['completed'] == true;
      final isShielded = data['shielded'] == true;
      if (!isCompleted && !isShielded) continue;
      final date = (data['date'] as Timestamp).toDate();
      doneDays.add(DateTime(date.year, date.month, date.day));
    }

    // añadir dias cubiertos por el modo enfermedad al set de cumplidos
    if (sickModeStart != null && sickModeUntil != null) {
      var day = DateTime(
          sickModeStart.year, sickModeStart.month, sickModeStart.day);
      final end = DateTime(
          sickModeUntil.year, sickModeUntil.month, sickModeUntil.day);
      while (!day.isAfter(end)) {
        doneDays.add(day);
        day = day.add(const Duration(days: 1));
      }
    }

    // contar dias consecutivos desde hoy hacia atras
    final today = DateTime.now();
    var current = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // si hoy no esta cumplido, empezar desde ayer
    if (!doneDays.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    while (doneDays.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Leer el sick mode del usuario para pasarlo al calculo de racha
  Future<({DateTime? start, DateTime? until})> _getSickMode() async {
    final snap =
        await _firestore.collection('users').doc(_uid).get();
    if (!snap.exists) return (start: null, until: null);
    final data = snap.data()!;
    final start = data['sickModeStart'] != null
        ? (data['sickModeStart'] as Timestamp).toDate()
        : null;
    final until = data['sickModeUntil'] != null
        ? (data['sickModeUntil'] as Timestamp).toDate()
        : null;
    return (start: start, until: until);
  }

  // Recalcular racha tras completar un habito
  Future<void> updateStreak(String habitId) async {
    final habit = await getHabit(habitId);
    if (habit == null) return;

    final sickMode = await _getSickMode();
    final newStreak = await _calculateStreak(
      habitId,
      sickModeStart: sickMode.start,
      sickModeUntil: sickMode.until,
    );
    final newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    await updateHabit(habitId, {
      'currentStreak': newStreak,
      'bestStreak': newBest,
    });

    // cancelar el recordatorio de hoy: ya se ha cumplido, no hace falta avisar
    await NotificationService.instance.cancelTodayReminder(habit);
  }

  // Recalcular racha tras desmarcar (borra log + recalcula)
  Future<void> uncheckAndRecalculate(String habitId) async {
    await deleteTodayLog(habitId);

    final habit = await getHabit(habitId);
    if (habit == null) return;

    final sickMode = await _getSickMode();
    final newStreak = await _calculateStreak(
      habitId,
      sickModeStart: sickMode.start,
      sickModeUntil: sickMode.until,
    );

    await updateHabit(habitId, {'currentStreak': newStreak});

    // si aun no ha pasado la hora del recordatorio, reprogramarlo para hoy
    await NotificationService.instance.scheduleHabitReminders(habit);
  }

  // ==================== ESCUDOS DE RACHA ====================

  // Usar un escudo en un dia concreto (crea log shielded y descuenta escudo)
  // Devuelve false si el usuario no tiene escudos suficientes
  Future<bool> useShield(String habitId, DateTime date) async {
    final userRef = _firestore.collection('users').doc(_uid);

    bool success = false;
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final shields = userSnap.data()?['shieldsCount'] as int? ?? 0;
      if (shields <= 0) return;

      // crear el log shielded
      final logRef = _logsRef(habitId).doc();
      final dayStart = DateTime(date.year, date.month, date.day);
      tx.set(logRef, {
        'date': Timestamp.fromDate(dayStart),
        'completed': false,
        'shielded': true,
        'notes': null,
      });

      // descontar escudo
      tx.update(userRef, {'shieldsCount': shields - 1});
      success = true;
    });

    if (success) {
      // recalcular racha con el nuevo log
      final sickMode = await _getSickMode();
      final habit = await getHabit(habitId);
      if (habit != null) {
        final newStreak = await _calculateStreak(
          habitId,
          sickModeStart: sickMode.start,
          sickModeUntil: sickMode.until,
        );
        final newBest =
            newStreak > habit.bestStreak ? newStreak : habit.bestStreak;
        await updateHabit(habitId, {
          'currentStreak': newStreak,
          'bestStreak': newBest,
        });
      }
    }

    return success;
  }

  // Quitar un escudo usado (devuelve el escudo al usuario)
  Future<void> removeShield(String habitId, DateTime date) async {
    final userRef = _firestore.collection('users').doc(_uid);

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // buscar el log shielded de ese dia
    final snap = await _logsRef(habitId)
        .where('shielded', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final shields = userSnap.data()?['shieldsCount'] as int? ?? 0;
      final newCount = (shields + 1).clamp(0, 5);

      tx.delete(snap.docs.first.reference);
      tx.update(userRef, {'shieldsCount': newCount});
    });

    // recalcular racha sin ese escudo
    final sickMode = await _getSickMode();
    final habit = await getHabit(habitId);
    if (habit != null) {
      final newStreak = await _calculateStreak(
        habitId,
        sickModeStart: sickMode.start,
        sickModeUntil: sickMode.until,
      );
      await updateHabit(habitId, {'currentStreak': newStreak});
    }
  }

  // Comprobar si hoy hay un log de tipo escudo activo
  Future<bool> isShieldedToday(String habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _logsRef(habitId)
        .where('shielded', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }
}