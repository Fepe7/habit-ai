import 'package:cloud_firestore/cloud_firestore.dart';

// Plantilla pública de hábitos publicada por un usuario en la comunidad
class CommunityTemplateModel {
  final String id;
  final String authorUid;
  final String authorUsername;
  final String authorDisplayName;
  final String title;
  final String? emoji;
  final String description;
  // categoria dominante (la más frecuente entre los hábitos del grupo)
  final String category;
  final int habitCount;
  final int importCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// URL de la foto del autor (null = sin foto, usa iniciales)
  final String? authorPhotoUrl;

  const CommunityTemplateModel({
    required this.id,
    required this.authorUid,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.title,
    this.emoji,
    required this.description,
    required this.category,
    required this.habitCount,
    this.importCount = 0,
    this.reportCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.authorPhotoUrl,
  });

  factory CommunityTemplateModel.fromJson(
      Map<String, dynamic> json, String docId) {
    return CommunityTemplateModel(
      id: docId,
      authorUid: json['authorUid'] as String,
      authorUsername: json['authorUsername'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? '',
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'productividad',
      habitCount: json['habitCount'] as int? ?? 0,
      importCount: json['importCount'] as int? ?? 0,
      reportCount: json['reportCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorUid': authorUid,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'title': title,
      'emoji': emoji,
      'description': description,
      'category': category,
      'habitCount': habitCount,
      'importCount': importCount,
      'reportCount': reportCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'authorPhotoUrl': authorPhotoUrl,
    };
  }

  CommunityTemplateModel copyWith({
    int? importCount,
    int? reportCount,
    String? authorPhotoUrl,
  }) {
    return CommunityTemplateModel(
      id: id,
      authorUid: authorUid,
      authorUsername: authorUsername,
      authorDisplayName: authorDisplayName,
      title: title,
      emoji: emoji,
      description: description,
      category: category,
      habitCount: habitCount,
      importCount: importCount ?? this.importCount,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
    );
  }
}
