import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_group_model.dart';

// CRUD de grupos de habitos en Firestore
class HabitGroupRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HabitGroupRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('users').doc(_uid).collection('habit_groups');

  // todos los grupos activos en tiempo real
  // solo orderBy para evitar indice compuesto, filtramos isActive en cliente
  Stream<List<HabitGroupModel>> watchGroups() {
    return _groupsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitGroupModel.fromJson(doc.data(), doc.id))
            .where((g) => g.isActive)
            .toList());
  }

  // observar un grupo concreto en tiempo real
  Stream<HabitGroupModel?> watchGroup(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HabitGroupModel.fromJson(doc.data()!, doc.id);
    });
  }

  // crear grupo y devolver su ID
  Future<String> createGroup(HabitGroupModel group) async {
    final docRef = await _groupsRef.add(group.toJson());
    return docRef.id;
  }

  // actualizar titulo, emoji, etc
  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    await _groupsRef.doc(groupId).update(data);
  }

  // actualizar el contador de habitos del grupo
  Future<void> updateHabitCount(String groupId, int count) async {
    await _groupsRef.doc(groupId).update({'habitCount': count});
  }

  // incrementar o decrementar el contador
  Future<void> incrementHabitCount(String groupId, int delta) async {
    await _groupsRef.doc(groupId).update({
      'habitCount': FieldValue.increment(delta),
    });
  }

  // desactivar grupo (los habitos pasan a sin grupo)
  Future<void> deleteGroup(String groupId) async {
    final batch = _firestore.batch();

    // desactivar el grupo
    batch.update(_groupsRef.doc(groupId), {'isActive': false});

    // quitar el groupId de los habitos del grupo
    final habitsRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('habits');
    final habitsSnapshot = await habitsRef
        .where('groupId', isEqualTo: groupId)
        .get();

    for (final doc in habitsSnapshot.docs) {
      batch.update(doc.reference, {'groupId': null});
    }

    await batch.commit();
  }

  // desactivar grupo Y desactivar todos sus habitos
  Future<void> deleteGroupAndHabits(String groupId) async {
    final batch = _firestore.batch();

    batch.update(_groupsRef.doc(groupId), {'isActive': false});

    final habitsRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('habits');
    final habitsSnapshot = await habitsRef
        .where('groupId', isEqualTo: groupId)
        .get();

    for (final doc in habitsSnapshot.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    await batch.commit();
  }
}
