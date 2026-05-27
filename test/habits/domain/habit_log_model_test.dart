import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/habits/domain/habit_log_model.dart';

void main() {
  final date = DateTime(2026, 5, 20);

  group('HabitLogModel.fromJson', () {
    test('parsea todos los campos', () {
      final log = HabitLogModel.fromJson({
        'date': Timestamp.fromDate(date),
        'completed': true,
        'shielded': true,
        'notes': 'Bien',
      }, 'log1');

      expect(log.id, 'log1');
      expect(log.date, date);
      expect(log.completed, true);
      expect(log.shielded, true);
      expect(log.notes, 'Bien');
    });

    test('defaults', () {
      final log = HabitLogModel.fromJson({
        'date': Timestamp.fromDate(date),
      }, 'log2');

      expect(log.completed, false);
      expect(log.shielded, false);
      expect(log.notes, isNull);
    });
  });

  group('toJson', () {
    test('roundtrip', () {
      final original = HabitLogModel(
        id: 'l1',
        date: date,
        completed: true,
        shielded: true,
        notes: 'nota',
      );
      final json = original.toJson();
      final restored = HabitLogModel.fromJson(json, 'l1');

      expect(restored.date, original.date);
      expect(restored.completed, original.completed);
      expect(restored.shielded, original.shielded);
      expect(restored.notes, original.notes);
    });

    test('no incluye id', () {
      final log = HabitLogModel(id: 'x', date: date, completed: true);
      expect(log.toJson().containsKey('id'), false);
    });
  });
}
