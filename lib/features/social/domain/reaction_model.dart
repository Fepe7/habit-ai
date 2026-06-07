import 'package:cloud_firestore/cloud_firestore.dart';

/// Reacción emoji de un usuario al perfil público de otro.
/// Colección: public_profiles/{ownerUid}/reactions/{reactorUid}
/// Un doc por reactor — el doc ID es el propio reactorUid.
class ReactionModel {
  final String reactorUid;
  final String reactorUsername;
  final String reactorDisplayName;
  final String? reactorPhotoUrl;
  final String emoji;
  final DateTime createdAt;

  const ReactionModel({
    required this.reactorUid,
    required this.reactorUsername,
    required this.reactorDisplayName,
    this.reactorPhotoUrl,
    required this.emoji,
    required this.createdAt,
  });

  factory ReactionModel.fromFirestore(Map<String, dynamic> data) {
    return ReactionModel(
      reactorUid: data['reactorUid'] as String? ?? '',
      reactorUsername: data['reactorUsername'] as String? ?? '',
      reactorDisplayName: data['reactorDisplayName'] as String? ?? '',
      reactorPhotoUrl: data['reactorPhotoUrl'] as String?,
      emoji: data['emoji'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reactorUid': reactorUid,
        'reactorUsername': reactorUsername,
        'reactorDisplayName': reactorDisplayName,
        'reactorPhotoUrl': reactorPhotoUrl,
        'emoji': emoji,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
