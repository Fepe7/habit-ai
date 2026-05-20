import 'package:cloud_firestore/cloud_firestore.dart';

/// Espejo público del usuario — solo contiene campos seguros.
/// Nunca expone email, reminderTime, notes ni logs.
class PublicProfileModel {
  final String uid;
  final String username;
  final String displayName;

  /// Iniciales para el avatar (derivadas de displayName)
  final String avatarInitials;

  /// Nivel promedio del usuario (1-5)
  final double averageLevel;

  /// Total de hábitos activos
  final int totalHabits;

  /// Mejor racha conseguida en cualquier hábito
  final int bestStreakEver;

  /// Cantidad de logros desbloqueados
  final int unlockedAchievements;

  /// Tipos de logros desbloqueados (para el showcase)
  final List<String> unlockedAchievementTypes;

  /// Cuándo se hizo público el perfil
  final DateTime createdAt;

  /// URL de la foto de perfil (null = sin foto, usa iniciales)
  final String? photoUrl;

  /// Si el perfil permite follow directo (false = requiere solicitud)
  final bool isProfilePublic;

  const PublicProfileModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatarInitials,
    required this.averageLevel,
    required this.totalHabits,
    required this.bestStreakEver,
    required this.unlockedAchievements,
    this.unlockedAchievementTypes = const [],
    required this.createdAt,
    this.photoUrl,
    this.isProfilePublic = true,
  });

  factory PublicProfileModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return PublicProfileModel(
      uid: docId,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Usuario',
      avatarInitials: data['avatarInitials'] as String? ?? 'U',
      averageLevel: (data['averageLevel'] as num?)?.toDouble() ?? 1.0,
      totalHabits: data['totalHabits'] as int? ?? 0,
      bestStreakEver: data['bestStreakEver'] as int? ?? 0,
      unlockedAchievements: data['unlockedAchievements'] as int? ?? 0,
      unlockedAchievementTypes: List<String>.from(
        data['unlockedAchievementTypes'] as List<dynamic>? ?? [],
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      isProfilePublic: data['isProfilePublic'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'avatarInitials': avatarInitials,
      'averageLevel': averageLevel,
      'totalHabits': totalHabits,
      'bestStreakEver': bestStreakEver,
      'unlockedAchievements': unlockedAchievements,
      'unlockedAchievementTypes': unlockedAchievementTypes,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'isProfilePublic': isProfilePublic,
    };
  }

  PublicProfileModel copyWith({
    String? username,
    String? displayName,
    String? avatarInitials,
    double? averageLevel,
    int? totalHabits,
    int? bestStreakEver,
    int? unlockedAchievements,
    List<String>? unlockedAchievementTypes,
    String? photoUrl,
    bool clearPhotoUrl = false,
    bool? isProfilePublic,
  }) {
    return PublicProfileModel(
      uid: uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      averageLevel: averageLevel ?? this.averageLevel,
      totalHabits: totalHabits ?? this.totalHabits,
      bestStreakEver: bestStreakEver ?? this.bestStreakEver,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      unlockedAchievementTypes:
          unlockedAchievementTypes ?? this.unlockedAchievementTypes,
      createdAt: createdAt,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
    );
  }
}
