import 'package:cloud_firestore/cloud_firestore.dart';

// Participante de un reto compartido
class ChallengeParticipantModel {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final String? habitId;
  final DateTime joinedAt;

  const ChallengeParticipantModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.habitId,
    required this.joinedAt,
  });

  factory ChallengeParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipantModel(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      habitId: json['habitId'] as String?,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'habitId': habitId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
