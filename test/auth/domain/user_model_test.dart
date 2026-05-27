import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/auth/domain/user_model.dart';

void main() {
  final now = DateTime(2026, 5, 20, 10, 0);
  final sickStart = DateTime(2026, 5, 18);

  Map<String, dynamic> _fullData() => {
        'email': 'test@mail.com',
        'displayName': 'Andrei',
        'shieldsCount': 3,
        'sickModeStart': Timestamp.fromDate(sickStart),
        'sickModeUntil': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'isProfilePublic': true,
        'username': 'andrei_dev',
        'publicProfileCreatedAt': Timestamp.fromDate(now),
        'photoUrl': 'https://example.com/photo.jpg',
        'challengePrivacy': 'followers',
        'profileVisibility': 'followers',
        'showStats': false,
        'showHabits': false,
        'showAchievements': false,
        'showFollowerCount': false,
      };

  group('fromFirestore', () {
    test('parsea todos los campos', () {
      final u = UserModel.fromFirestore(_fullData(), 'uid1');

      expect(u.uid, 'uid1');
      expect(u.email, 'test@mail.com');
      expect(u.displayName, 'Andrei');
      expect(u.shieldsCount, 3);
      expect(u.sickModeStart, sickStart);
      expect(u.sickModeUntil, now.add(const Duration(days: 2)));
      expect(u.isProfilePublic, true);
      expect(u.username, 'andrei_dev');
      expect(u.publicProfileCreatedAt, now);
      expect(u.photoUrl, 'https://example.com/photo.jpg');
      expect(u.challengePrivacy, 'followers');
      expect(u.profileVisibility, 'followers');
      expect(u.showStats, false);
      expect(u.showHabits, false);
      expect(u.showAchievements, false);
      expect(u.showFollowerCount, false);
    });

    test('defaults', () {
      final u = UserModel.fromFirestore({}, 'uid2');

      expect(u.email, '');
      expect(u.displayName, isNull);
      expect(u.shieldsCount, 0);
      expect(u.sickModeStart, isNull);
      expect(u.sickModeUntil, isNull);
      expect(u.isProfilePublic, false);
      expect(u.username, isNull);
      expect(u.publicProfileCreatedAt, isNull);
      expect(u.photoUrl, isNull);
      expect(u.challengePrivacy, 'everyone');
      expect(u.profileVisibility, 'everyone');
      expect(u.showStats, true);
      expect(u.showHabits, true);
      expect(u.showAchievements, true);
      expect(u.showFollowerCount, true);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = UserModel.fromFirestore(_fullData(), 'uid1');
      final json = original.toJson();
      final restored = UserModel.fromFirestore(json, 'uid1');

      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.shieldsCount, original.shieldsCount);
      expect(restored.sickModeStart, original.sickModeStart);
      expect(restored.isProfilePublic, original.isProfilePublic);
      expect(restored.username, original.username);
      expect(restored.challengePrivacy, original.challengePrivacy);
      expect(restored.showStats, original.showStats);
    });

    test('null dates se preservan', () {
      final u = UserModel.fromFirestore({'email': 'a@b.c'}, 'uid3');
      final json = u.toJson();
      expect(json['sickModeStart'], isNull);
      expect(json['sickModeUntil'], isNull);
      expect(json['publicProfileCreatedAt'], isNull);
    });
  });

  group('isSickModeActive', () {
    test('false cuando sickModeUntil es null', () {
      final u = UserModel(uid: 'x', email: 'e');
      expect(u.isSickModeActive, false);
    });

    test('false cuando sickModeUntil está en el pasado', () {
      final u = UserModel(
        uid: 'x',
        email: 'e',
        sickModeUntil: DateTime(2020, 1, 1),
      );
      expect(u.isSickModeActive, false);
    });

    test('true cuando sickModeUntil está en el futuro', () {
      final u = UserModel(
        uid: 'x',
        email: 'e',
        sickModeUntil: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(u.isSickModeActive, true);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final u = UserModel.fromFirestore(_fullData(), 'uid1');
      final copy = u.copyWith(email: 'new@mail.com', shieldsCount: 5);

      expect(copy.email, 'new@mail.com');
      expect(copy.shieldsCount, 5);
      expect(copy.uid, u.uid);
      expect(copy.displayName, u.displayName);
    });

    test('clearSickMode pone ambas fechas a null', () {
      final u = UserModel.fromFirestore(_fullData(), 'uid1');
      expect(u.sickModeStart, isNotNull);
      final cleared = u.copyWith(clearSickMode: true);
      expect(cleared.sickModeStart, isNull);
      expect(cleared.sickModeUntil, isNull);
    });

    test('clearUsername', () {
      final u = UserModel.fromFirestore(_fullData(), 'uid1');
      expect(u.username, 'andrei_dev');
      final cleared = u.copyWith(clearUsername: true);
      expect(cleared.username, isNull);
    });

    test('clearPhotoUrl', () {
      final u = UserModel.fromFirestore(_fullData(), 'uid1');
      expect(u.photoUrl, isNotNull);
      final cleared = u.copyWith(clearPhotoUrl: true);
      expect(cleared.photoUrl, isNull);
    });
  });
}
