import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/public_profile_model.dart';
import '../domain/public_habit_model.dart';

/// Repositorio que gestiona los perfiles públicos.
/// Colección espejo: public_profiles/{uid} — nunca expone datos privados.
class PublicProfileRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  PublicProfileRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _publicProfilesRef =>
      _firestore.collection('public_profiles');

  CollectionReference<Map<String, dynamic>> get _usernamesRef =>
      _firestore.collection('usernames');

  DocumentReference<Map<String, dynamic>> get _myProfileRef =>
      _publicProfilesRef.doc(_uid);

  CollectionReference<Map<String, dynamic>> get _myPublicHabitsRef =>
      _myProfileRef.collection('habits');

  // ==================== USERNAME ====================

  /// Devuelve true si el username está disponible
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _usernamesRef.doc(username).get();
    return !doc.exists;
  }

  /// Valida formato del username: lowercase, 3-20 chars, [a-z0-9_]
  static bool isValidUsername(String username) {
    if (username.length < 3 || username.length > 20) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(username);
  }

  // ==================== HABILITAR / DESHABILITAR PERFIL ====================

  /// Activa el perfil público:
  /// 1. Reserva el username en usernames/{name}
  /// 2. Crea public_profiles/{uid} con snapshot de datos
  /// 3. Copia los hábitos activos a la subcolección pública
  /// Devuelve false si el username ya está ocupado
  Future<bool> enablePublicProfile({
    required String username,
    required String displayName,
    required String avatarInitials,
    String? photoUrl,
  }) async {
    // Verificar disponibilidad antes del batch
    final available = await isUsernameAvailable(username);
    if (!available) return false;

    final now = DateTime.now();

    // Leer hábitos activos del usuario
    final habitsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .get();

    // Leer logros desbloqueados
    final achievementsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('achievements')
        .get();

    // Calcular mejor racha
    int bestStreak = 0;
    for (final doc in habitsSnap.docs) {
      final streak = doc.data()['bestStreak'] as int? ?? 0;
      if (streak > bestStreak) bestStreak = streak;
    }

    final profileData = PublicProfileModel(
      uid: _uid,
      username: username,
      displayName: displayName,
      avatarInitials: avatarInitials,
      averageLevel: 1.0,
      totalHabits: habitsSnap.docs.length,
      bestStreakEver: bestStreak,
      unlockedAchievements: achievementsSnap.docs.length,
      createdAt: now,
      photoUrl: photoUrl,
    );

    // Batch atómico
    final batch = _firestore.batch();

    // Reservar username
    batch.set(_usernamesRef.doc(username), {'uid': _uid});

    // Crear perfil público
    batch.set(_myProfileRef, profileData.toJson());

    // Actualizar flag en users/{uid}
    batch.set(
      _firestore.collection('users').doc(_uid),
      {
        'isProfilePublic': true,
        'username': username,
        'publicProfileCreatedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );

    // Copiar hábitos activos a la subcolección pública
    for (final doc in habitsSnap.docs) {
      final data = doc.data();
      final publicHabit = PublicHabitModel(
        id: doc.id,
        title: data['title'] as String? ?? '',
        category: data['category'] as String? ?? 'productividad',
        emoji: data['emoji'] as String?,
        currentStreak: data['currentStreak'] as int? ?? 0,
        bestStreak: data['bestStreak'] as int? ?? 0,
      );
      batch.set(_myPublicHabitsRef.doc(doc.id), publicHabit.toJson());
    }

    await batch.commit();
    return true;
  }

  /// Desactiva el perfil público:
  /// Borra public_profiles/{uid}, su subcolección de hábitos y usernames/{name}.
  /// Anonimiza las plantillas publicadas para no dejar datos personales expuestos.
  Future<void> disablePublicProfile(String username) async {
    // Borrar hábitos públicos primero (subcolección)
    final habitsSnap = await _myPublicHabitsRef.get();

    final batch = _firestore.batch();

    for (final doc in habitsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar doc de perfil
    batch.delete(_myProfileRef);

    // Liberar username
    batch.delete(_usernamesRef.doc(username));

    // Actualizar flag en users/{uid}
    batch.set(
      _firestore.collection('users').doc(_uid),
      {
        'isProfilePublic': false,
        'username': null,
        'publicProfileCreatedAt': null,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Anonimizar plantillas publicadas en batch separado
    // (evita superar el límite de 500 ops si hay muchos hábitos públicos)
    final templatesSnap = await _firestore
        .collection('community_templates')
        .where('authorUid', isEqualTo: _uid)
        .get();

    if (templatesSnap.docs.isNotEmpty) {
      final anonBatch = _firestore.batch();
      for (final doc in templatesSnap.docs) {
        anonBatch.update(doc.reference, {
          'authorUsername': 'usuario',
          'authorDisplayName': 'Usuario anónimo',
          'authorPhotoUrl': null,
        });
      }
      await anonBatch.commit();
    }
  }

  /// Cambia el username: libera el antiguo y reserva el nuevo
  /// Devuelve false si el nuevo ya está ocupado
  Future<bool> changeUsername(
    String oldUsername,
    String newUsername,
    String displayName,
    String avatarInitials,
  ) async {
    final available = await isUsernameAvailable(newUsername);
    if (!available) return false;

    final batch = _firestore.batch();

    // Liberar username viejo
    batch.delete(_usernamesRef.doc(oldUsername));

    // Reservar username nuevo
    batch.set(_usernamesRef.doc(newUsername), {'uid': _uid});

    // Actualizar en perfil público y en users
    batch.update(_myProfileRef, {'username': newUsername});
    batch.set(
      _firestore.collection('users').doc(_uid),
      {'username': newUsername},
      SetOptions(merge: true),
    );

    await batch.commit();
    return true;
  }

  // ==================== SYNC DE HÁBITOS ====================

  /// Sincroniza un hábito en la subcolección pública
  Future<void> syncHabit(PublicHabitModel habit) async {
    await _myPublicHabitsRef.doc(habit.id).set(habit.toJson());
    // Actualizar contador de totalHabits en el perfil
    await _refreshProfileCounters();
  }

  /// Elimina un hábito de la subcolección pública (cuando se desactiva)
  Future<void> removeHabit(String habitId) async {
    await _myPublicHabitsRef.doc(habitId).delete();
    await _refreshProfileCounters();
  }

  /// Actualiza solo las rachas de un hábito público
  Future<void> updateHabitStreaks(
    String habitId,
    int currentStreak,
    int bestStreak,
  ) async {
    try {
      await _myPublicHabitsRef.doc(habitId).update({
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
      });
      await _refreshBestStreak();
    } catch (_) {
      // el hábito puede no existir en el perfil público todavía
    }
  }

  /// Sincroniza la foto de perfil en el espejo público (si existe el doc)
  Future<void> syncPhotoUrl(String? url) async {
    try {
      await _myProfileRef.update({'photoUrl': url});
    } catch (_) {
      // perfil público no existe, ignorar
    }
  }

  /// Actualiza nivel y logros en el perfil público
  Future<void> syncUserLevel(double averageLevel, int unlockedAchievements) async {
    try {
      await _myProfileRef.update({
        'averageLevel': averageLevel,
        'unlockedAchievements': unlockedAchievements,
      });
    } catch (_) {
      // perfil no existe, no hacer nada
    }
  }

  // ==================== LECTURA PÚBLICA ====================

  /// Búsqueda por prefix de username (prefix search estándar Firestore)
  Future<List<PublicProfileModel>> searchByUsername(
    String prefix, {
    int limit = 20,
  }) async {
    if (prefix.isEmpty) return [];
    final snap = await _publicProfilesRef
        .where('username', isGreaterThanOrEqualTo: prefix)
        .where('username', isLessThan: '$prefix\uf8ff')
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => PublicProfileModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Feed global paginado por createdAt desc
  Future<({List<PublicProfileModel> profiles, DocumentSnapshot? lastDoc})>
      watchPublicProfilesFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _publicProfilesRef
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final profiles = snap.docs
        .map((doc) => PublicProfileModel.fromFirestore(doc.data(), doc.id))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (profiles: profiles, lastDoc: lastDoc);
  }

  /// Fetch puntual de un perfil público
  Future<PublicProfileModel?> getPublicProfile(String uid) async {
    final doc = await _publicProfilesRef.doc(uid).get();
    if (!doc.exists) return null;
    return PublicProfileModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream de hábitos públicos de un usuario
  Stream<List<PublicHabitModel>> watchPublicHabits(String uid) {
    return _publicProfilesRef
        .doc(uid)
        .collection('habits')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PublicHabitModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ==================== HELPERS PRIVADOS ====================

  Future<void> _refreshProfileCounters() async {
    final snap = await _myPublicHabitsRef.get();
    final count = snap.docs.length;

    int bestStreak = 0;
    for (final doc in snap.docs) {
      final streak = doc.data()['bestStreak'] as int? ?? 0;
      if (streak > bestStreak) bestStreak = streak;
    }

    try {
      await _myProfileRef.update({
        'totalHabits': count,
        'bestStreakEver': bestStreak,
      });
    } catch (_) {}
  }

  Future<void> _refreshBestStreak() async {
    final snap = await _myPublicHabitsRef.get();
    int bestStreak = 0;
    for (final doc in snap.docs) {
      final streak = doc.data()['bestStreak'] as int? ?? 0;
      if (streak > bestStreak) bestStreak = streak;
    }
    try {
      await _myProfileRef.update({'bestStreakEver': bestStreak});
    } catch (_) {}
  }
}
