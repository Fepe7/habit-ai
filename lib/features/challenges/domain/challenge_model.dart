import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeStatus { pending, active, completed, declined, abandoned }

// Reto compartido entre dos usuarios
class ChallengeModel {
  final String id;
  final String habitTitle;
  final String habitDescription;
  final String habitCategory;
  final int durationDays;
  final String creatorUid;
  final String invitedUid;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? completedAt;
  final List<String> participantUids;

  const ChallengeModel({
    required this.id,
    required this.habitTitle,
    required this.habitDescription,
    required this.habitCategory,
    required this.durationDays,
    required this.creatorUid,
    required this.invitedUid,
    required this.status,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.completedAt,
    required this.participantUids,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json, String docId) {
    return ChallengeModel(
      id: docId,
      habitTitle: json['habitTitle'] as String,
      habitDescription: json['habitDescription'] as String? ?? '',
      habitCategory: json['habitCategory'] as String? ?? 'productividad',
      durationDays: json['durationDays'] as int? ?? 21,
      creatorUid: json['creatorUid'] as String,
      invitedUid: json['invitedUid'] as String,
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ChallengeStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      startDate: json['startDate'] != null
          ? (json['startDate'] as Timestamp).toDate()
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      participantUids: List<String>.from(json['participantUids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitTitle': habitTitle,
      'habitDescription': habitDescription,
      'habitCategory': habitCategory,
      'durationDays': durationDays,
      'creatorUid': creatorUid,
      'invitedUid': invitedUid,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'participantUids': participantUids,
    };
  }

  ChallengeModel copyWith({
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? completedAt,
  }) {
    return ChallengeModel(
      id: id,
      habitTitle: habitTitle,
      habitDescription: habitDescription,
      habitCategory: habitCategory,
      durationDays: durationDays,
      creatorUid: creatorUid,
      invitedUid: invitedUid,
      status: status ?? this.status,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completedAt: completedAt ?? this.completedAt,
      participantUids: participantUids,
    );
  }

  // uid del compañero (el otro participante)
  String partnerUid(String myUid) =>
      creatorUid == myUid ? invitedUid : creatorUid;

  bool get isActive => status == ChallengeStatus.active;
  bool get isPending => status == ChallengeStatus.pending;
}
