import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/challenges/domain/challenge_progress_model.dart';

void main() {
  final updatedAt = DateTime(2026, 5, 20);

  group('ChallengeProgressModel.fromJson', () {
    test('parsea todos los campos', () {
      final p = ChallengeProgressModel.fromJson({
        'uid': 'u1',
        'days': {
          '1': 'completed',
          '2': 'completed',
          '3': 'missed',
          '4': 'shielded',
          '5': 'pending',
        },
        'completedCount': 2,
        'currentStreak': 2,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      expect(p.uid, 'u1');
      expect(p.days.length, 5);
      expect(p.days[1], DayStatus.completed);
      expect(p.days[3], DayStatus.missed);
      expect(p.days[4], DayStatus.shielded);
      expect(p.days[5], DayStatus.pending);
      expect(p.completedCount, 2);
      expect(p.currentStreak, 2);
      expect(p.updatedAt, updatedAt);
    });

    test('defaults', () {
      final p = ChallengeProgressModel.fromJson({
        'uid': 'u1',
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      expect(p.days, isEmpty);
      expect(p.completedCount, 0);
      expect(p.currentStreak, 0);
    });

    test('DayStatus desconocido → pending', () {
      final p = ChallengeProgressModel.fromJson({
        'uid': 'u1',
        'days': {'1': 'unknown_status'},
        'updatedAt': Timestamp.fromDate(updatedAt),
      });
      expect(p.days[1], DayStatus.pending);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = ChallengeProgressModel(
        uid: 'u1',
        days: {1: DayStatus.completed, 2: DayStatus.missed},
        completedCount: 1,
        currentStreak: 1,
        updatedAt: updatedAt,
      );
      final json = original.toJson();
      final restored = ChallengeProgressModel.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.days, original.days);
      expect(restored.completedCount, original.completedCount);
      expect(restored.currentStreak, original.currentStreak);
    });

    test('days keys se serializan como strings', () {
      final p = ChallengeProgressModel(
        uid: 'u1',
        days: {1: DayStatus.completed},
        completedCount: 1,
        currentStreak: 1,
        updatedAt: updatedAt,
      );
      final json = p.toJson();
      final daysMap = json['days'] as Map<String, dynamic>;
      expect(daysMap.containsKey('1'), true);
      expect(daysMap['1'], 'completed');
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final p = ChallengeProgressModel(
        uid: 'u1',
        days: {1: DayStatus.completed},
        completedCount: 1,
        currentStreak: 1,
        updatedAt: updatedAt,
      );
      final copy = p.copyWith(completedCount: 5, currentStreak: 3);

      expect(copy.completedCount, 5);
      expect(copy.currentStreak, 3);
      expect(copy.uid, p.uid);
      expect(copy.days, p.days);
    });

    test('updatedAt y days', () {
      final p = ChallengeProgressModel(
        uid: 'u1',
        days: {1: DayStatus.pending},
        completedCount: 0,
        currentStreak: 0,
        updatedAt: updatedAt,
      );
      final newDate = DateTime(2026, 5, 21);
      final newDays = {1: DayStatus.completed, 2: DayStatus.missed};
      final copy = p.copyWith(updatedAt: newDate, days: newDays);
      expect(copy.updatedAt, newDate);
      expect(copy.days, newDays);
    });
  });
}
