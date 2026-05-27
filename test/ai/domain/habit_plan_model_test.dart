import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/ai/domain/habit_plan_model.dart';

void main() {
  Map<String, dynamic> _fullJson() => {
        'planTitle': 'Plan matutino',
        'planEmoji': '🌅',
        'planDescription': 'Rutina para empezar bien el día',
        'habits': [
          {
            'title': 'Meditar',
            'description': '10 min meditación guiada',
            'category': 'bienestar',
            'frequency': 'daily',
            'targetDays': [1, 2, 3, 4, 5],
            'suggestedTime': '07:00',
            'estimatedMinutes': 10,
            'difficultyLevel': 'easy',
          },
          {
            'title': 'Leer',
            'description': '20 páginas',
            'category': 'aprendizaje',
            'frequency': 'daily',
            'targetDays': [1, 2, 3, 4, 5, 6, 7],
          },
        ],
        'coachMessage': 'Empieza poco a poco',
      };

  group('HabitPlanModel.fromJson', () {
    test('parsea todos los campos', () {
      final p = HabitPlanModel.fromJson(_fullJson());

      expect(p.planTitle, 'Plan matutino');
      expect(p.planEmoji, '🌅');
      expect(p.planDescription, 'Rutina para empezar bien el día');
      expect(p.habits.length, 2);
      expect(p.coachMessage, 'Empieza poco a poco');
    });

    test('defaults', () {
      final p = HabitPlanModel.fromJson({});

      expect(p.planTitle, 'Tu plan personalizado');
      expect(p.planEmoji, isNull);
      expect(p.planDescription, '');
      expect(p.habits, isEmpty);
      expect(p.coachMessage, '');
    });
  });

  group('GeneratedHabitModel.fromJson', () {
    test('parsea campos completos', () {
      final h = GeneratedHabitModel.fromJson({
        'title': 'Correr',
        'description': '30 min',
        'category': 'salud',
        'frequency': 'weekly',
        'targetDays': [1, 3, 5],
        'suggestedTime': '18:00',
        'estimatedMinutes': 30,
        'difficultyLevel': 'hard',
      });

      expect(h.title, 'Correr');
      expect(h.description, '30 min');
      expect(h.category, 'salud');
      expect(h.frequency, 'weekly');
      expect(h.targetDays, [1, 3, 5]);
      expect(h.suggestedTime, '18:00');
      expect(h.estimatedMinutes, 30);
      expect(h.difficultyLevel, 'hard');
    });

    test('defaults', () {
      final h = GeneratedHabitModel.fromJson({'title': 'X'});

      expect(h.description, '');
      expect(h.category, 'productividad');
      expect(h.frequency, 'daily');
      expect(h.targetDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(h.suggestedTime, isNull);
      expect(h.estimatedMinutes, 15);
      expect(h.difficultyLevel, 'medium');
    });
  });

  group('GeneratedHabitModel.toHabitModel', () {
    test('convierte correctamente', () {
      final gen = GeneratedHabitModel(
        title: 'Test',
        description: 'Desc',
        category: 'salud',
        frequency: 'daily',
        targetDays: [1, 2],
        suggestedTime: '09:00',
      );
      final habit = gen.toHabitModel(groupId: 'g1');

      expect(habit.id, '');
      expect(habit.title, 'Test');
      expect(habit.description, 'Desc');
      expect(habit.category, 'salud');
      expect(habit.frequency, 'daily');
      expect(habit.targetDays, [1, 2]);
      expect(habit.reminderTime, '09:00');
      expect(habit.isAIGenerated, true);
      expect(habit.groupId, 'g1');
    });

    test('sin groupId', () {
      final gen = GeneratedHabitModel(
        title: 'T',
        description: '',
        category: 'c',
        frequency: 'f',
        targetDays: [],
      );
      final habit = gen.toHabitModel();
      expect(habit.groupId, isNull);
    });
  });
}
