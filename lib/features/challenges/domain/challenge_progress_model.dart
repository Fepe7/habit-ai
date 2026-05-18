import 'package:cloud_firestore/cloud_firestore.dart';

enum DayStatus { pending, completed, missed, shielded }

// Progreso de un participante en un reto
class ChallengeProgressModel {
  final String uid;
  final Map<int, DayStatus> days;
  final int completedCount;
  final int currentStreak;
  final DateTime updatedAt;

  const ChallengeProgressModel({
    required this.uid,
    required this.days,
    required this.completedCount,
    required this.currentStreak,
    required this.updatedAt,
  });

  factory ChallengeProgressModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as Map<String, dynamic>? ?? {};
    final days = rawDays.map(
      (key, value) => MapEntry(
        int.parse(key),
        DayStatus.values.firstWhere(
          (s) => s.name == value,
          orElse: () => DayStatus.pending,
        ),
      ),
    );

    return ChallengeProgressModel(
      uid: json['uid'] as String,
      days: days,
      completedCount: json['completedCount'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'days': days.map((key, value) => MapEntry(key.toString(), value.name)),
      'completedCount': completedCount,
      'currentStreak': currentStreak,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChallengeProgressModel copyWith({
    Map<int, DayStatus>? days,
    int? completedCount,
    int? currentStreak,
    DateTime? updatedAt,
  }) {
    return ChallengeProgressModel(
      uid: uid,
      days: days ?? this.days,
      completedCount: completedCount ?? this.completedCount,
      currentStreak: currentStreak ?? this.currentStreak,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
