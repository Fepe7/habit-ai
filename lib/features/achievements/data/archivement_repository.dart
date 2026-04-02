import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/achivement_model.dart';

/// Repositorio de logros del usuario.
/// Solo permite leer y crear — los logros no se editan ni borran.
class AchievementRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  AchievementRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _achievementsRef =>
      _firestore.collection('users').doc(_uid).collection('achievements');

  /// Stream reactivo de todos los logros del usuario.
  Stream<List<AchievementModel>> watchAchievements() {
    return _achievementsRef
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AchievementModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Desbloquea un logro si no existe ya.
  /// Comprueba primero si el tipo ya fue desbloqueado para evitar duplicados.
  Future<bool> unlockAchievement({
    required String type,
    String? habitId,
  }) async {
    // Verificar si ya existe este tipo de logro
    final existing = await _achievementsRef
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return false; // Ya desbloqueado

    final achievement = AchievementModel(
      id: '',
      type: type,
      unlockedAt: DateTime.now(),
      habitId: habitId,
    );

    await _achievementsRef.add(achievement.toJson());
    return true; // Nuevo logro desbloqueado
  }

  /// Comprueba si un tipo de logro ya está desbloqueado.
  Future<bool> isUnlocked(String type) async {
    // EFICIENCIA: limit(1) para no descargar más de un documento
    final snapshot = await _achievementsRef
        .where('type', isEqualTo: type)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}