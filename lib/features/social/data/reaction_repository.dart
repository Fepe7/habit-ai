import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/reaction_model.dart';

/// CRUD + streams para reacciones emoji sobre logros en perfiles públicos.
/// Colección: public_profiles/{ownerUid}/reactions/{reactorUid}_{achievementType}
class ReactionRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String ownerUid) =>
      _db.collection('public_profiles').doc(ownerUid).collection('reactions');

  /// Crea o sobreescribe la reacción al perfil (doc ID = reactorUid)
  Future<void> react({
    required String ownerUid,
    required String reactorUid,
    required String reactorUsername,
    required String reactorDisplayName,
    String? reactorPhotoUrl,
    required String emoji,
  }) async {
    final reaction = ReactionModel(
      reactorUid: reactorUid,
      reactorUsername: reactorUsername,
      reactorDisplayName: reactorDisplayName,
      reactorPhotoUrl: reactorPhotoUrl,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    await _col(ownerUid).doc(reactorUid).set(reaction.toJson());
  }

  /// Elimina la reacción del usuario al perfil
  Future<void> unreact({
    required String ownerUid,
    required String reactorUid,
  }) async {
    await _col(ownerUid).doc(reactorUid).delete();
  }

  /// Stream de todas las reacciones de un perfil (para la pantalla de perfil público)
  Stream<List<ReactionModel>> watchReactionsForProfile(String ownerUid) {
    return _col(ownerUid).snapshots().map(
          (snap) => snap.docs
              .map((d) => ReactionModel.fromFirestore(d.data()))
              .toList(),
        );
  }

  /// Stream de reacciones recibidas por el propio usuario (para el listener en MainShell)
  Stream<List<ReactionModel>> watchMyReceivedReactions(String myUid) {
    return _col(myUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReactionModel.fromFirestore(d.data()))
              .toList(),
        );
  }
}
