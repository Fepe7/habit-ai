import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/habits/domain/habit_group_model.dart';

void main() {
  final now = DateTime(2026, 5, 20);

  Map<String, dynamic> _fullJson() => {
        'title': 'Rutina mañana',
        'emoji': '🌅',
        'description': 'Hábitos matutinos',
        'createdAt': Timestamp.fromDate(now),
        'conversationId': 'conv1',
        'habitCount': 3,
        'isActive': true,
        'publishedTemplateId': 'tmpl1',
      };

  group('fromJson', () {
    test('parsea todos los campos', () {
      final g = HabitGroupModel.fromJson(_fullJson(), 'g1');

      expect(g.id, 'g1');
      expect(g.title, 'Rutina mañana');
      expect(g.emoji, '🌅');
      expect(g.description, 'Hábitos matutinos');
      expect(g.createdAt, now);
      expect(g.conversationId, 'conv1');
      expect(g.habitCount, 3);
      expect(g.isActive, true);
      expect(g.publishedTemplateId, 'tmpl1');
    });

    test('defaults', () {
      final g = HabitGroupModel.fromJson({
        'title': 'Grupo',
        'createdAt': Timestamp.fromDate(now),
      }, 'g2');

      expect(g.emoji, isNull);
      expect(g.description, isNull);
      expect(g.conversationId, isNull);
      expect(g.habitCount, 0);
      expect(g.isActive, true);
      expect(g.publishedTemplateId, isNull);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = HabitGroupModel.fromJson(_fullJson(), 'g1');
      final json = original.toJson();
      final restored = HabitGroupModel.fromJson(json, 'g1');

      expect(restored.title, original.title);
      expect(restored.emoji, original.emoji);
      expect(restored.habitCount, original.habitCount);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final g = HabitGroupModel.fromJson(_fullJson(), 'g1');
      final copy = g.copyWith(title: 'Nuevo', habitCount: 5);

      expect(copy.title, 'Nuevo');
      expect(copy.habitCount, 5);
      expect(copy.emoji, g.emoji);
      expect(copy.id, g.id);
    });

    test('isActive', () {
      final g = HabitGroupModel.fromJson(_fullJson(), 'g1');
      final copy = g.copyWith(isActive: false);
      expect(copy.isActive, false);
    });

    test('publishedTemplateId', () {
      final g = HabitGroupModel.fromJson(_fullJson(), 'g1');
      final copy = g.copyWith(publishedTemplateId: 'tmpl2');
      expect(copy.publishedTemplateId, 'tmpl2');
    });
  });
}
