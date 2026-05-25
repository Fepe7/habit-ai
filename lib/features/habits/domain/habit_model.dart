import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de habito
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
  final String? groupId;
  final String? challengeId;

  // --- Habit Stacking (Atomic Habits: "Después de X, haré Y") ---
  // stackId = ID del hábito raíz de la cadena (null si no pertenece a ninguna)
  final String? stackId;
  // Posición en la cadena (0 = ancla/raíz, 1+ = encadenados)
  final int stackOrder;

  // Campo transitorio — NO se persiste en Firestore.
  // Usado para pasar "encadenar después de este hábito" desde la UI al repositorio.
  final String? stackAfterHabitId;

  /// Visibilidad en el perfil: 'public' | 'followers' | 'private'
  final String visibility;

  /// true si el hábito aparece en algún perfil (público o solo seguidores)
  bool get isVisibleToAnyone => visibility != 'private';

  /// true si pertenece a una cadena de hábitos
  bool get isInStack => stackId != null;

  /// true si es el ancla (primer hábito) de su cadena
  bool get isStackAnchor => stackId != null && stackOrder == 0;

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
    this.groupId,
    this.challengeId,
    this.visibility = 'private',
    this.stackId,
    this.stackOrder = 0,
    this.stackAfterHabitId,
  });

  // Crear desde un doc de Firestore (el id va aparte porque no viene en data())
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
      groupId: json['groupId'] as String?,
      challengeId: json['challengeId'] as String?,
      // retrocompat: si no hay 'visibility', leer el bool antiguo
      visibility: json['visibility'] as String? ??
          ((json['isPubliclyVisible'] as bool? ?? false) ? 'public' : 'private'),
      stackId: json['stackId'] as String?,
      stackOrder: json['stackOrder'] as int? ?? 0,
      // stackAfterHabitId es transitorio, nunca viene de Firestore
    );
  }

  // Convertir a map para guardar en Firestore (sin id, lo pone Firestore)
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
      'groupId': groupId,
      'challengeId': challengeId,
      'visibility': visibility,
      'stackId': stackId,
      'stackOrder': stackOrder,
      // stackAfterHabitId es transitorio, no va a Firestore
    };
  }

  // Crear copia con campos cambiados
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
    String? groupId,
    String? challengeId,
    String? visibility,
    String? stackId,
    int? stackOrder,
    String? stackAfterHabitId,
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
      groupId: groupId ?? this.groupId,
      challengeId: challengeId ?? this.challengeId,
      visibility: visibility ?? this.visibility,
      stackId: stackId ?? this.stackId,
      stackOrder: stackOrder ?? this.stackOrder,
      stackAfterHabitId: stackAfterHabitId ?? this.stackAfterHabitId,
    );
  }
}
