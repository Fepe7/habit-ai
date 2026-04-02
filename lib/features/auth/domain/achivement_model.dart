import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un logro desbloqueado por el usuario.
/// Los logros son inmutables: una vez desbloqueados no se editan ni borran.
/// Esto se refuerza en las reglas de seguridad de Firestore (solo read + create).
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

  /// Tipos de logros disponibles en la app.
  /// Se definen como constantes para evitar errores de typo.
  static const String firstHabit = 'first_habit';
  static const String streak7 = 'streak_7';
  static const String streak30 = 'streak_30';
  static const String aiPlan = 'ai_plan';
  static const String allCompleted = 'all_completed_day';
}