import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/levels/domain/level_model.dart';

void main() {
  group('CategoryLevel.fromXp', () {
    test('0 XP → nivel 1', () {
      final l = CategoryLevel.fromXp('salud', 0);
      expect(l.level, 1);
      expect(l.titleCurrent, 'Novato');
      expect(l.titleNext, 'Atleta');
      expect(l.xpToNext, 200);
      expect(l.progressToNext, 0.0);
    });

    test('100 XP → nivel 1, 50% progreso', () {
      final l = CategoryLevel.fromXp('salud', 100);
      expect(l.level, 1);
      expect(l.progressToNext, 0.5);
      expect(l.xpToNext, 100);
    });

    test('200 XP → nivel 2', () {
      final l = CategoryLevel.fromXp('salud', 200);
      expect(l.level, 2);
      expect(l.titleCurrent, 'Atleta');
      expect(l.titleNext, 'Guerrero');
    });

    test('600 XP → nivel 3', () {
      final l = CategoryLevel.fromXp('productividad', 600);
      expect(l.level, 3);
      expect(l.titleCurrent, 'Estratega');
    });

    test('1500 XP → nivel 4', () {
      final l = CategoryLevel.fromXp('bienestar', 1500);
      expect(l.level, 4);
      expect(l.titleCurrent, 'Zen');
    });

    test('3500 XP → nivel 5 (máximo)', () {
      final l = CategoryLevel.fromXp('social', 3500);
      expect(l.level, 5);
      expect(l.titleCurrent, 'Embajador');
      expect(l.titleNext, isNull);
      expect(l.xpToNext, 0);
      expect(l.progressToNext, 1.0);
    });

    test('XP muy alto sigue siendo nivel 5', () {
      final l = CategoryLevel.fromXp('finanzas', 99999);
      expect(l.level, 5);
      expect(l.titleCurrent, 'Mecenas');
    });

    test('categoría desconocida usa fallback', () {
      final l = CategoryLevel.fromXp('custom_category', 0);
      expect(l.level, 1);
      expect(l.titleCurrent, 'Novato');
    });

    test('radarValue', () {
      expect(CategoryLevel.fromXp('salud', 0).radarValue, 0.2);
      expect(CategoryLevel.fromXp('salud', 3500).radarValue, 1.0);
    });

    test('todas las categorías conocidas tienen títulos', () {
      for (final cat in ['salud', 'productividad', 'bienestar', 'social', 'aprendizaje', 'finanzas']) {
        final l = CategoryLevel.fromXp(cat, 0);
        expect(l.titleCurrent.isNotEmpty, true, reason: '$cat sin título');
      }
    });
  });

  group('LevelsProfile', () {
    test('topCategory devuelve la de más XP', () {
      final profile = LevelsProfile(categories: {
        'salud': CategoryLevel.fromXp('salud', 500),
        'productividad': CategoryLevel.fromXp('productividad', 1000),
        'bienestar': CategoryLevel.fromXp('bienestar', 100),
      });

      expect(profile.topCategory!.category, 'productividad');
    });

    test('topCategory null si vacío', () {
      final profile = LevelsProfile(categories: {});
      expect(profile.topCategory, isNull);
    });

    test('averageLevel', () {
      final profile = LevelsProfile(categories: {
        'salud': CategoryLevel.fromXp('salud', 0),
        'productividad': CategoryLevel.fromXp('productividad', 3500),
      });
      expect(profile.averageLevel, 3.0);
    });

    test('averageLevel vacío = 1.0', () {
      final profile = LevelsProfile(categories: {});
      expect(profile.averageLevel, 1.0);
    });

    test('totalXp', () {
      final profile = LevelsProfile(categories: {
        'salud': CategoryLevel.fromXp('salud', 100),
        'productividad': CategoryLevel.fromXp('productividad', 200),
      });
      expect(profile.totalXp, 300);
    });
  });
}
