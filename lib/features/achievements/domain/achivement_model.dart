import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  // tipos de logros
  static const String firstHabit = 'first_habit';
  static const String streak3 = 'streak_3';
  static const String streak7 = 'streak_7';
  static const String streak14 = 'streak_14';
  static const String streak30 = 'streak_30';
  static const String aiPlan = 'ai_plan';
  static const String allCompleted = 'all_completed_day';
  static const String habits5 = 'habits_5';
  static const String total50 = 'total_50';
  static const String total100 = 'total_100';
  static const String perfectWeek = 'perfect_week';
  static const String challengeCompleted = 'challenge_completed';
}

// catalogo con la info visual de cada logro
class AchievementCatalog {
  static const List<AchievementInfo> all = [
    AchievementInfo(
      type: AchievementModel.firstHabit,
      title: 'Primer paso',
      description: 'Crea tu primer habito',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF38BDF8),
    ),
    AchievementInfo(
      type: AchievementModel.aiPlan,
      title: 'Asistente personal',
      description: 'Genera un plan con la IA',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF8B5CF6),
    ),
    AchievementInfo(
      type: AchievementModel.allCompleted,
      title: 'Dia perfecto',
      description: 'Completa todos los habitos del dia',
      icon: Icons.stars_rounded,
      color: Color(0xFF10B981),
    ),
    AchievementInfo(
      type: AchievementModel.streak3,
      title: 'En marcha',
      description: 'Consigue una racha de 3 dias',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFF97316),
    ),
    AchievementInfo(
      type: AchievementModel.streak7,
      title: 'Semana de fuego',
      description: 'Consigue una racha de 7 dias',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF59E0B),
    ),
    AchievementInfo(
      type: AchievementModel.streak14,
      title: 'Imparable',
      description: 'Consigue una racha de 14 dias',
      icon: Icons.bolt_rounded,
      color: Color(0xFFEF4444),
    ),
    AchievementInfo(
      type: AchievementModel.streak30,
      title: 'Leyenda',
      description: 'Consigue una racha de 30 dias',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFEAB308),
    ),
    AchievementInfo(
      type: AchievementModel.habits5,
      title: 'Cinco en accion',
      description: 'Ten 5 habitos activos',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF0EA5E9),
    ),
    AchievementInfo(
      type: AchievementModel.total50,
      title: 'Medio centenar',
      description: 'Completa 50 check-ins en total',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF14B8A6),
    ),
    AchievementInfo(
      type: AchievementModel.total100,
      title: 'Centenario',
      description: 'Completa 100 check-ins en total',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFD97706),
    ),
    AchievementInfo(
      type: AchievementModel.perfectWeek,
      title: 'Semana impecable',
      description: '7 dias seguidos completando todo',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFEC4899),
    ),
    AchievementInfo(
      type: AchievementModel.challengeCompleted,
      title: 'Compañeros de reto',
      description: 'Completa un reto compartido',
      icon: Icons.handshake_rounded,
      color: Color(0xFF6366F1),
    ),
  ];

  static AchievementInfo getInfo(String type) {
    return all.firstWhere(
      (a) => a.type == type,
      orElse: () => AchievementInfo(
        type: type,
        title: type,
        description: '',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
      ),
    );
  }
}

// info visual de un tipo de logro
class AchievementInfo {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementInfo({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
