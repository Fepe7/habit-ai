import 'package:cloud_firestore/cloud_firestore.dart';

// Grupo de habitos generado por la IA (o creado manualmente)
class HabitGroupModel {
  final String id;
  final String title;
  final String? emoji;
  final DateTime createdAt;
  final String? conversationId;
  final int habitCount;
  final bool isActive;

  const HabitGroupModel({
    required this.id,
    required this.title,
    this.emoji,
    required this.createdAt,
    this.conversationId,
    this.habitCount = 0,
    this.isActive = true,
  });

  factory HabitGroupModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitGroupModel(
      id: docId,
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      conversationId: json['conversationId'] as String?,
      habitCount: json['habitCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'conversationId': conversationId,
      'habitCount': habitCount,
      'isActive': isActive,
    };
  }

  HabitGroupModel copyWith({
    String? title,
    String? emoji,
    int? habitCount,
    bool? isActive,
  }) {
    return HabitGroupModel(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      conversationId: conversationId,
      habitCount: habitCount ?? this.habitCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
