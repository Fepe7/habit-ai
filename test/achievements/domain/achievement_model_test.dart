import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/achievements/domain/achivement_model.dart';

void main() {
  final now = DateTime(2026, 5, 20);

  group('AchievementModel.fromJson', () {
    test('parsea todos los campos', () {
      final a = AchievementModel.fromJson({
        'type': 'streak_7',
        'unlockedAt': Timestamp.fromDate(now),
        'habitId': 'h1',
      }, 'a1');

      expect(a.id, 'a1');
      expect(a.type, 'streak_7');
      expect(a.unlockedAt, now);
      expect(a.habitId, 'h1');
    });

    test('habitId puede ser null', () {
      final a = AchievementModel.fromJson({
        'type': 'first_habit',
        'unlockedAt': Timestamp.fromDate(now),
      }, 'a2');

      expect(a.habitId, isNull);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = AchievementModel(
        id: 'a1',
        type: 'streak_30',
        unlockedAt: now,
        habitId: 'h1',
      );
      final json = original.toJson();
      final restored = AchievementModel.fromJson(json, 'a1');

      expect(restored.type, original.type);
      expect(restored.unlockedAt, original.unlockedAt);
      expect(restored.habitId, original.habitId);
    });

    test('no incluye id', () {
      final a = AchievementModel(id: 'x', type: 't', unlockedAt: now);
      expect(a.toJson().containsKey('id'), false);
    });
  });

  group('constantes de tipo', () {
    test('12 tipos definidos', () {
      final types = [
        AchievementModel.firstHabit,
        AchievementModel.streak3,
        AchievementModel.streak7,
        AchievementModel.streak14,
        AchievementModel.streak30,
        AchievementModel.aiPlan,
        AchievementModel.allCompleted,
        AchievementModel.habits5,
        AchievementModel.total50,
        AchievementModel.total100,
        AchievementModel.perfectWeek,
        AchievementModel.challengeCompleted,
      ];
      expect(types.length, 12);
      expect(types.toSet().length, 12);
    });
  });

  group('AchievementCatalog', () {
    test('tiene 12 entradas', () {
      expect(AchievementCatalog.all.length, 12);
    });

    test('getInfo devuelve info correcta para tipo conocido', () {
      final info = AchievementCatalog.getInfo('streak_7');
      expect(info.type, 'streak_7');
      expect(info.title, 'Semana de fuego');
      expect(info.icon, Icons.local_fire_department_rounded);
    });

    test('getInfo devuelve fallback para tipo desconocido', () {
      final info = AchievementCatalog.getInfo('unknown_type');
      expect(info.type, 'unknown_type');
      expect(info.title, 'unknown_type');
      expect(info.description, '');
      expect(info.icon, Icons.emoji_events_rounded);
    });

    test('todos los tipos del modelo están en el catálogo', () {
      final catalogTypes = AchievementCatalog.all.map((a) => a.type).toSet();
      expect(catalogTypes.contains(AchievementModel.firstHabit), true);
      expect(catalogTypes.contains(AchievementModel.streak30), true);
      expect(catalogTypes.contains(AchievementModel.challengeCompleted), true);
    });
  });
}
