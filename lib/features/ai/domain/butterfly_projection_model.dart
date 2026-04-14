import 'package:cloud_firestore/cloud_firestore.dart';

// Proyección de vida a 3 años generada por IA — escenario positivo y negativo
class ButterflyProjectionModel {
  final String monthId;
  final DateTime generatedAt;
  final DateTime monthStart;
  final DateTime monthEnd;
  final ButterflyStats stats;
  final String titleKeep;
  final String storyKeep;
  final String titleAbandon;
  final String storyAbandon;
  final List<ButterflyKeyMoment> keyMoments;
  final String closingMessage;

  const ButterflyProjectionModel({
    required this.monthId,
    required this.generatedAt,
    required this.monthStart,
    required this.monthEnd,
    required this.stats,
    required this.titleKeep,
    required this.storyKeep,
    required this.titleAbandon,
    required this.storyAbandon,
    required this.keyMoments,
    required this.closingMessage,
  });

  factory ButterflyProjectionModel.fromJson(Map<String, dynamic> json) {
    return ButterflyProjectionModel(
      monthId: json['monthId'] as String,
      generatedAt:
          (json['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monthStart: (json['monthStart'] as Timestamp).toDate(),
      monthEnd: (json['monthEnd'] as Timestamp).toDate(),
      stats: ButterflyStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      ),
      titleKeep: json['titleKeep'] as String? ?? '',
      storyKeep: json['storyKeep'] as String? ?? '',
      titleAbandon: json['titleAbandon'] as String? ?? '',
      storyAbandon: json['storyAbandon'] as String? ?? '',
      keyMoments: (json['keyMoments'] as List? ?? [])
          .map((k) =>
              ButterflyKeyMoment.fromJson(Map<String, dynamic>.from(k as Map)))
          .toList(),
      closingMessage: json['closingMessage'] as String? ?? '',
    );
  }
}

// Estadísticas del mes que sirvieron de base para la proyección
class ButterflyStats {
  final int totalLogs;
  final int activeHabits;
  final double completionRate;
  final List<String> topCategories;
  final int longestStreak;

  const ButterflyStats({
    required this.totalLogs,
    required this.activeHabits,
    required this.completionRate,
    required this.topCategories,
    required this.longestStreak,
  });

  factory ButterflyStats.fromJson(Map<String, dynamic> json) {
    return ButterflyStats(
      totalLogs: json['totalLogs'] as int? ?? 0,
      activeHabits: json['activeHabits'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      topCategories: List<String>.from(json['topCategories'] ?? []),
      longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }
}

// Hito concreto que marca la diferencia entre los dos escenarios
class ButterflyKeyMoment {
  final String habitTitle;
  final String impact;

  const ButterflyKeyMoment({
    required this.habitTitle,
    required this.impact,
  });

  factory ButterflyKeyMoment.fromJson(Map<String, dynamic> json) {
    return ButterflyKeyMoment(
      habitTitle: json['habitTitle'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
    );
  }
}
