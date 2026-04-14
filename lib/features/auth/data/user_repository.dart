import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

// Repositorio para leer y modificar datos del usuario en Firestore
// (escudos de racha, modo enfermedad, etc.)
class UserRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  UserRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_uid);

  // Stream reactivo del usuario para escuchar cambios de escudos y sick mode
  Stream<UserModel> watchUser() {
    return _userRef.snapshots().map((snap) {
      if (!snap.exists) {
        return UserModel(uid: _uid, email: '');
      }
      return UserModel.fromFirestore(snap.data()!, _uid);
    });
  }

  // Leer el usuario una sola vez
  Future<UserModel> getUser() async {
    final snap = await _userRef.get();
    if (!snap.exists) return UserModel(uid: _uid, email: '');
    return UserModel.fromFirestore(snap.data()!, _uid);
  }

  // Conceder escudos con cap en 5 — usa transacción para evitar race conditions
  Future<void> grantShields(int amount) async {
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_userRef);
      final current = snap.data()?['shieldsCount'] as int? ?? 0;
      final newCount = (current + amount).clamp(0, 5);
      tx.update(_userRef, {'shieldsCount': newCount});
    });
  }

  // Gastar un escudo — devuelve false si no había suficientes
  Future<bool> spendShield() async {
    bool spent = false;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_userRef);
      final current = snap.data()?['shieldsCount'] as int? ?? 0;
      if (current <= 0) return;
      tx.update(_userRef, {'shieldsCount': current - 1});
      spent = true;
    });
    return spent;
  }

  // Devolver un escudo (cuando se deshace un escudo usado)
  Future<void> returnShield() async {
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_userRef);
      final current = snap.data()?['shieldsCount'] as int? ?? 0;
      final newCount = (current + 1).clamp(0, 5);
      tx.update(_userRef, {'shieldsCount': newCount});
    });
  }

  // Activar modo enfermedad por [days] días (máx. 7)
  Future<void> activateSickMode(int days) async {
    final clampedDays = days.clamp(1, 7);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final until = start.add(Duration(days: clampedDays - 1));

    await _userRef.update({
      'sickModeStart': Timestamp.fromDate(start),
      'sickModeUntil': Timestamp.fromDate(until),
    });
  }

  // Cancelar modo enfermedad
  Future<void> cancelSickMode() async {
    await _userRef.update({
      'sickModeStart': null,
      'sickModeUntil': null,
    });
  }

  // Comprobar si ya se concedió escudo por un hito concreto de un hábito
  // (deduplicación para no dar escudos dos veces)
  Future<bool> hasShieldGrant(String habitId, int milestone) async {
    final grantId = '${habitId}_$milestone';
    final snap = await _userRef
        .collection('shield_grants')
        .doc(grantId)
        .get();
    return snap.exists;
  }

  // Registrar que se concedió escudo por este hito (evita repetición)
  Future<void> recordShieldGrant(String habitId, int milestone) async {
    final grantId = '${habitId}_$milestone';
    await _userRef
        .collection('shield_grants')
        .doc(grantId)
        .set({'grantedAt': FieldValue.serverTimestamp()});
  }
}
