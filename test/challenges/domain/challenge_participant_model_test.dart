import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/challenges/domain/challenge_participant_model.dart';

void main() {
  final joinedAt = DateTime(2026, 5, 20);

  group('ChallengeParticipantModel.fromJson', () {
    test('parsea todos los campos', () {
      final p = ChallengeParticipantModel.fromJson({
        'uid': 'u1',
        'username': 'andrei',
        'displayName': 'Andrei S',
        'photoUrl': 'https://example.com/photo.jpg',
        'habitId': 'h1',
        'joinedAt': Timestamp.fromDate(joinedAt),
      });

      expect(p.uid, 'u1');
      expect(p.username, 'andrei');
      expect(p.displayName, 'Andrei S');
      expect(p.photoUrl, 'https://example.com/photo.jpg');
      expect(p.habitId, 'h1');
      expect(p.joinedAt, joinedAt);
    });

    test('defaults', () {
      final p = ChallengeParticipantModel.fromJson({
        'uid': 'u1',
        'joinedAt': Timestamp.fromDate(joinedAt),
      });

      expect(p.username, '');
      expect(p.displayName, '');
      expect(p.photoUrl, isNull);
      expect(p.habitId, isNull);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = ChallengeParticipantModel(
        uid: 'u1',
        username: 'test',
        displayName: 'Test User',
        photoUrl: 'url',
        habitId: 'h1',
        joinedAt: joinedAt,
      );
      final json = original.toJson();
      final restored = ChallengeParticipantModel.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.username, original.username);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.habitId, original.habitId);
      expect(restored.joinedAt, original.joinedAt);
    });
  });
}
