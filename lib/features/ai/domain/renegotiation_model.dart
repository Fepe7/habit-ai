import 'package:cloud_firestore/cloud_firestore.dart';

enum RenegotiationStrategy {
  lowerIntensity,
  changeTime,
  splitMicro,
  reduceFrequency;

  static RenegotiationStrategy fromString(String value) {
    switch (value) {
      case 'lower_intensity':
        return RenegotiationStrategy.lowerIntensity;
      case 'change_time':
        return RenegotiationStrategy.changeTime;
      case 'split_micro':
        return RenegotiationStrategy.splitMicro;
      case 'reduce_frequency':
        return RenegotiationStrategy.reduceFrequency;
      default:
        return RenegotiationStrategy.lowerIntensity;
    }
  }

  String get snakeCase {
    switch (this) {
      case RenegotiationStrategy.lowerIntensity:
        return 'lower_intensity';
      case RenegotiationStrategy.changeTime:
        return 'change_time';
      case RenegotiationStrategy.splitMicro:
        return 'split_micro';
      case RenegotiationStrategy.reduceFrequency:
        return 'reduce_frequency';
    }
  }

  String get label {
    switch (this) {
      case RenegotiationStrategy.lowerIntensity:
        return 'Bajar intensidad';
      case RenegotiationStrategy.changeTime:
        return 'Cambiar horario';
      case RenegotiationStrategy.splitMicro:
        return 'Dividir en micro-hábito';
      case RenegotiationStrategy.reduceFrequency:
        return 'Reducir frecuencia';
    }
  }
}

// Sugerencia de ajuste generada por la IA cuando el hábito lleva ≥3 días fallados
class RenegotiationModel {
  final String habitId;
  final String habitTitle;
  final DateTime generatedAt;
  final int missedDays;
  final String diagnosis;
  final RenegotiationStrategy strategy;
  final String suggestedTitle;
  final String? suggestedDescription;
  final String? suggestedReminderTime;
  final List<int>? suggestedTargetDays;
  final String encouragement;
  final DateTime? appliedAt;
  final DateTime? dismissedAt;

  const RenegotiationModel({
    required this.habitId,
    required this.habitTitle,
    required this.generatedAt,
    required this.missedDays,
    required this.diagnosis,
    required this.strategy,
    required this.suggestedTitle,
    this.suggestedDescription,
    this.suggestedReminderTime,
    this.suggestedTargetDays,
    required this.encouragement,
    this.appliedAt,
    this.dismissedAt,
  });

  bool get isPending => appliedAt == null && dismissedAt == null;

  factory RenegotiationModel.fromMap(String id, Map<String, dynamic> map) {
    return RenegotiationModel(
      habitId: id,
      habitTitle: map['habitTitle'] as String? ?? '',
      generatedAt:
          (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      missedDays: map['missedDays'] as int? ?? 0,
      diagnosis: map['diagnosis'] as String? ?? '',
      strategy: RenegotiationStrategy.fromString(
          map['strategy'] as String? ?? ''),
      suggestedTitle: map['suggestedTitle'] as String? ?? '',
      suggestedDescription: map['suggestedDescription'] as String?,
      suggestedReminderTime: map['suggestedReminderTime'] as String?,
      suggestedTargetDays: (map['suggestedTargetDays'] as List?)
          ?.map((e) => e as int)
          .toList(),
      encouragement: map['encouragement'] as String? ?? '',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate(),
      dismissedAt: (map['dismissedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitTitle': habitTitle,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'missedDays': missedDays,
      'diagnosis': diagnosis,
      'strategy': strategy.snakeCase,
      'suggestedTitle': suggestedTitle,
      'suggestedDescription': suggestedDescription,
      'suggestedReminderTime': suggestedReminderTime,
      'suggestedTargetDays': suggestedTargetDays,
      'encouragement': encouragement,
      'appliedAt': appliedAt != null ? Timestamp.fromDate(appliedAt!) : null,
      'dismissedAt':
          dismissedAt != null ? Timestamp.fromDate(dismissedAt!) : null,
    };
  }
}
