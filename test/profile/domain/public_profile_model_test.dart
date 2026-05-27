import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/profile/domain/public_profile_model.dart';

void main() {
  final createdAt = DateTime(2026, 5, 10);

  Map<String, dynamic> _fullData() => {
        'username': 'andrei',
        'displayName': 'Andrei S',
        'avatarInitials': 'AS',
        'averageLevel': 3.5,
        'totalHabits': 8,
        'bestStreakEver': 30,
        'unlockedAchievements': 5,
        'unlockedAchievementTypes': ['streak_7', 'first_habit'],
        'createdAt': Timestamp.fromDate(createdAt),
        'photoUrl': 'https://example.com/photo.jpg',
        'isProfilePublic': false,
      };

  group('fromFirestore', () {
    test('parsea todos los campos', () {
      final p = PublicProfileModel.fromFirestore(_fullData(), 'uid1');

      expect(p.uid, 'uid1');
      expect(p.username, 'andrei');
      expect(p.displayName, 'Andrei S');
      expect(p.avatarInitials, 'AS');
      expect(p.averageLevel, 3.5);
      expect(p.totalHabits, 8);
      expect(p.bestStreakEver, 30);
      expect(p.unlockedAchievements, 5);
      expect(p.unlockedAchievementTypes, ['streak_7', 'first_habit']);
      expect(p.createdAt, createdAt);
      expect(p.photoUrl, 'https://example.com/photo.jpg');
      expect(p.isProfilePublic, false);
    });

    test('defaults', () {
      final p = PublicProfileModel.fromFirestore({}, 'uid2');

      expect(p.username, '');
      expect(p.displayName, 'Usuario');
      expect(p.avatarInitials, 'U');
      expect(p.averageLevel, 1.0);
      expect(p.totalHabits, 0);
      expect(p.bestStreakEver, 0);
      expect(p.unlockedAchievements, 0);
      expect(p.unlockedAchievementTypes, isEmpty);
      expect(p.photoUrl, isNull);
      expect(p.isProfilePublic, true);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = PublicProfileModel.fromFirestore(_fullData(), 'uid1');
      final json = original.toJson();
      final restored = PublicProfileModel.fromFirestore(json, 'uid1');

      expect(restored.username, original.username);
      expect(restored.displayName, original.displayName);
      expect(restored.averageLevel, original.averageLevel);
      expect(restored.totalHabits, original.totalHabits);
      expect(restored.unlockedAchievementTypes, original.unlockedAchievementTypes);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isProfilePublic, original.isProfilePublic);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final p = PublicProfileModel.fromFirestore(_fullData(), 'uid1');
      final copy = p.copyWith(totalHabits: 10, bestStreakEver: 50);

      expect(copy.totalHabits, 10);
      expect(copy.bestStreakEver, 50);
      expect(copy.uid, p.uid);
      expect(copy.username, p.username);
    });

    test('clearPhotoUrl', () {
      final p = PublicProfileModel.fromFirestore(_fullData(), 'uid1');
      expect(p.photoUrl, isNotNull);
      final cleared = p.copyWith(clearPhotoUrl: true);
      expect(cleared.photoUrl, isNull);
    });
  });
}
