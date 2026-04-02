import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/achivement_model.dart';

// Gestiona los logros (solo lectura y creacion, no se borran)
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

  // Logros en tiempo real
  Stream<List<AchievementModel>> watchAchievements() {
    return _achievementsRef
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AchievementModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // Desbloquear logro (comprueba que no exista ya)
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

  // Comprobar si ya tiene un logro
  Future<bool> isUnlocked(String type) async {
    // limit(1) para no bajar mas de lo necesario
    final snapshot = await _achievementsRef
        .where('type', isEqualTo: type)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}