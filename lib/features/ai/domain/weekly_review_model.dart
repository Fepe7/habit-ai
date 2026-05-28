import 'package:cloud_firestore/cloud_firestore.dart';

// Revision semanal generada por la IA a partir de los logs del usuario
class WeeklyReviewModel {
  final String weekId;
  final DateTime generatedAt;
  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyReviewStats stats;
  final List<String> wins;
  final List<String> struggles;
  final List<ReviewRecommendation> recommendations;
  final String focus;
  final String? moodInsights;

  const WeeklyReviewModel({
    required this.weekId,
    required this.generatedAt,
    required this.weekStart,
    required this.weekEnd,
    required this.stats,
    required this.wins,
    required this.struggles,
    required this.recommendations,
    required this.focus,
    this.moodInsights,
  });

  factory WeeklyReviewModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewModel(
      weekId: json['weekId'] as String,
      generatedAt: (json['generatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      weekStart: (json['weekStart'] as Timestamp).toDate(),
      weekEnd: (json['weekEnd'] as Timestamp).toDate(),
      stats: WeeklyReviewStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      ),
      wins: List<String>.from(json['wins'] ?? []),
      struggles: List<String>.from(json['struggles'] ?? []),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) =>
              ReviewRecommendation.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
      focus: json['focus'] as String? ?? '',
      moodInsights: json['moodInsights'] as String?,
    );
  }
}

class WeeklyReviewStats {
  final int totalLogs;
  final int totalHabits;
  final String? bestHabit;
  final List<String> habitsAtRisk;

  const WeeklyReviewStats({
    required this.totalLogs,
    required this.totalHabits,
    this.bestHabit,
    required this.habitsAtRisk,
  });

  factory WeeklyReviewStats.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewStats(
      totalLogs: json['totalLogs'] as int? ?? 0,
      totalHabits: json['totalHabits'] as int? ?? 0,
      bestHabit: json['bestHabit'] as String?,
      habitsAtRisk: List<String>.from(json['habitsAtRisk'] ?? []),
    );
  }
}

// Recomendacion concreta sobre un habito especifico
class ReviewRecommendation {
  final String habitId;
  final String habitTitle;
  final String action;
  final String reason;

  const ReviewRecommendation({
    required this.habitId,
    required this.habitTitle,
    required this.action,
    required this.reason,
  });

  factory ReviewRecommendation.fromJson(Map<String, dynamic> json) {
    return ReviewRecommendation(
      habitId: json['habitId'] as String? ?? '',
      habitTitle: json['habitTitle'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
