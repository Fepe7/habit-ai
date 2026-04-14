import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa el registro diario de un hábito.
/// Cada vez que el usuario marca un hábito como completado, se crea un log.
/// De aquí se calculan las rachas y las estadísticas del dashboard.
/// Si [shielded] es true, el log fue creado por un escudo (no completado real).
class HabitLogModel {
  final String id;
  final DateTime date;
  final bool completed;
  final bool shielded;
  final String? notes;

  const HabitLogModel({
    required this.id,
    required this.date,
    required this.completed,
    this.shielded = false,
    this.notes,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitLogModel(
      id: docId,
      date: (json['date'] as Timestamp).toDate(),
      completed: json['completed'] as bool? ?? false,
      shielded: json['shielded'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'shielded': shielded,
      'notes': notes,
    };
  }
}