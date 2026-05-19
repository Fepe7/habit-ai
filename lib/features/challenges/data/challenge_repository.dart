import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/challenge_model.dart';
import '../domain/challenge_participant_model.dart';
import '../domain/challenge_progress_model.dart';

// CRUD de retos compartidos
class ChallengeRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ChallengeRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _firestore.collection('challenges');

  // ==================== CREACIÓN ====================

  Future<String> createChallenge({
    required String habitTitle,
    required String habitDescription,
    required String habitCategory,
    required int durationDays,
    required String invitedUid,
    required ChallengeParticipantModel creatorParticipant,
  }) async {
    final challengeRef = _challengesRef.doc();
    final batch = _firestore.batch();

    final challenge = ChallengeModel(
      id: challengeRef.id,
      habitTitle: habitTitle,
      habitDescription: habitDescription,
      habitCategory: habitCategory,
      durationDays: durationDays,
      creatorUid: _uid,
      invitedUid: invitedUid,
      status: ChallengeStatus.pending,
      createdAt: DateTime.now(),
      participantUids: [_uid, invitedUid],
    );

    batch.set(challengeRef, challenge.toJson());

    batch.set(
      challengeRef.collection('participants').doc(_uid),
      creatorParticipant.toJson(),
    );

    final emptyProgress = ChallengeProgressModel(
      uid: _uid,
      days: {},
      completedCount: 0,
      currentStreak: 0,
      updatedAt: DateTime.now(),
    );
    batch.set(
      challengeRef.collection('progress').doc(_uid),
      emptyProgress.toJson(),
    );

    await batch.commit();
    return challengeRef.id;
  }

  // ==================== FLUJO DE INVITACIÓN ====================

  Future<void> acceptChallenge({
    required String challengeId,
    required ChallengeParticipantModel inviteeParticipant,
    required String habitId,
  }) async {
    final challengeRef = _challengesRef.doc(challengeId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(challengeRef);
      if (!snap.exists) throw Exception('Reto no encontrado');

      final data = snap.data()!;
      if (data['status'] != 'pending') {
        throw Exception('Este reto ya no está pendiente');
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final durationDays = data['durationDays'] as int? ?? 21;
      final endDate = startDate.add(Duration(days: durationDays));

      tx.update(challengeRef, {
        'status': ChallengeStatus.active.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
      });

      final participant = ChallengeParticipantModel(
        uid: inviteeParticipant.uid,
        username: inviteeParticipant.username,
        displayName: inviteeParticipant.displayName,
        photoUrl: inviteeParticipant.photoUrl,
        habitId: habitId,
        joinedAt: now,
      );

      tx.set(
        challengeRef.collection('participants').doc(_uid),
        participant.toJson(),
      );

      final emptyProgress = ChallengeProgressModel(
        uid: _uid,
        days: {},
        completedCount: 0,
        currentStreak: 0,
        updatedAt: now,
      );
      tx.set(
        challengeRef.collection('progress').doc(_uid),
        emptyProgress.toJson(),
      );
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'status': ChallengeStatus.declined.name,
    });
  }

  Future<void> abandonChallenge(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'status': ChallengeStatus.abandoned.name,
    });
  }

  Future<void> completeChallenge(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'status': ChallengeStatus.completed.name,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==================== QUERIES ====================

  Stream<List<ChallengeModel>> watchMyChallenges() {
    return _challengesRef
        .where('participantUids', arrayContains: _uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<ChallengeModel>> watchPendingInvites() {
    // Filtro de status en cliente para evitar índice compuesto en Firestore
    return _challengesRef
        .where('invitedUid', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
            .where((c) => c.status == ChallengeStatus.pending)
            .toList());
  }

  // retos que yo creé y el compañero acaba de aceptar (status = active)
  Stream<List<ChallengeModel>> watchAcceptedByOthers() {
    // Filtro de status en cliente para evitar índice compuesto en Firestore
    return _challengesRef
        .where('creatorUid', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
            .where((c) => c.status == ChallengeStatus.active)
            .toList());
  }

  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final snap = await _challengesRef.doc(challengeId).get();
    if (!snap.exists) return null;
    return ChallengeModel.fromJson(snap.data()!, snap.id);
  }

  Stream<ChallengeModel?> watchChallenge(String challengeId) {
    return _challengesRef.doc(challengeId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ChallengeModel.fromJson(snap.data()!, snap.id);
    });
  }

  // ==================== PROGRESO ====================

  Stream<ChallengeProgressModel?> watchProgress(
    String challengeId,
    String uid,
  ) {
    return _challengesRef
        .doc(challengeId)
        .collection('progress')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return ChallengeProgressModel.fromJson(snap.data()!);
    });
  }

  Future<void> updateMyProgress({
    required String challengeId,
    required int dayIndex,
    required DayStatus status,
  }) async {
    final ref =
        _challengesRef.doc(challengeId).collection('progress').doc(_uid);

    final snap = await ref.get();
    final current =
        snap.exists ? ChallengeProgressModel.fromJson(snap.data()!) : null;

    final days = Map<int, DayStatus>.from(current?.days ?? {});
    days[dayIndex] = status;

    final completedCount =
        days.values.where((s) => s == DayStatus.completed).length;

    // racha desde el último día completado hacia atrás
    int streak = 0;
    for (int i = dayIndex; i >= 0; i--) {
      final s = days[i];
      if (s == DayStatus.completed || s == DayStatus.shielded) {
        streak++;
      } else {
        break;
      }
    }

    await ref.set({
      'uid': _uid,
      'days': days.map((k, v) => MapEntry(k.toString(), v.name)),
      'completedCount': completedCount,
      'currentStreak': streak,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Sync automático desde el toggle de un hábito vinculado a reto
  Future<void> syncProgressFromToggle({
    required String challengeId,
    required bool completed,
    bool shielded = false,
  }) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null || !challenge.isActive || challenge.startDate == null) {
      return;
    }

    final today = DateTime.now();
    final start = challenge.startDate!;
    final dayIndex = DateTime(today.year, today.month, today.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;

    if (dayIndex < 0 || dayIndex >= challenge.durationDays) return;

    DayStatus status;
    if (shielded) {
      status = DayStatus.shielded;
    } else if (completed) {
      status = DayStatus.completed;
    } else {
      status = DayStatus.pending;
    }

    await updateMyProgress(
      challengeId: challengeId,
      dayIndex: dayIndex,
      status: status,
    );
  }

  // ==================== PARTICIPANTES ====================

  Future<List<ChallengeParticipantModel>> getParticipants(
    String challengeId,
  ) async {
    final snap =
        await _challengesRef.doc(challengeId).collection('participants').get();
    return snap.docs
        .map((doc) => ChallengeParticipantModel.fromJson(doc.data()))
        .toList();
  }

  Future<ChallengeParticipantModel?> getParticipant(
    String challengeId,
    String uid,
  ) async {
    final snap = await _challengesRef
        .doc(challengeId)
        .collection('participants')
        .doc(uid)
        .get();
    if (!snap.exists) return null;
    return ChallengeParticipantModel.fromJson(snap.data()!);
  }

  // ==================== HELPERS ====================

  // Marcar días pasados sin entrada como "missed"
  Future<void> fillMissedDays(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null || !challenge.isActive || challenge.startDate == null) {
      return;
    }

    final ref =
        _challengesRef.doc(challengeId).collection('progress').doc(_uid);
    final snap = await ref.get();
    if (!snap.exists) return;

    final progress = ChallengeProgressModel.fromJson(snap.data()!);
    final today = DateTime.now();
    final start = challenge.startDate!;
    final todayIndex = DateTime(today.year, today.month, today.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;

    final days = Map<int, DayStatus>.from(progress.days);
    bool changed = false;

    for (int i = 0; i < todayIndex && i < challenge.durationDays; i++) {
      if (!days.containsKey(i)) {
        days[i] = DayStatus.missed;
        changed = true;
      }
    }

    if (!changed) return;

    final completedCount =
        days.values.where((s) => s == DayStatus.completed).length;

    await ref.update({
      'days': days.map((k, v) => MapEntry(k.toString(), v.name)),
      'completedCount': completedCount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Buscar reto activo vinculado a un hábito concreto
  Future<ChallengeModel?> findActiveChallengeForHabit(String habitId) async {
    final snap = await _challengesRef
        .where('participantUids', arrayContains: _uid)
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .get();

    for (final doc in snap.docs) {
      final participantSnap = await doc.reference
          .collection('participants')
          .doc(_uid)
          .get();
      if (participantSnap.exists &&
          participantSnap.data()?['habitId'] == habitId) {
        return ChallengeModel.fromJson(doc.data(), doc.id);
      }
    }
    return null;
  }
}
