import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/follow_model.dart';
import '../domain/follow_request_model.dart';

/// Gestiona el sistema de seguidores/siguiendo (Instagram-style).
/// Relaciones unidireccionales: follow directo si perfil público,
/// solicitud si perfil privado (isProfilePublic = false).
class FollowRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  FollowRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('follow_requests');

  CollectionReference<Map<String, dynamic>> _followersRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('followers');

  CollectionReference<Map<String, dynamic>> _followingRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('following');

  // ==================== FOLLOW DIRECTO (perfil público) ====================

  /// Seguir a un usuario público: crea docs en ambas subcolecciones en batch.
  Future<void> follow({
    required String targetUid,
    required String targetUsername,
    required String targetDisplayName,
    String? targetPhotoUrl,
    required String myUsername,
    required String myDisplayName,
    String? myPhotoUrl,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // yo aparezco en los followers del target
    batch.set(_followersRef(targetUid).doc(_uid), {
      'username': myUsername,
      'displayName': myDisplayName,
      'photoUrl': myPhotoUrl,
      'followedAt': Timestamp.fromDate(now),
    });

    // target aparece en mi following
    batch.set(_followingRef(_uid).doc(targetUid), {
      'username': targetUsername,
      'displayName': targetDisplayName,
      'photoUrl': targetPhotoUrl,
      'followedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Dejar de seguir: borra los docs en ambas subcolecciones.
  Future<void> unfollow(String targetUid) async {
    final batch = _firestore.batch();
    batch.delete(_followersRef(targetUid).doc(_uid));
    batch.delete(_followingRef(_uid).doc(targetUid));
    await batch.commit();
  }

  // ==================== FOLLOW REQUESTS (perfil privado) ====================

  /// Enviar solicitud de seguimiento a un perfil privado.
  Future<String> sendFollowRequest({
    required String toUid,
    required String fromUsername,
    required String fromDisplayName,
    String? fromPhotoUrl,
    required String toUsername,
    required String toDisplayName,
    String? toPhotoUrl,
  }) async {
    final doc = _requestsRef.doc();
    await doc.set({
      'fromUid': _uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
      'fromUsername': fromUsername,
      'fromDisplayName': fromDisplayName,
      'fromPhotoUrl': fromPhotoUrl,
      'toUsername': toUsername,
      'toDisplayName': toDisplayName,
      'toPhotoUrl': toPhotoUrl,
    });
    return doc.id;
  }

  /// Aceptar solicitud: actualiza estado + crea docs de follower/following en batch.
  Future<void> acceptFollowRequest(String requestId) async {
    final reqDoc = await _requestsRef.doc(requestId).get();
    if (!reqDoc.exists) return;
    final data = reqDoc.data()!;
    final fromUid = data['fromUid'] as String;
    final toUid = data['toUid'] as String;

    final now = DateTime.now();
    final batch = _firestore.batch();

    batch.update(_requestsRef.doc(requestId), {
      'status': 'accepted',
      'respondedAt': Timestamp.fromDate(now),
    });

    // fromUid pasa a ser follower de toUid
    batch.set(_followersRef(toUid).doc(fromUid), {
      'username': data['fromUsername'],
      'displayName': data['fromDisplayName'],
      'photoUrl': data['fromPhotoUrl'],
      'followedAt': Timestamp.fromDate(now),
    });

    // toUid aparece en el following de fromUid
    batch.set(_followingRef(fromUid).doc(toUid), {
      'username': data['toUsername'],
      'displayName': data['toDisplayName'],
      'photoUrl': data['toPhotoUrl'],
      'followedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Rechazar solicitud.
  Future<void> declineFollowRequest(String requestId) async {
    await _requestsRef.doc(requestId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== QUERIES ====================

  /// Stream de quién me sigue.
  Stream<List<FollowModel>> watchMyFollowers() {
    return _followersRef(_uid)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FollowModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream de a quién sigo.
  Stream<List<FollowModel>> watchMyFollowing() {
    return _followingRef(_uid)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FollowModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Solicitudes de seguimiento entrantes pendientes.
  Stream<List<FollowRequestModel>> watchPendingFollowRequests() {
    return _requestsRef
        .where('toUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                FollowRequestModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Solicitudes de seguimiento enviadas pendientes.
  Stream<List<FollowRequestModel>> watchSentFollowRequests() {
    return _requestsRef
        .where('fromUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                FollowRequestModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ==================== CHECKS ====================

  /// ¿Yo sigo a [targetUid]?
  Future<bool> isFollowing(String targetUid) async {
    final doc = await _followingRef(_uid).doc(targetUid).get();
    return doc.exists;
  }

  /// ¿[otherUid] me sigue a mí?
  Future<bool> isFollowedBy(String otherUid) async {
    final doc = await _followersRef(_uid).doc(otherUid).get();
    return doc.exists;
  }

  /// ¿Nos seguimos mutuamente?
  Future<bool> isMutual(String otherUid) async {
    final results = await Future.wait([
      isFollowing(otherUid),
      isFollowedBy(otherUid),
    ]);
    return results[0] && results[1];
  }

  /// Lista de UIDs a quienes sigo (para filtrar búsquedas y privacidad).
  Future<List<String>> getFollowingUids() async {
    final snap = await _followingRef(_uid).get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  /// Lista de UIDs que me siguen.
  Future<List<String>> getFollowerUids() async {
    final snap = await _followersRef(_uid).get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  /// Cancela una solicitud pendiente enviada a [toUid].
  Future<void> cancelFollowRequest(String toUid) async {
    final snap = await _requestsRef
        .where('fromUid', isEqualTo: _uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// UIDs a los que ya envié solicitud pendiente (para poblar _pendingUids al arrancar).
  Future<List<String>> getSentPendingUids() async {
    final snap = await _requestsRef
        .where('fromUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((doc) => doc.data()['toUid'] as String? ?? '')
        .where((uid) => uid.isNotEmpty)
        .toList();
  }

  /// ¿Hay una solicitud pendiente de mí hacia [otherUid]?
  Future<bool> hasPendingFollowRequest(String otherUid) async {
    final snap = await _requestsRef
        .where('fromUid', isEqualTo: _uid)
        .where('toUid', isEqualTo: otherUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ==================== GESTIÓN ====================

  /// Eliminar a [followerUid] de mis seguidores.
  /// Solo borra de mi /followers — el doc en su /following queda huérfano (aceptable).
  Future<void> removeFollower(String followerUid) async {
    await _followersRef(_uid).doc(followerUid).delete();
  }
}
