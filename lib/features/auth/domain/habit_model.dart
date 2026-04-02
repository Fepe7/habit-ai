import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio que representa un hábito del usuario.
/// Independiente de la UI — solo define la estructura de datos.
class HabitModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency;
  final List<int> targetDays;
  final String? reminderTime;
  final int currentStreak;
  final int bestStreak;
  final bool isAIGenerated;
  final DateTime createdAt;
  final bool isActive;

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.reminderTime,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isAIGenerated = false,
    required this.createdAt,
    this.isActive = true,
  });

  /// Construye el modelo desde un documento de Firestore.
  /// El ID viene separado porque Firestore lo guarda en doc.id,
  /// no dentro del data() del documento.
  factory HabitModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitModel(
      id: docId,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'productividad',
      frequency: json['frequency'] as String? ?? 'daily',
      targetDays: List<int>.from(json['targetDays'] ?? []),
      reminderTime: json['reminderTime'] as String?,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      isAIGenerated: json['isAIGenerated'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serializa para guardar en Firestore.
  /// No incluye el ID porque Firestore lo gestiona como doc.id.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'frequency': frequency,
      'targetDays': targetDays,
      'reminderTime': reminderTime,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isAIGenerated': isAIGenerated,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Copia inmutable con campos modificados.
  /// En vez de mutar el objeto, creamos uno nuevo con los cambios.
  HabitModel copyWith({
    String? title,
    String? description,
    String? category,
    String? frequency,
    List<int>? targetDays,
    String? reminderTime,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      targetDays: targetDays ?? this.targetDays,
      reminderTime: reminderTime ?? this.reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isAIGenerated: isAIGenerated,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}