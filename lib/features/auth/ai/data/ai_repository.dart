import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_plan_model.dart';

/// Repositorio que gestiona las conversaciones con la IA.
/// Por ahora solo guarda y lee conversaciones en Firestore.
/// La llamada a Cloud Functions se implementará cuando activemos el plan Blaze.
class AIRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  AIRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('users').doc(_uid).collection('ai_conversations');

  /// Guarda una conversación con la IA en Firestore.
  /// Las conversaciones son inmutables: no se editan ni borran.
  Future<String> saveConversation({
    required String userMessage,
    required String aiResponse,
    List<Map<String, dynamic>>? generatedHabits,
  }) async {
    final docRef = await _conversationsRef.add({
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'userMessage': userMessage,
      'aiResponse': aiResponse,
      'generatedHabits': generatedHabits ?? [],
    });
    return docRef.id;
  }

  /// Stream reactivo del historial de conversaciones.
  /// Ordenado por fecha, las más recientes primero.
  Stream<List<Map<String, dynamic>>> watchConversations() {
    return _conversationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  /// Obtener las últimas N conversaciones para enviar como contexto a la IA.
  /// Así la IA sabe qué le recomendó antes al usuario.
  Future<List<Map<String, dynamic>>> getRecentConversations({
    int limit = 5,
  }) async {
    // EFICIENCIA: limit evita descargar todo el historial
    final snapshot = await _conversationsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList();
  }
}