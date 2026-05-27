import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/ai/domain/butterfly_projection_model.dart';

void main() {
  final monthStart = DateTime(2026, 5, 1);
  final monthEnd = DateTime(2026, 5, 31);
  final generatedAt = DateTime(2026, 5, 20);

  Map<String, dynamic> _fullJson() => {
        'monthId': '2026-05',
        'generatedAt': Timestamp.fromDate(generatedAt),
        'monthStart': Timestamp.fromDate(monthStart),
        'monthEnd': Timestamp.fromDate(monthEnd),
        'stats': {
          'totalLogs': 45,
          'activeHabits': 5,
          'completionRate': 0.82,
          'topCategories': ['salud', 'productividad'],
          'longestStreak': 12,
        },
        'titleKeep': 'Futuro brillante',
        'storyKeep': 'Historia positiva...',
        'titleAbandon': 'Oportunidad perdida',
        'storyAbandon': 'Historia negativa...',
        'keyMoments': [
          {'habitTitle': 'Meditar', 'impact': 'Reduce estrés'},
          {'habitTitle': 'Leer', 'impact': 'Más conocimiento'},
        ],
        'closingMessage': 'Sigue así',
      };

  group('ButterflyProjectionModel.fromJson', () {
    test('parsea todos los campos', () {
      final b = ButterflyProjectionModel.fromJson(_fullJson());

      expect(b.monthId, '2026-05');
      expect(b.generatedAt, generatedAt);
      expect(b.monthStart, monthStart);
      expect(b.monthEnd, monthEnd);
      expect(b.titleKeep, 'Futuro brillante');
      expect(b.storyKeep, 'Historia positiva...');
      expect(b.titleAbandon, 'Oportunidad perdida');
      expect(b.storyAbandon, 'Historia negativa...');
      expect(b.keyMoments.length, 2);
      expect(b.keyMoments[0].habitTitle, 'Meditar');
      expect(b.keyMoments[1].impact, 'Más conocimiento');
      expect(b.closingMessage, 'Sigue así');
    });

    test('defaults en campos opcionales', () {
      final b = ButterflyProjectionModel.fromJson({
        'monthId': '2026-05',
        'monthStart': Timestamp.fromDate(monthStart),
        'monthEnd': Timestamp.fromDate(monthEnd),
      });

      expect(b.titleKeep, '');
      expect(b.storyKeep, '');
      expect(b.titleAbandon, '');
      expect(b.storyAbandon, '');
      expect(b.keyMoments, isEmpty);
      expect(b.closingMessage, '');
    });
  });

  group('ButterflyStats.fromJson', () {
    test('parsea campos', () {
      final s = ButterflyStats.fromJson({
        'totalLogs': 45,
        'activeHabits': 5,
        'completionRate': 0.82,
        'topCategories': ['salud'],
        'longestStreak': 12,
      });

      expect(s.totalLogs, 45);
      expect(s.activeHabits, 5);
      expect(s.completionRate, 0.82);
      expect(s.topCategories, ['salud']);
      expect(s.longestStreak, 12);
    });

    test('defaults', () {
      final s = ButterflyStats.fromJson({});

      expect(s.totalLogs, 0);
      expect(s.activeHabits, 0);
      expect(s.completionRate, 0.0);
      expect(s.topCategories, isEmpty);
      expect(s.longestStreak, 0);
    });
  });

  group('ButterflyKeyMoment.fromJson', () {
    test('defaults', () {
      final k = ButterflyKeyMoment.fromJson({});
      expect(k.habitTitle, '');
      expect(k.impact, '');
    });
  });
}
