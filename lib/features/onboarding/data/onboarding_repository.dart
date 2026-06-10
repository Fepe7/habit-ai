import 'package:cloud_firestore/cloud_firestore.dart';

// Lee y marca el estado del onboarding en users/{uid}
class OnboardingRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  OnboardingRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_uid);

  // Doc inexistente = registro recién hecho cuyo _ensureUserDoc aún no
  // terminó de escribir (carrera en el primer arranque) → mostrar onboarding.
  // Solo un error de red se trata como completado para no bloquear el acceso.
  Future<bool> isCompleted() async {
    final snap = await _userRef.get();
    if (!snap.exists) return false;
    return snap.data()?['onboardingCompleted'] as bool? ?? false;
  }

  // Marca el onboarding como completado y guarda las áreas elegidas
  // (las áreas sirven de contexto para futuras features de personalización).
  // set+merge por si el doc del usuario aún no existe (misma carrera de arriba)
  Future<void> markCompleted({List<String>? goals}) async {
    await _userRef.set(
      {
        'onboardingCompleted': true,
        if (goals != null && goals.isNotEmpty) 'onboardingGoals': goals,
      },
      SetOptions(merge: true),
    );
  }
}
