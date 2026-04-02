import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/habit_model.dart';

/// Plan completo de hábitos generado por la IA.
/// Contiene los hábitos sugeridos y un mensaje motivacional.
class HabitPlanModel {
  final String planTitle;
  final String planDescription;
  final List<GeneratedHabitModel> habits;
  final String coachMessage;

  const HabitPlanModel({
    required this.planTitle,
    required this.planDescription,
    required this.habits,
    required this.coachMessage,
  });

  factory HabitPlanModel.fromJson(Map<String, dynamic> json) {
    return HabitPlanModel(
      planTitle: json['planTitle'] as String? ?? 'Tu plan personalizado',
      planDescription: json['planDescription'] as String? ?? '',
      habits:
          (json['habits'] as List<dynamic>?)
              ?.map(
                (h) => GeneratedHabitModel.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
      coachMessage: json['coachMessage'] as String? ?? '',
    );
  }
}

/// Hábito individual generado por la IA, antes de guardarse en Firestore.
/// Tiene campos extra de IA (estimatedMinutes, difficultyLevel) que no se persisten.
class GeneratedHabitModel {
  final String title;
  final String description;
  final String category;
  final String frequency;
  final List<int> targetDays;
  final String? suggestedTime;
  final int estimatedMinutes;
  final String difficultyLevel;

  const GeneratedHabitModel({
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.suggestedTime,
    this.estimatedMinutes = 15,
    this.difficultyLevel = 'medium',
  });

  factory GeneratedHabitModel.fromJson(Map<String, dynamic> json) {
    return GeneratedHabitModel(
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'productividad',
      frequency: json['frequency'] as String? ?? 'daily',
      targetDays: List<int>.from(json['targetDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      suggestedTime: json['suggestedTime'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      difficultyLevel: json['difficultyLevel'] as String? ?? 'medium',
    );
  }

  /// Convierte a HabitModel para guardar en Firestore.
  /// Marca isAIGenerated = true para distinguir de hábitos manuales.
  HabitModel toHabitModel() {
    return HabitModel(
      id: '',
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      targetDays: targetDays,
      reminderTime: suggestedTime,
      isAIGenerated: true,
      createdAt: DateTime.now(),
    );
  }
}
