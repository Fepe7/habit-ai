import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa a un seguidor/seguido en /users/{uid}/followers/{followerUid}
/// o /users/{uid}/following/{followingUid}.
class FollowModel {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final DateTime followedAt;

  const FollowModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.followedAt,
  });

  String get avatarInitials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return username.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory FollowModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return FollowModel(
      uid: uid,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      followedAt: data['followedAt'] != null
          ? (data['followedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'followedAt': Timestamp.fromDate(followedAt),
      };
}
