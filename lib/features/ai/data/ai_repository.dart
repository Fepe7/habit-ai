import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/habit_plan_model.dart';

// Llama a la Cloud Function proxy y guarda las conversaciones en Firestore
class AIRepository {
  final FirebaseFirestore _firestore;
  final String _uid;
  final HttpsCallable _generatePlanFn;

  // Historial del chat para mantener contexto entre mensajes
  final List<Map<String, String>> _chatHistory = [];

  AIRepository({
    required String uid,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _generatePlanFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generateHabitPlan');

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('users').doc(_uid).collection('ai_conversations');

  // Envia un mensaje a la Cloud Function y devuelve la respuesta parseada
  Future<HabitPlanModel> generatePlan(String userMessage) async {
    try {
      final result = await _generatePlanFn.call({
        'message': userMessage,
        'history': _chatHistory,
      });

      // Firebase devuelve Map<Object?, Object?>, hay que convertirlo recursivamente
      final data = _deepCast(result.data);
      final text = data['text'] as String? ?? '';
      final planJson = data['plan'] as Map<String, dynamic>?;

      // Guardar en el historial para mantener contexto
      _chatHistory.add({'role': 'user', 'text': userMessage});
      _chatHistory.add({'role': 'model', 'text': text});

      if (planJson != null) {
        final plan = HabitPlanModel.fromJson(planJson);

        await saveConversation(
          userMessage: userMessage,
          aiResponse: text,
          generatedHabits: plan.habits
              .map((h) => {
                    'title': h.title,
                    'category': h.category,
                    'frequency': h.frequency,
                  })
              .toList(),
        );

        return plan;
      }

      // Si la Cloud Function no pudo parsear JSON
      await saveConversation(
        userMessage: userMessage,
        aiResponse: text,
      );

      return HabitPlanModel(
        planTitle: 'Respuesta del asistente',
        planDescription: '',
        habits: [],
        coachMessage: text,
      );
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  // Reiniciar chat
  void resetChat() {
    _chatHistory.clear();
  }

  // Traduce errores de la Cloud Function a mensajes legibles
  String _mapError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
      case 'resource-exhausted':
        return 'Has hecho demasiadas peticiones. Espera unos minutos.';
      case 'invalid-argument':
        return 'El mensaje no puede estar vacío.';
      default:
        return 'Error del asistente. Inténtalo más tarde.';
    }
  }

  // Guardar conversacion en Firestore (inmutable)
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

  // Ultimas conversaciones para contexto
  Future<List<Map<String, dynamic>>> getRecentConversations({
    int limit = 5,
  }) async {
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

  // Convierte recursivamente Map<Object?, Object?> a Map<String, dynamic>
  // Firebase Functions devuelve tipos genéricos que Dart no castea automaticamente
  static Map<String, dynamic> _deepCast(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), _deepCastValue(v)),
      );
    }
    return {};
  }

  static dynamic _deepCastValue(dynamic value) {
    if (value is Map) {
      return _deepCast(value);
    } else if (value is List) {
      return value.map(_deepCastValue).toList();
    }
    return value;
  }
}
