import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/social/domain/follow_model.dart';

void main() {
  final followedAt = DateTime(2026, 5, 20);

  group('FollowModel.fromFirestore', () {
    test('parsea todos los campos', () {
      final f = FollowModel.fromFirestore({
        'username': 'andrei',
        'displayName': 'Andrei S',
        'photoUrl': 'https://example.com/photo.jpg',
        'followedAt': Timestamp.fromDate(followedAt),
      }, 'uid1');

      expect(f.uid, 'uid1');
      expect(f.username, 'andrei');
      expect(f.displayName, 'Andrei S');
      expect(f.photoUrl, 'https://example.com/photo.jpg');
      expect(f.followedAt, followedAt);
    });

    test('defaults', () {
      final f = FollowModel.fromFirestore({}, 'uid2');

      expect(f.username, '');
      expect(f.displayName, '');
      expect(f.photoUrl, isNull);
    });
  });

  group('avatarInitials', () {
    test('dos nombres → dos iniciales', () {
      final f = FollowModel(
        uid: 'u', username: 'x', displayName: 'Andrei Staicu',
        followedAt: followedAt,
      );
      expect(f.avatarInitials, 'AS');
    });

    test('un nombre → una inicial', () {
      final f = FollowModel(
        uid: 'u', username: 'x', displayName: 'Andrei',
        followedAt: followedAt,
      );
      expect(f.avatarInitials, 'A');
    });

    test('nombre vacío, username no vacío → inicial del username', () {
      final f = FollowModel(
        uid: 'u', username: 'andrei', displayName: '',
        followedAt: followedAt,
      );
      expect(f.avatarInitials, 'A');
    });

    test('todo vacío → U', () {
      final f = FollowModel(
        uid: 'u', username: '', displayName: '',
        followedAt: followedAt,
      );
      expect(f.avatarInitials, 'U');
    });

    test('nombre con espacios extra', () {
      final f = FollowModel(
        uid: 'u', username: 'x', displayName: '  Ana  García  ',
        followedAt: followedAt,
      );
      expect(f.avatarInitials, 'AG');
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = FollowModel(
        uid: 'u1',
        username: 'test',
        displayName: 'Test',
        photoUrl: 'url',
        followedAt: followedAt,
      );
      final json = original.toJson();
      final restored = FollowModel.fromFirestore(json, 'u1');

      expect(restored.username, original.username);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.followedAt, original.followedAt);
    });
  });
}
