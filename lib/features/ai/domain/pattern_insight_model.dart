import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Resultado del análisis de patrones cruzados entre hábitos, generado por Gemini
class PatternInsightModel {
  final String periodId;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final PatternInsightStats stats;
  final List<PatternInsight> insights;
  final String summary;
  final String dataQuality; // "good" | "limited"

  const PatternInsightModel({
    required this.periodId,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.stats,
    required this.insights,
    required this.summary,
    required this.dataQuality,
  });

  factory PatternInsightModel.fromJson(Map<String, dynamic> json) {
    return PatternInsightModel(
      periodId: json['periodId'] as String,
      generatedAt:
          (json['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodStart: (json['periodStart'] as Timestamp).toDate(),
      periodEnd: (json['periodEnd'] as Timestamp).toDate(),
      stats: PatternInsightStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      ),
      insights: (json['insights'] as List? ?? [])
          .map((i) =>
              PatternInsight.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      summary: json['summary'] as String? ?? '',
      dataQuality: json['dataQuality'] as String? ?? 'limited',
    );
  }
}

// Estadísticas del período analizado
class PatternInsightStats {
  final int totalHabits;
  final int totalLogs;
  final int analyzedDays;

  const PatternInsightStats({
    required this.totalHabits,
    required this.totalLogs,
    required this.analyzedDays,
  });

  factory PatternInsightStats.fromJson(Map<String, dynamic> json) {
    return PatternInsightStats(
      totalHabits: json['totalHabits'] as int? ?? 0,
      totalLogs: json['totalLogs'] as int? ?? 0,
      analyzedDays: json['analyzedDays'] as int? ?? 0,
    );
  }
}

// Tipo de patrón detectado por la IA
enum PatternType {
  dayEffect,
  crossHabit,
  timeCluster,
  categorySynergy,
  streakPredictor,
  vulnerability;

  static PatternType fromString(String value) {
    switch (value) {
      case 'day_effect':
        return PatternType.dayEffect;
      case 'cross_habit':
        return PatternType.crossHabit;
      case 'time_cluster':
        return PatternType.timeCluster;
      case 'category_synergy':
        return PatternType.categorySynergy;
      case 'streak_predictor':
        return PatternType.streakPredictor;
      case 'vulnerability':
        return PatternType.vulnerability;
      default:
        return PatternType.crossHabit;
    }
  }

  String get label {
    switch (this) {
      case PatternType.dayEffect:
        return 'Día de semana';
      case PatternType.crossHabit:
        return 'Correlación';
      case PatternType.timeCluster:
        return 'Horario';
      case PatternType.categorySynergy:
        return 'Sinergia';
      case PatternType.streakPredictor:
        return 'Predictor';
      case PatternType.vulnerability:
        return 'Vulnerabilidad';
    }
  }

  IconData get icon {
    switch (this) {
      case PatternType.dayEffect:
        return Icons.calendar_today_rounded;
      case PatternType.crossHabit:
        return Icons.link_rounded;
      case PatternType.timeCluster:
        return Icons.schedule_rounded;
      case PatternType.categorySynergy:
        return Icons.bubble_chart_rounded;
      case PatternType.streakPredictor:
        return Icons.local_fire_department_rounded;
      case PatternType.vulnerability:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PatternType.dayEffect:
        return const Color(0xFF6366F1); // indigo
      case PatternType.crossHabit:
        return const Color(0xFF0EA5E9); // sky
      case PatternType.timeCluster:
        return const Color(0xFF10B981); // emerald
      case PatternType.categorySynergy:
        return const Color(0xFF8B5CF6); // violet
      case PatternType.streakPredictor:
        return const Color(0xFFF59E0B); // amber
      case PatternType.vulnerability:
        return const Color(0xFFEF4444); // red
    }
  }
}

// Un insight concreto detectado por la IA
class PatternInsight {
  final PatternType type;
  final String title;
  final String description;
  final List<String> relatedHabits;
  final String confidence; // "high" | "medium" | "low"
  final String actionable;

  const PatternInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.relatedHabits,
    required this.confidence,
    required this.actionable,
  });

  factory PatternInsight.fromJson(Map<String, dynamic> json) {
    return PatternInsight(
      type: PatternType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      relatedHabits: List<String>.from(json['relatedHabits'] ?? []),
      confidence: json['confidence'] as String? ?? 'medium',
      actionable: json['actionable'] as String? ?? '',
    );
  }

  // Color del dot de confianza
  Color get confidenceColor {
    switch (confidence) {
      case 'high':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
