import 'package:cloud_firestore/cloud_firestore.dart';

// Grupo de habitos generado por la IA (o creado manualmente)
class HabitGroupModel {
  final String id;
  final String title;
  final String? emoji;
  final String? description;
  final DateTime createdAt;
  final String? conversationId;
  final int habitCount;
  final bool isActive;
  // id de la plantilla publica si el grupo fue publicado en la comunidad
  final String? publishedTemplateId;

  const HabitGroupModel({
    required this.id,
    required this.title,
    this.emoji,
    this.description,
    required this.createdAt,
    this.conversationId,
    this.habitCount = 0,
    this.isActive = true,
    this.publishedTemplateId,
  });

  factory HabitGroupModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitGroupModel(
      id: docId,
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      conversationId: json['conversationId'] as String?,
      habitCount: json['habitCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      publishedTemplateId: json['publishedTemplateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'emoji': emoji,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'conversationId': conversationId,
      'habitCount': habitCount,
      'isActive': isActive,
      'publishedTemplateId': publishedTemplateId,
    };
  }

  HabitGroupModel copyWith({
    String? title,
    String? emoji,
    String? description,
    int? habitCount,
    bool? isActive,
    String? publishedTemplateId,
  }) {
    return HabitGroupModel(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      createdAt: createdAt,
      conversationId: conversationId,
      habitCount: habitCount ?? this.habitCount,
      isActive: isActive ?? this.isActive,
      publishedTemplateId: publishedTemplateId ?? this.publishedTemplateId,
    );
  }
}
