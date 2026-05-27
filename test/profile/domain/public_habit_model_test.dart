import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/profile/domain/public_habit_model.dart';

void main() {
  group('PublicHabitModel.fromFirestore', () {
    test('parsea todos los campos', () {
      final h = PublicHabitModel.fromFirestore({
        'title': 'Meditar',
        'category': 'bienestar',
        'emoji': '🧘',
        'currentStreak': 7,
        'bestStreak': 14,
        'visibility': 'followers',
      }, 'h1');

      expect(h.id, 'h1');
      expect(h.title, 'Meditar');
      expect(h.category, 'bienestar');
      expect(h.emoji, '🧘');
      expect(h.currentStreak, 7);
      expect(h.bestStreak, 14);
      expect(h.visibility, 'followers');
    });

    test('defaults', () {
      final h = PublicHabitModel.fromFirestore({}, 'h2');

      expect(h.title, '');
      expect(h.category, 'productividad');
      expect(h.emoji, isNull);
      expect(h.currentStreak, 0);
      expect(h.bestStreak, 0);
      expect(h.visibility, 'public');
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = PublicHabitModel(
        id: 'h1',
        title: 'Test',
        category: 'salud',
        emoji: '🏃',
        currentStreak: 5,
        bestStreak: 10,
        visibility: 'followers',
      );
      final json = original.toJson();
      final restored = PublicHabitModel.fromFirestore(json, 'h1');

      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.emoji, original.emoji);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.bestStreak, original.bestStreak);
      expect(restored.visibility, original.visibility);
    });

    test('no incluye id', () {
      final h = PublicHabitModel(
        id: 'x', title: 'T', category: 'c', currentStreak: 0, bestStreak: 0,
      );
      expect(h.toJson().containsKey('id'), false);
    });
  });
}
