import 'package:cloud_firestore/cloud_firestore.dart';
import '../../habits/domain/habit_group_model.dart';
import '../../habits/domain/habit_model.dart';
import '../../habits/data/habit_group_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../domain/community_template_model.dart';
import '../domain/template_habit_snapshot.dart';

enum TemplateSort { popular, recent }

// Repositorio para el marketplace de plantillas de la comunidad.
// Coleccion global: community_templates/{templateId}/habits/{habitId}
class CommunityTemplateRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  CommunityTemplateRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('community_templates');

  // ==================== PUBLICAR / DESPUBLICAR ====================

  /// Publica un grupo como plantilla. Crea el doc de metadata + snapshots
  /// de los habitos en la subcoleccion. Devuelve el templateId.
  Future<String> publishTemplate({
    required HabitGroupModel group,
    required List<HabitModel> habits,
    required String authorUsername,
    required String authorDisplayName,
    required String description,
    String? authorPhotoUrl,
  }) async {
    final now = DateTime.now();

    // calcular categoria dominante contando frecuencias
    final categoryCount = <String, int>{};
    for (final h in habits) {
      categoryCount[h.category] = (categoryCount[h.category] ?? 0) + 1;
    }
    final dominantCategory = categoryCount.isEmpty
        ? 'productividad'
        : (categoryCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    final template = CommunityTemplateModel(
      id: '',
      authorUid: _uid,
      authorUsername: authorUsername,
      authorDisplayName: authorDisplayName,
      title: group.title,
      emoji: group.emoji,
      description: description,
      category: dominantCategory,
      habitCount: habits.length,
      createdAt: now,
      updatedAt: now,
      authorPhotoUrl: authorPhotoUrl,
    );

    // batch: crear plantilla + snapshots de habitos
    final batch = _firestore.batch();
    final templateRef = _templatesRef.doc();

    batch.set(templateRef, template.toJson());

    for (final habit in habits) {
      final snap = TemplateHabitSnapshot(
        id: '',
        title: habit.title,
        description: habit.description,
        category: habit.category,
        frequency: habit.frequency,
        targetDays: habit.targetDays,
        reminderTime: habit.reminderTime,
      );
      final snapRef = templateRef.collection('habits').doc();
      batch.set(snapRef, snap.toJson());
    }

    // marcar el grupo origen con el templateId
    final groupRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('habit_groups')
        .doc(group.id);
    batch.update(groupRef, {'publishedTemplateId': templateRef.id});

    await batch.commit();
    return templateRef.id;
  }

  /// Despublica una plantilla: borra la subcoleccion de habitos + el doc
  /// y limpia el publishedTemplateId en el grupo origen.
  Future<void> unpublishTemplate({
    required String templateId,
    required String sourceGroupId,
  }) async {
    // borrar habitos de la subcoleccion
    final habitsSnap =
        await _templatesRef.doc(templateId).collection('habits').get();

    final batch = _firestore.batch();

    for (final doc in habitsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_templatesRef.doc(templateId));

    // limpiar referencia en el grupo
    final groupRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('habit_groups')
        .doc(sourceGroupId);
    batch.update(groupRef, {'publishedTemplateId': FieldValue.delete()});

    await batch.commit();
  }

  // ==================== LEER FEED ====================

  /// Feed paginado ordenado por importCount (popular) o createdAt (reciente).
  /// Filtramos por categoria en cliente para evitar indice compuesto.
  Future<({List<CommunityTemplateModel> templates, DocumentSnapshot? lastDoc})>
      fetchTemplatePage({
    String? category,
    TemplateSort sort = TemplateSort.popular,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _templatesRef;

    switch (sort) {
      case TemplateSort.popular:
        query = query.orderBy('importCount', descending: true);
      case TemplateSort.recent:
        query = query.orderBy('createdAt', descending: true);
    }

    query = query.limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    var templates = snapshot.docs
        .map((doc) => CommunityTemplateModel.fromJson(doc.data(), doc.id))
        .toList();

    // filtro client-side por categoria
    if (category != null && category.isNotEmpty) {
      templates = templates.where((t) => t.category == category).toList();
    }

    return (
      templates: templates,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  // ==================== DETALLE ====================

  Future<CommunityTemplateModel?> getTemplate(String templateId) async {
    final doc = await _templatesRef.doc(templateId).get();
    if (!doc.exists) return null;
    return CommunityTemplateModel.fromJson(doc.data()!, doc.id);
  }

  Future<List<TemplateHabitSnapshot>> getTemplateHabits(
      String templateId) async {
    final snap =
        await _templatesRef.doc(templateId).collection('habits').get();
    return snap.docs
        .map((doc) => TemplateHabitSnapshot.fromJson(doc.data(), doc.id))
        .toList();
  }

  // ==================== IMPORTAR ====================

  /// Importa una plantilla: crea un grupo + habitos en la cuenta del usuario.
  /// Devuelve el nuevo groupId.
  Future<String> importTemplate({
    required CommunityTemplateModel template,
    required List<TemplateHabitSnapshot> habits,
  }) async {
    // patron identico al de ai_screen.dart:150-175
    final groupRepo = HabitGroupRepository(uid: _uid);
    final habitRepo = HabitRepository(uid: _uid);

    final group = HabitGroupModel(
      id: '',
      title: template.title,
      emoji: template.emoji,
      createdAt: DateTime.now(),
      habitCount: habits.length,
    );
    final groupId = await groupRepo.createGroup(group);

    final habitModels = habits
        .map((snap) => HabitModel(
              id: '',
              title: snap.title,
              description: snap.description,
              category: snap.category,
              frequency: snap.frequency,
              targetDays: snap.targetDays,
              reminderTime: snap.reminderTime,
              isAIGenerated: false,
              createdAt: DateTime.now(),
            ))
        .toList();

    await habitRepo.createHabitsInGroup(habitModels, groupId);

    // incrementar contador best-effort (no bloquea si falla)
    _incrementImportCount(template.id);

    return groupId;
  }

  // incremento atomico del contador — se llama sin await para no bloquear UI
  void _incrementImportCount(String templateId) {
    _templatesRef.doc(templateId).update({
      'importCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }).catchError((_) {}); // ignorar errores de red en el contador
  }

  // ==================== REPORTAR ====================

  /// Incrementa el contador de reportes (stub MVP).
  Future<void> reportTemplate(String templateId) async {
    await _templatesRef.doc(templateId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ==================== VERIFICAR AUTORIA ====================

  /// Devuelve true si el templateId fue publicado por el usuario actual.
  Future<bool> isMyTemplate(String templateId) async {
    final doc = await _templatesRef.doc(templateId).get();
    if (!doc.exists) return false;
    return doc.data()?['authorUid'] == _uid;
  }

  // leer perfiles publicos para el autor — evita username obsoleto en el detalle
  Future<Map<String, dynamic>?> getAuthorPublicProfile(
      String authorUid) async {
    final doc =
        await _firestore.collection('public_profiles').doc(authorUid).get();
    return doc.exists ? doc.data() : null;
  }

  // verificar si existe la cuenta del autor (para manejar cuentas eliminadas)
  String get currentUid => _uid;
}
