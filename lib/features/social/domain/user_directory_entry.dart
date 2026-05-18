import 'package:cloud_firestore/cloud_firestore.dart';
import 'privacy_level.dart';

/// Entrada ligera en /user_directory/{uid}.
/// Solo contiene lo mínimo para búsqueda y control de privacidad.
/// Separada de PublicProfileModel (que tiene stats y hábitos).
class UserDirectoryEntry {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final PrivacyLevel challengePrivacy;
  final PrivacyLevel profileVisibility;
  final DateTime createdAt;

  const UserDirectoryEntry({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.challengePrivacy = PrivacyLevel.everyone,
    this.profileVisibility = PrivacyLevel.everyone,
    required this.createdAt,
  });

  String get avatarInitials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return username.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UserDirectoryEntry.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return UserDirectoryEntry(
      uid: uid,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      challengePrivacy: PrivacyLevelX.fromString(
        data['challengePrivacy'] as String?,
      ),
      profileVisibility: PrivacyLevelX.fromString(
        data['profileVisibility'] as String?,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'challengePrivacy': challengePrivacy.value,
        'profileVisibility': profileVisibility.value,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
