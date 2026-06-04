import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio que representa al usuario autenticado.
/// Separa la lógica de la app del objeto User de Firebase.
/// Si en el futuro cambiamos de proveedor de auth, solo tocamos este archivo.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;

  /// Número de escudos de racha disponibles (máx. 5)
  final int shieldsCount;

  /// Inicio del período de modo enfermedad (null si no está activo)
  final DateTime? sickModeStart;

  /// Fin del período de modo enfermedad (null si no está activo)
  final DateTime? sickModeUntil;

  /// Si el perfil es público (visible en el directorio de perfiles)
  final bool isProfilePublic;

  /// Username único elegido por el usuario (lowercase, 3-20, [a-z0-9_])
  final String? username;

  /// Cuándo se hizo público el perfil por primera vez
  final DateTime? publicProfileCreatedAt;

  /// URL de la foto de perfil en Firebase Storage (null = sin foto)
  final String? photoUrl;

  /// Bio corta del perfil (máx. ~150 chars, null = sin bio)
  final String? bio;

  /// Quién puede enviar retos al usuario: "everyone" | "followers" | "nobody"
  final String challengePrivacy;

  /// Quién puede ver el perfil completo: "everyone" | "followers" | "nobody"
  final String profileVisibility;

  /// Mostrar bloque de stats en el perfil público
  final bool showStats;

  /// Mostrar lista de hábitos activos en el perfil público
  final bool showHabits;

  /// Mostrar logros desbloqueados en el perfil público
  final bool showAchievements;

  /// Mostrar contador de seguidores/siguiendo en el perfil público
  final bool showFollowerCount;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.shieldsCount = 0,
    this.sickModeStart,
    this.sickModeUntil,
    this.isProfilePublic = false,
    this.username,
    this.publicProfileCreatedAt,
    this.photoUrl,
    this.bio,
    this.challengePrivacy = 'everyone',
    this.profileVisibility = 'everyone',
    this.showStats = true,
    this.showHabits = true,
    this.showAchievements = true,
    this.showFollowerCount = true,
  });

  /// Si el modo enfermedad sigue activo ahora mismo
  bool get isSickModeActive {
    if (sickModeUntil == null) return false;
    return sickModeUntil!.isAfter(DateTime.now());
  }

  /// Crear desde un doc de Firestore (el uid viene del doc.id o de auth)
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      shieldsCount: data['shieldsCount'] as int? ?? 0,
      sickModeStart: data['sickModeStart'] != null
          ? (data['sickModeStart'] as Timestamp).toDate()
          : null,
      sickModeUntil: data['sickModeUntil'] != null
          ? (data['sickModeUntil'] as Timestamp).toDate()
          : null,
      isProfilePublic: data['isProfilePublic'] as bool? ?? false,
      username: data['username'] as String?,
      publicProfileCreatedAt: data['publicProfileCreatedAt'] != null
          ? (data['publicProfileCreatedAt'] as Timestamp).toDate()
          : null,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      challengePrivacy: data['challengePrivacy'] as String? ?? 'everyone',
      profileVisibility: data['profileVisibility'] as String? ?? 'everyone',
      showStats: data['showStats'] as bool? ?? true,
      showHabits: data['showHabits'] as bool? ?? true,
      showAchievements: data['showAchievements'] as bool? ?? true,
      showFollowerCount: data['showFollowerCount'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'shieldsCount': shieldsCount,
      'sickModeStart':
          sickModeStart != null ? Timestamp.fromDate(sickModeStart!) : null,
      'sickModeUntil':
          sickModeUntil != null ? Timestamp.fromDate(sickModeUntil!) : null,
      'isProfilePublic': isProfilePublic,
      'username': username,
      'publicProfileCreatedAt': publicProfileCreatedAt != null
          ? Timestamp.fromDate(publicProfileCreatedAt!)
          : null,
      'photoUrl': photoUrl,
      'bio': bio,
      'challengePrivacy': challengePrivacy,
      'profileVisibility': profileVisibility,
      'showStats': showStats,
      'showHabits': showHabits,
      'showAchievements': showAchievements,
      'showFollowerCount': showFollowerCount,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    int? shieldsCount,
    DateTime? sickModeStart,
    DateTime? sickModeUntil,
    bool clearSickMode = false,
    bool? isProfilePublic,
    String? username,
    DateTime? publicProfileCreatedAt,
    bool clearUsername = false,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? bio,
    bool clearBio = false,
    String? challengePrivacy,
    String? profileVisibility,
    bool? showStats,
    bool? showHabits,
    bool? showAchievements,
    bool? showFollowerCount,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      shieldsCount: shieldsCount ?? this.shieldsCount,
      sickModeStart: clearSickMode ? null : (sickModeStart ?? this.sickModeStart),
      sickModeUntil: clearSickMode ? null : (sickModeUntil ?? this.sickModeUntil),
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      username: clearUsername ? null : (username ?? this.username),
      publicProfileCreatedAt: publicProfileCreatedAt ?? this.publicProfileCreatedAt,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      bio: clearBio ? null : (bio ?? this.bio),
      challengePrivacy: challengePrivacy ?? this.challengePrivacy,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showStats: showStats ?? this.showStats,
      showHabits: showHabits ?? this.showHabits,
      showAchievements: showAchievements ?? this.showAchievements,
      showFollowerCount: showFollowerCount ?? this.showFollowerCount,
    );
  }
}
