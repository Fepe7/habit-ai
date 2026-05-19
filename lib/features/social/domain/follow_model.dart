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
    final name = displayName.trim();
    if (name.isNotEmpty) {
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    }
    if (username.isNotEmpty) return username[0].toUpperCase();
    return 'U';
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
