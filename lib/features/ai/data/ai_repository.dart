import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/l10n/locale_provider.dart';
import '../domain/habit_plan_model.dart';
import '../domain/weekly_review_model.dart';
import '../domain/butterfly_projection_model.dart';
import '../domain/renegotiation_model.dart';
import '../domain/pattern_insight_model.dart';

// Llama a la Cloud Function proxy y guarda las conversaciones en Firestore
class AIRepository {
  final FirebaseFirestore _firestore;
  final String _uid;
  final HttpsCallable _generatePlanFn;
  final HttpsCallable _generateWeeklyReviewFn;

  // Historial del chat para mantener contexto entre mensajes
  final List<Map<String, String>> _chatHistory = [];

  // El locale se lee de LocaleProvider.currentCode — sin necesidad de context

  final HttpsCallable _generateButterflyFn;
  final HttpsCallable _generateRenegotiationFn;
  final HttpsCallable _generatePatternInsightsFn;

  AIRepository({
    required String uid,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _generatePlanFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generateHabitPlan'),
        _generateWeeklyReviewFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generateWeeklyReview'),
        _generateButterflyFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generateButterflyProjection'),
        _generateRenegotiationFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generateRenegotiation'),
        _generatePatternInsightsFn = (functions ??
                FirebaseFunctions.instanceFor(region: 'europe-west1'))
            .httpsCallable('generatePatternInsights');

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('users').doc(_uid).collection('ai_conversations');

  CollectionReference<Map<String, dynamic>> get _weeklyReviewsRef =>
      _firestore.collection('users').doc(_uid).collection('weekly_reviews');

  CollectionReference<Map<String, dynamic>> get _butterflyRef =>
      _firestore.collection('users').doc(_uid).collection('butterfly_projections');

  CollectionReference<Map<String, dynamic>> get _renegotiationsRef =>
      _firestore.collection('users').doc(_uid).collection('renegotiations');

  CollectionReference<Map<String, dynamic>> get _patternInsightsRef =>
      _firestore.collection('users').doc(_uid).collection('pattern_insights');

  // Envia un mensaje a la Cloud Function y devuelve la respuesta parseada
  Future<HabitPlanModel> generatePlan(String userMessage) async {
    try {
      final result = await _generatePlanFn.call({
        'message': userMessage,
        'history': _chatHistory,
        'locale': LocaleProvider.currentCode,
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
      case 'unavailable':
        return 'El asistente de IA está en pausa temporal. El resto de la app funciona con normalidad.';
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
      // TTL de Firestore: las conversaciones se purgan a los 30 días
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'userMessage': userMessage,
      'aiResponse': aiResponse,
      'generatedHabits': generatedHabits ?? [],
    });
    return docRef.id;
  }

  // Historial de conversaciones en tiempo real (acotado: el historial completo
  // crecería sin fin y dispararía lecturas en cada reconexión del stream)
  Stream<List<Map<String, dynamic>>> watchConversations() {
    return _conversationsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
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

  // ==================== REVISION SEMANAL ====================

  // Fuerza la generacion de la revision de la semana anterior (boton manual).
  // Devuelve null si el backend decidio omitirla por falta de logs.
  Future<String?> generateWeeklyReview() async {
    try {
      final result = await _generateWeeklyReviewFn.call({'locale': LocaleProvider.currentCode});
      final data = _deepCast(result.data);
      if (data['skipped'] == true) return null;
      return data['weekId'] as String?;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  // Stream con la ultima revision generada (para el card del dashboard)
  Stream<WeeklyReviewModel?> watchLatestWeeklyReview() {
    return _weeklyReviewsRef
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WeeklyReviewModel.fromJson(snapshot.docs.first.data());
    });
  }

  // Lee una revision concreta por weekId (para la pantalla de detalle)
  Future<WeeklyReviewModel?> getReviewForWeek(String weekId) async {
    final doc = await _weeklyReviewsRef.doc(weekId).get();
    if (!doc.exists) return null;
    return WeeklyReviewModel.fromJson(doc.data()!);
  }

  // EFECTO MARIPOSA

  // Dispara la generación manual de la proyección del mes en curso
  // Devuelve null si no hay suficientes logs (< 10
  Future<String?> generateButterflyProjection() async {
    try {
      final result = await _generateButterflyFn.call({'locale': LocaleProvider.currentCode});
      final data = _deepCast(result.data);
      if (data['skipped'] == true) return null;
      return data['monthId'] as String?;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  // Stream con la proyección más reciente (para el card del dashboard)
  Stream<ButterflyProjectionModel?> watchLatestButterfly() {
    return _butterflyRef
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ButterflyProjectionModel.fromJson(snapshot.docs.first.data());
    });
  }

  // Lee una proyección concreta por monthId (para la pantalla de detalle)
  Future<ButterflyProjectionModel?> getProjectionForMonth(
      String monthId) async {
    final doc = await _butterflyRef.doc(monthId).get();
    if (!doc.exists) return null;
    return ButterflyProjectionModel.fromJson(doc.data()!);
  }

  // ==================== RENEGOCIACION ====================

  // Dispara la generación manual de renegociación para un hábito concreto.
  // Devuelve null si la sugerencia se generó correctamente, o la razón si se omitió.
  Future<String?> generateRenegotiation(String habitId) async {
    try {
      final result = await _generateRenegotiationFn.call({'habitId': habitId, 'locale': LocaleProvider.currentCode});
      final data = _deepCast(result.data);
      if (data['skipped'] == true) return data['reason'] as String? ?? 'unknown';
      return null;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  // Stream de todas las renegociaciones pendientes (sin applied ni dismissed)
  Stream<List<RenegotiationModel>> watchActiveRenegotiations() {
    return _renegotiationsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RenegotiationModel.fromMap(doc.id, doc.data()))
        .where((r) => r.isPending)
        .toList());
  }

  // Stream de la renegociación pendiente de un hábito concreto (null si no hay)
  Stream<RenegotiationModel?> watchRenegotiationForHabit(String habitId) {
    return _renegotiationsRef.doc(habitId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final model = RenegotiationModel.fromMap(doc.id, doc.data()!);
      return model.isPending ? model : null;
    });
  }

  // Marca la renegociación como aplicada (el usuario aceptó el cambio)
  Future<void> markRenegotiationApplied(String habitId) async {
    await _renegotiationsRef.doc(habitId).update({
      'appliedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Descarta la renegociación sin aplicarla
  Future<void> dismissRenegotiation(String habitId) async {
    await _renegotiationsRef.doc(habitId).update({
      'dismissedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==================== DETECCION DE PATRONES ====================

  // Dispara la generación manual de insights de patrones del mes en curso.
  // Devuelve null si hay datos insuficientes (<14 días o <3 hábitos).
  Future<String?> generatePatternInsights() async {
    try {
      final result = await _generatePatternInsightsFn.call({'locale': LocaleProvider.currentCode});
      final data = _deepCast(result.data);
      if (data['skipped'] == true) return null;
      return data['periodId'] as String?;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  // Stream con los insights más recientes (para el card del dashboard)
  Stream<PatternInsightModel?> watchLatestPatternInsights() {
    return _patternInsightsRef
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return PatternInsightModel.fromJson(snapshot.docs.first.data());
    });
  }

  // Lee los insights de un período concreto por periodId (pantalla de detalle)
  Future<PatternInsightModel?> getInsightsForPeriod(String periodId) async {
    final doc = await _patternInsightsRef.doc(periodId).get();
    if (!doc.exists) return null;
    return PatternInsightModel.fromJson(doc.data()!);
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
