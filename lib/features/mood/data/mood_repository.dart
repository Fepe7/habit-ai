import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/mood_entry_model.dart';

// CRUD de registros de estado de ánimo en Firestore
class MoodRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  MoodRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _moodRef =>
      _firestore.collection('users').doc(_uid).collection('mood_entries');

  // Registros de hoy en tiempo real
  Stream<List<MoodEntryModel>> watchTodayEntries() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _moodRef
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MoodEntryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Registros de un mes en tiempo real (para heatmap)
  Stream<List<MoodEntryModel>> watchEntriesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return _moodRef
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MoodEntryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Registros en un rango de fechas (para gráficas)
  Future<List<MoodEntryModel>> getEntriesForRange(
      DateTime start, DateTime end) async {
    final snap = await _moodRef
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: false)
        .get();

    return snap.docs
        .map((doc) => MoodEntryModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Media de ánimo de un día concreto
  Future<double?> getAverageForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final entries = await getEntriesForRange(start, end);
    if (entries.isEmpty) return null;
    final sum = entries.fold<int>(0, (acc, e) => acc + e.rating);
    return sum / entries.length;
  }

  // Crear nuevo registro
  Future<String> createEntry(MoodEntryModel entry) async {
    final doc = await _moodRef.add(entry.toJson());
    return doc.id;
  }

  // Borrar registro
  Future<void> deleteEntry(String entryId) async {
    await _moodRef.doc(entryId).delete();
  }

  // días consecutivos con al menos una entrada (hacia atrás desde hoy)
  Future<int> getMoodStreak() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 60));
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    final entries = await getEntriesForRange(start, end);
    if (entries.isEmpty) return 0;

    final daysWithEntries = <int>{};
    for (final e in entries) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      daysWithEntries.add(d.millisecondsSinceEpoch);
    }

    int streak = 0;
    var day = DateTime(now.year, now.month, now.day);
    while (daysWithEntries.contains(day.millisecondsSinceEpoch)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
