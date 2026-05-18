import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_directory_entry.dart';
import '../domain/privacy_level.dart';

/// Gestiona /user_directory/{uid} — colección ligera para búsqueda y privacidad.
/// Separada de public_profiles para no mezclar "soy buscable" con "tengo perfil público".
class UserDirectoryRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  UserDirectoryRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _dirRef =>
      _firestore.collection('user_directory');

  CollectionReference<Map<String, dynamic>> get _usernamesRef =>
      _firestore.collection('usernames');

  DocumentReference<Map<String, dynamic>> get _myEntry =>
      _dirRef.doc(_uid);

  // ==================== USERNAME ====================

  /// Valida formato: lowercase, 3-20 chars, [a-z0-9_]
  static bool isValidUsername(String username) {
    if (username.length < 3 || username.length > 20) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(username);
  }

  /// Devuelve true si el username está disponible
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _usernamesRef.doc(username).get();
    return !doc.exists;
  }

  /// Reserva username + crea /user_directory/{uid}.
  /// Devuelve false si el username ya está ocupado.
  Future<bool> claimUsername({
    required String username,
    required String displayName,
    String? photoUrl,
  }) async {
    final available = await isUsernameAvailable(username);
    if (!available) return false;

    final now = DateTime.now();
    final batch = _firestore.batch();

    // reservar en /usernames
    batch.set(_usernamesRef.doc(username), {'uid': _uid});

    // crear entrada en /user_directory
    batch.set(_myEntry, {
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'challengePrivacy': 'everyone',
      'profileVisibility': 'everyone',
      'createdAt': Timestamp.fromDate(now),
    });

    // actualizar username en /users/{uid}
    batch.set(
      _firestore.collection('users').doc(_uid),
      {'username': username},
      SetOptions(merge: true),
    );

    await batch.commit();
    return true;
  }

  /// Libera el username y borra /user_directory/{uid}
  Future<void> releaseUsername(String username) async {
    final batch = _firestore.batch();
    batch.delete(_usernamesRef.doc(username));
    batch.delete(_myEntry);
    batch.set(
      _firestore.collection('users').doc(_uid),
      {'username': null},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Cambia el username: libera el viejo, reserva el nuevo.
  /// Devuelve false si el nuevo ya está ocupado.
  Future<bool> changeUsername(String oldUsername, String newUsername) async {
    final available = await isUsernameAvailable(newUsername);
    if (!available) return false;

    final batch = _firestore.batch();
    batch.delete(_usernamesRef.doc(oldUsername));
    batch.set(_usernamesRef.doc(newUsername), {'uid': _uid});
    batch.update(_myEntry, {'username': newUsername});
    batch.set(
      _firestore.collection('users').doc(_uid),
      {'username': newUsername},
      SetOptions(merge: true),
    );
    await batch.commit();
    return true;
  }

  // ==================== PRIVACIDAD ====================

  /// Actualiza los ajustes de privacidad del directorio
  Future<void> updatePrivacySettings({
    PrivacyLevel? challengePrivacy,
    PrivacyLevel? profileVisibility,
  }) async {
    final updates = <String, dynamic>{};
    if (challengePrivacy != null) {
      updates['challengePrivacy'] = challengePrivacy.value;
    }
    if (profileVisibility != null) {
      updates['profileVisibility'] = profileVisibility.value;
    }
    if (updates.isEmpty) return;

    // actualizar en user_directory y en users/{uid} en batch
    final batch = _firestore.batch();
    batch.update(_myEntry, updates);
    batch.set(
      _firestore.collection('users').doc(_uid),
      {
        if (challengePrivacy != null)
          'challengePrivacy': challengePrivacy.value,
        if (profileVisibility != null)
          'profileVisibility': profileVisibility.value,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ==================== BÚSQUEDA ====================

  /// Prefix search por username en /user_directory
  Future<List<UserDirectoryEntry>> searchByUsername(
    String prefix, {
    int limit = 20,
  }) async {
    if (prefix.isEmpty) return [];
    final snap = await _dirRef
        .where('username', isGreaterThanOrEqualTo: prefix)
        .where('username', isLessThan: '$prefix')
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => UserDirectoryEntry.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Fetch puntual de una entrada del directorio
  Future<UserDirectoryEntry?> getEntry(String uid) async {
    final doc = await _dirRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserDirectoryEntry.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream de la propia entrada (para escuchar cambios de privacidad)
  Stream<UserDirectoryEntry?> watchMyEntry() {
    return _myEntry.snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserDirectoryEntry.fromFirestore(snap.data()!, snap.id);
    });
  }

  // ==================== MIGRACIÓN ====================

  /// Si el usuario ya tiene username pero no tiene entrada en /user_directory, la crea.
  /// Para usuarios existentes que se actualizan desde el sistema antiguo.
  Future<void> ensureDirectoryEntry({
    required String username,
    required String displayName,
    String? photoUrl,
  }) async {
    final existing = await _myEntry.get();
    if (existing.exists) return;

    await _myEntry.set({
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'challengePrivacy': 'everyone',
      'profileVisibility': 'everyone',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Sincroniza displayName y photoUrl en /user_directory (cuando el usuario actualiza perfil)
  Future<void> syncProfileInfo({String? displayName, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    try {
      await _myEntry.update(updates);
    } catch (_) {
      // la entrada puede no existir si el usuario no tiene username
    }
  }
}
