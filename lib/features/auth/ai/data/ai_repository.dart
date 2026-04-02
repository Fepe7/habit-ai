import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_plan_model.dart';

// Guarda y lee conversaciones con la IA en Firestore
// La parte de Cloud Functions se hara cuando tenga plan Blaze
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

  // Guardar conversacion (no se editan ni borran)
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

  // Historial de conversaciones en tiempo real
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

  // Ultimas conversaciones para pasar como contexto a la IA
  Future<List<Map<String, dynamic>>> getRecentConversations({
    int limit = 5,
  }) async {
    // limit para no bajar todo el historial
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