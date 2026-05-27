import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/ai/domain/weekly_review_model.dart';

void main() {
  final weekStart = DateTime(2026, 5, 13);
  final weekEnd = DateTime(2026, 5, 19);
  final generatedAt = DateTime(2026, 5, 20);

  Map<String, dynamic> _fullJson() => {
        'weekId': '2026-w20',
        'generatedAt': Timestamp.fromDate(generatedAt),
        'weekStart': Timestamp.fromDate(weekStart),
        'weekEnd': Timestamp.fromDate(weekEnd),
        'stats': {
          'totalLogs': 25,
          'totalHabits': 5,
          'bestHabit': 'Meditar',
          'habitsAtRisk': ['Correr'],
        },
        'wins': ['Racha de 7 días', 'Nuevo hábito'],
        'struggles': ['Horario inconsistente'],
        'recommendations': [
          {
            'habitId': 'h1',
            'habitTitle': 'Correr',
            'action': 'Reducir a 3 días',
            'reason': 'Solo completaste 2 de 5',
          },
        ],
        'focus': 'Mantener constancia',
      };

  group('WeeklyReviewModel.fromJson', () {
    test('parsea todos los campos', () {
      final w = WeeklyReviewModel.fromJson(_fullJson());

      expect(w.weekId, '2026-w20');
      expect(w.generatedAt, generatedAt);
      expect(w.weekStart, weekStart);
      expect(w.weekEnd, weekEnd);
      expect(w.stats.totalLogs, 25);
      expect(w.stats.totalHabits, 5);
      expect(w.stats.bestHabit, 'Meditar');
      expect(w.stats.habitsAtRisk, ['Correr']);
      expect(w.wins.length, 2);
      expect(w.struggles, ['Horario inconsistente']);
      expect(w.recommendations.length, 1);
      expect(w.recommendations[0].habitTitle, 'Correr');
      expect(w.focus, 'Mantener constancia');
    });

    test('defaults', () {
      final w = WeeklyReviewModel.fromJson({
        'weekId': 'w1',
        'weekStart': Timestamp.fromDate(weekStart),
        'weekEnd': Timestamp.fromDate(weekEnd),
      });

      expect(w.wins, isEmpty);
      expect(w.struggles, isEmpty);
      expect(w.recommendations, isEmpty);
      expect(w.focus, '');
    });
  });

  group('WeeklyReviewStats.fromJson', () {
    test('defaults', () {
      final s = WeeklyReviewStats.fromJson({});
      expect(s.totalLogs, 0);
      expect(s.totalHabits, 0);
      expect(s.bestHabit, isNull);
      expect(s.habitsAtRisk, isEmpty);
    });
  });

  group('ReviewRecommendation.fromJson', () {
    test('parsea campos', () {
      final r = ReviewRecommendation.fromJson({
        'habitId': 'h1',
        'habitTitle': 'Test',
        'action': 'Do',
        'reason': 'Because',
      });

      expect(r.habitId, 'h1');
      expect(r.habitTitle, 'Test');
      expect(r.action, 'Do');
      expect(r.reason, 'Because');
    });

    test('defaults', () {
      final r = ReviewRecommendation.fromJson({});
      expect(r.habitId, '');
      expect(r.habitTitle, '');
      expect(r.action, '');
      expect(r.reason, '');
    });
  });
}
