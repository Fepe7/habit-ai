import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/mood/domain/mood_entry_model.dart';

void main() {
  group('MoodEntryModel.emoji', () {
    MoodEntryModel withRating(int r) => MoodEntryModel(
          id: 'x',
          rating: r,
          labels: const [],
          timeBlock: 'morning',
          timestamp: DateTime(2026, 1, 1),
        );

    test('mapea cada rating 1-5 a su emoji', () {
      expect(withRating(1).emoji, '😞');
      expect(withRating(2).emoji, '😕');
      expect(withRating(3).emoji, '😐');
      expect(withRating(4).emoji, '🙂');
      expect(withRating(5).emoji, '😄');
    });

    test('rating fuera de rango cae al neutro', () {
      expect(withRating(0).emoji, '😐');
      expect(withRating(99).emoji, '😐');
    });
  });

  group('MoodEntryModel.timeBlockFromHour', () {
    test('mañana 5:00-11:59', () {
      expect(MoodEntryModel.timeBlockFromHour(5), 'morning');
      expect(MoodEntryModel.timeBlockFromHour(11), 'morning');
    });

    test('mediodía 12:00-14:59', () {
      expect(MoodEntryModel.timeBlockFromHour(12), 'midday');
      expect(MoodEntryModel.timeBlockFromHour(14), 'midday');
    });

    test('tarde 15:00-20:59', () {
      expect(MoodEntryModel.timeBlockFromHour(15), 'afternoon');
      expect(MoodEntryModel.timeBlockFromHour(20), 'afternoon');
    });

    test('noche 21:00-4:59 (incluye madrugada)', () {
      expect(MoodEntryModel.timeBlockFromHour(21), 'night');
      expect(MoodEntryModel.timeBlockFromHour(23), 'night');
      expect(MoodEntryModel.timeBlockFromHour(0), 'night');
      expect(MoodEntryModel.timeBlockFromHour(4), 'night');
    });

    test('cubre las 24 horas sin huecos', () {
      const valid = {'morning', 'midday', 'afternoon', 'night'};
      for (var h = 0; h < 24; h++) {
        expect(valid.contains(MoodEntryModel.timeBlockFromHour(h)), isTrue,
            reason: 'hora $h sin bloque válido');
      }
    });
  });

  group('MoodEntryModel JSON', () {
    test('round-trip toJson/fromJson preserva los datos', () {
      final ts = DateTime(2026, 5, 29, 9, 30);
      final original = MoodEntryModel(
        id: 'doc1',
        rating: 4,
        labels: const ['energy', 'focus'],
        note: 'buen día',
        timeBlock: 'morning',
        timestamp: ts,
        habitsCompletedSnapshot: const ['h1', 'h2'],
      );

      final restored = MoodEntryModel.fromJson(original.toJson(), 'doc1');

      expect(restored.id, 'doc1');
      expect(restored.rating, 4);
      expect(restored.labels, ['energy', 'focus']);
      expect(restored.note, 'buen día');
      expect(restored.timeBlock, 'morning');
      expect(restored.timestamp, ts);
      expect(restored.habitsCompletedSnapshot, ['h1', 'h2']);
    });

    test('fromJson aplica defaults seguros con datos faltantes', () {
      final e = MoodEntryModel.fromJson(
        {'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1))},
        'doc2',
      );
      expect(e.rating, 3);
      expect(e.labels, isEmpty);
      expect(e.note, isNull);
      expect(e.timeBlock, 'morning');
      expect(e.habitsCompletedSnapshot, isEmpty);
    });

    test('toJson serializa timestamp como Timestamp de Firestore', () {
      final e = MoodEntryModel(
        id: 'x',
        rating: 3,
        labels: const [],
        timeBlock: 'night',
        timestamp: DateTime(2026, 1, 1, 22),
      );
      expect(e.toJson()['timestamp'], isA<Timestamp>());
    });
  });

  group('MoodEntryModel.copyWith', () {
    final base = MoodEntryModel(
      id: 'base',
      rating: 3,
      labels: const ['calm'],
      note: 'nota original',
      timeBlock: 'midday',
      timestamp: DateTime(2026, 1, 1),
    );

    test('sin args devuelve copia equivalente', () {
      final c = base.copyWith();
      expect(c.rating, base.rating);
      expect(c.labels, base.labels);
      expect(c.note, base.note);
      expect(c.timeBlock, base.timeBlock);
      expect(c.id, base.id);
    });

    test('sobrescribe solo los campos indicados', () {
      final c = base.copyWith(rating: 5, labels: ['energy']);
      expect(c.rating, 5);
      expect(c.labels, ['energy']);
      expect(c.note, 'nota original');
      expect(c.timeBlock, 'midday');
    });

    test('clearNote borra la nota aunque no se pase note', () {
      expect(base.copyWith(clearNote: true).note, isNull);
    });

    test('clearNote tiene prioridad sobre note', () {
      expect(base.copyWith(note: 'nueva', clearNote: true).note, isNull);
    });
  });
}
