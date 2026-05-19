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

  /// Si el perfil requiere solicitud para seguir (false = privado)
  final bool isProfilePublic;

  /// Visibilidad de secciones del perfil
  final bool showStats;
  final bool showHabits;
  final bool showAchievements;
  final bool showFollowerCount;

  const UserDirectoryEntry({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.challengePrivacy = PrivacyLevel.everyone,
    this.profileVisibility = PrivacyLevel.everyone,
    required this.createdAt,
    this.isProfilePublic = false,
    this.showStats = true,
    this.showHabits = true,
    this.showAchievements = true,
    this.showFollowerCount = true,
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
      isProfilePublic: data['isProfilePublic'] as bool? ?? false,
      showStats: data['showStats'] as bool? ?? true,
      showHabits: data['showHabits'] as bool? ?? true,
      showAchievements: data['showAchievements'] as bool? ?? true,
      showFollowerCount: data['showFollowerCount'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'challengePrivacy': challengePrivacy.value,
        'profileVisibility': profileVisibility.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'isProfilePublic': isProfilePublic,
        'showStats': showStats,
        'showHabits': showHabits,
        'showAchievements': showAchievements,
        'showFollowerCount': showFollowerCount,
      };
}
