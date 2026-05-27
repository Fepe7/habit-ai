import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/challenges/domain/challenge_model.dart';

void main() {
  final now = DateTime(2026, 5, 20);
  final startDate = DateTime(2026, 5, 21);
  final endDate = DateTime(2026, 6, 11);

  Map<String, dynamic> _fullJson() => {
        'habitTitle': 'Meditar',
        'habitDescription': '10 min diarios',
        'habitCategory': 'bienestar',
        'durationDays': 21,
        'creatorUid': 'u1',
        'invitedUid': 'u2',
        'status': 'active',
        'createdAt': Timestamp.fromDate(now),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'completedAt': null,
        'participantUids': ['u1', 'u2'],
      };

  group('ChallengeModel.fromJson', () {
    test('parsea todos los campos', () {
      final c = ChallengeModel.fromJson(_fullJson(), 'c1');

      expect(c.id, 'c1');
      expect(c.habitTitle, 'Meditar');
      expect(c.habitDescription, '10 min diarios');
      expect(c.habitCategory, 'bienestar');
      expect(c.durationDays, 21);
      expect(c.creatorUid, 'u1');
      expect(c.invitedUid, 'u2');
      expect(c.status, ChallengeStatus.active);
      expect(c.createdAt, now);
      expect(c.startDate, startDate);
      expect(c.endDate, endDate);
      expect(c.completedAt, isNull);
      expect(c.participantUids, ['u1', 'u2']);
    });

    test('defaults', () {
      final c = ChallengeModel.fromJson({
        'habitTitle': 'X',
        'creatorUid': 'u1',
        'invitedUid': 'u2',
        'createdAt': Timestamp.fromDate(now),
      }, 'c2');

      expect(c.habitDescription, '');
      expect(c.habitCategory, 'productividad');
      expect(c.durationDays, 21);
      expect(c.status, ChallengeStatus.pending);
      expect(c.startDate, isNull);
      expect(c.endDate, isNull);
      expect(c.completedAt, isNull);
      expect(c.participantUids, isEmpty);
    });

    test('todos los ChallengeStatus se parsean', () {
      for (final s in ChallengeStatus.values) {
        final c = ChallengeModel.fromJson({
          'habitTitle': 'X',
          'creatorUid': 'u1',
          'invitedUid': 'u2',
          'status': s.name,
          'createdAt': Timestamp.fromDate(now),
        }, 'id');
        expect(c.status, s);
      }
    });

    test('status desconocido → pending', () {
      final c = ChallengeModel.fromJson({
        'habitTitle': 'X',
        'creatorUid': 'u1',
        'invitedUid': 'u2',
        'status': 'unknown_status',
        'createdAt': Timestamp.fromDate(now),
      }, 'id');
      expect(c.status, ChallengeStatus.pending);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = ChallengeModel.fromJson(_fullJson(), 'c1');
      final json = original.toJson();
      final restored = ChallengeModel.fromJson(json, 'c1');

      expect(restored.habitTitle, original.habitTitle);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.startDate, original.startDate);
      expect(restored.participantUids, original.participantUids);
    });
  });

  group('computed getters', () {
    test('partnerUid', () {
      final c = ChallengeModel.fromJson(_fullJson(), 'c1');
      expect(c.partnerUid('u1'), 'u2');
      expect(c.partnerUid('u2'), 'u1');
    });

    test('isActive / isPending', () {
      final active = ChallengeModel.fromJson(_fullJson(), 'c1');
      expect(active.isActive, true);
      expect(active.isPending, false);

      final pending = ChallengeModel.fromJson({
        ..._fullJson(),
        'status': 'pending',
      }, 'c2');
      expect(pending.isActive, false);
      expect(pending.isPending, true);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final c = ChallengeModel.fromJson(_fullJson(), 'c1');
      final copy = c.copyWith(
        status: ChallengeStatus.completed,
        completedAt: now,
      );

      expect(copy.status, ChallengeStatus.completed);
      expect(copy.completedAt, now);
      expect(copy.habitTitle, c.habitTitle);
      expect(copy.id, c.id);
    });
  });
}
