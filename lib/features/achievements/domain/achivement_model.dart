import 'package:cloud_firestore/cloud_firestore.dart';

// Logro del usuario (inmutable, una vez desbloqueado no se toca)
class AchievementModel {
  final String id;
  final String type;
  final DateTime unlockedAt;
  final String? habitId;

  const AchievementModel({
    required this.id,
    required this.type,
    required this.unlockedAt,
    this.habitId,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json, String docId) {
    return AchievementModel(
      id: docId,
      type: json['type'] as String,
      unlockedAt: (json['unlockedAt'] as Timestamp).toDate(),
      habitId: json['habitId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'habitId': habitId,
    };
  }

  // Tipos de logros
  static const String firstHabit = 'first_habit';
  static const String streak7 = 'streak_7';
  static const String streak30 = 'streak_30';
  static const String aiPlan = 'ai_plan';
  static const String allCompleted = 'all_completed_day';
}