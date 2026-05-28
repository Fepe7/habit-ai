import 'package:cloud_firestore/cloud_firestore.dart';

// Registro de estado de ánimo en un momento del día
class MoodEntryModel {
  final String id;
  final int rating; // 1-5
  final List<String> labels;
  final String? note;
  final String timeBlock; // morning | midday | afternoon | night
  final DateTime timestamp;
  final List<String> habitsCompletedSnapshot;

  const MoodEntryModel({
    required this.id,
    required this.rating,
    required this.labels,
    this.note,
    required this.timeBlock,
    required this.timestamp,
    this.habitsCompletedSnapshot = const [],
  });

  String get emoji {
    switch (rating) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  // Detecta el bloque horario según la hora del día
  static String timeBlockFromHour(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 15) return 'midday';
    if (hour >= 15 && hour < 21) return 'afternoon';
    return 'night';
  }

  factory MoodEntryModel.fromJson(Map<String, dynamic> json, String docId) {
    return MoodEntryModel(
      id: docId,
      rating: json['rating'] as int? ?? 3,
      labels: List<String>.from(json['labels'] ?? []),
      note: json['note'] as String?,
      timeBlock: json['timeBlock'] as String? ?? 'morning',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      habitsCompletedSnapshot:
          List<String>.from(json['habitsCompletedSnapshot'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'labels': labels,
      'note': note,
      'timeBlock': timeBlock,
      'timestamp': Timestamp.fromDate(timestamp),
      'habitsCompletedSnapshot': habitsCompletedSnapshot,
    };
  }

  MoodEntryModel copyWith({
    int? rating,
    List<String>? labels,
    String? note,
    bool clearNote = false,
    String? timeBlock,
    DateTime? timestamp,
    List<String>? habitsCompletedSnapshot,
  }) {
    return MoodEntryModel(
      id: id,
      rating: rating ?? this.rating,
      labels: labels ?? this.labels,
      note: clearNote ? null : (note ?? this.note),
      timeBlock: timeBlock ?? this.timeBlock,
      timestamp: timestamp ?? this.timestamp,
      habitsCompletedSnapshot:
          habitsCompletedSnapshot ?? this.habitsCompletedSnapshot,
    );
  }
}
