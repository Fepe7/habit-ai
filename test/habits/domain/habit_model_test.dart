import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/habits/domain/habit_model.dart';
import 'package:habitai/features/habits/domain/habit_visibility.dart';

void main() {
  final now = DateTime(2026, 5, 20, 10, 30);

  Map<String, dynamic> _fullJson() => {
        'title': 'Meditar',
        'description': 'Meditación guiada 10 min',
        'category': 'bienestar',
        'frequency': 'daily',
        'targetDays': [1, 2, 3, 4, 5],
        'reminderTime': '08:00',
        'currentStreak': 7,
        'bestStreak': 14,
        'isAIGenerated': true,
        'createdAt': Timestamp.fromDate(now),
        'isActive': true,
        'groupId': 'g1',
        'challengeId': 'c1',
        'visibility': 'public',
        'stackId': 'stack1',
        'stackOrder': 0,
        'sortOrder': 2,
      };

  group('HabitModel.fromJson', () {
    test('parsea todos los campos', () {
      final h = HabitModel.fromJson(_fullJson(), 'h1');

      expect(h.id, 'h1');
      expect(h.title, 'Meditar');
      expect(h.description, 'Meditación guiada 10 min');
      expect(h.category, 'bienestar');
      expect(h.frequency, 'daily');
      expect(h.targetDays, [1, 2, 3, 4, 5]);
      expect(h.reminderTime, '08:00');
      expect(h.currentStreak, 7);
      expect(h.bestStreak, 14);
      expect(h.isAIGenerated, true);
      expect(h.createdAt, now);
      expect(h.isActive, true);
      expect(h.groupId, 'g1');
      expect(h.challengeId, 'c1');
      expect(h.visibility, 'public');
      expect(h.stackId, 'stack1');
      expect(h.stackOrder, 0);
      expect(h.sortOrder, 2);
      expect(h.stackAfterHabitId, isNull);
    });

    test('defaults cuando faltan campos opcionales', () {
      final h = HabitModel.fromJson({
        'title': 'Leer',
        'createdAt': Timestamp.fromDate(now),
      }, 'h2');

      expect(h.description, '');
      expect(h.category, 'productividad');
      expect(h.frequency, 'daily');
      expect(h.targetDays, isEmpty);
      expect(h.reminderTime, isNull);
      expect(h.currentStreak, 0);
      expect(h.bestStreak, 0);
      expect(h.isAIGenerated, false);
      expect(h.isActive, true);
      expect(h.groupId, isNull);
      expect(h.challengeId, isNull);
      expect(h.visibility, 'private');
      expect(h.stackId, isNull);
      expect(h.stackOrder, 0);
      expect(h.sortOrder, 0);
    });

    test('retrocompat: isPubliclyVisible=true → visibility=public', () {
      final h = HabitModel.fromJson({
        'title': 'X',
        'createdAt': Timestamp.fromDate(now),
        'isPubliclyVisible': true,
      }, 'h3');
      expect(h.visibility, 'public');
    });

    test('retrocompat: isPubliclyVisible=false → visibility=private', () {
      final h = HabitModel.fromJson({
        'title': 'X',
        'createdAt': Timestamp.fromDate(now),
        'isPubliclyVisible': false,
      }, 'h4');
      expect(h.visibility, 'private');
    });

    test('visibility explícito tiene prioridad sobre isPubliclyVisible', () {
      final h = HabitModel.fromJson({
        'title': 'X',
        'createdAt': Timestamp.fromDate(now),
        'visibility': 'followers',
        'isPubliclyVisible': true,
      }, 'h5');
      expect(h.visibility, 'followers');
    });
  });

  group('HabitModel.toJson', () {
    test('roundtrip fromJson → toJson preserva datos', () {
      final original = HabitModel.fromJson(_fullJson(), 'h1');
      final json = original.toJson();
      final restored = HabitModel.fromJson(json, 'h1');

      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.category, original.category);
      expect(restored.frequency, original.frequency);
      expect(restored.targetDays, original.targetDays);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.bestStreak, original.bestStreak);
      expect(restored.isAIGenerated, original.isAIGenerated);
      expect(restored.createdAt, original.createdAt);
      expect(restored.visibility, original.visibility);
      expect(restored.stackId, original.stackId);
      expect(restored.stackOrder, original.stackOrder);
      expect(restored.sortOrder, original.sortOrder);
    });

    test('no incluye stackAfterHabitId', () {
      final h = HabitModel(
        id: 'x',
        title: 'T',
        description: '',
        category: 'salud',
        frequency: 'daily',
        targetDays: [],
        createdAt: now,
        stackAfterHabitId: 'prev',
      );
      expect(h.toJson().containsKey('stackAfterHabitId'), false);
    });
  });

  group('computed getters', () {
    test('isVisibleToAnyone', () {
      expect(
        HabitModel(
          id: '', title: '', description: '', category: '', frequency: '',
          targetDays: [], createdAt: now, visibility: HabitVisibility.public,
        ).isVisibleToAnyone,
        true,
      );
      expect(
        HabitModel(
          id: '', title: '', description: '', category: '', frequency: '',
          targetDays: [], createdAt: now, visibility: HabitVisibility.followers,
        ).isVisibleToAnyone,
        true,
      );
      expect(
        HabitModel(
          id: '', title: '', description: '', category: '', frequency: '',
          targetDays: [], createdAt: now, visibility: HabitVisibility.private,
        ).isVisibleToAnyone,
        false,
      );
    });

    test('isInStack / isStackAnchor', () {
      final noStack = HabitModel(
        id: '', title: '', description: '', category: '', frequency: '',
        targetDays: [], createdAt: now,
      );
      expect(noStack.isInStack, false);
      expect(noStack.isStackAnchor, false);

      final anchor = HabitModel(
        id: '', title: '', description: '', category: '', frequency: '',
        targetDays: [], createdAt: now, stackId: 's1', stackOrder: 0,
      );
      expect(anchor.isInStack, true);
      expect(anchor.isStackAnchor, true);

      final chained = HabitModel(
        id: '', title: '', description: '', category: '', frequency: '',
        targetDays: [], createdAt: now, stackId: 's1', stackOrder: 2,
      );
      expect(chained.isInStack, true);
      expect(chained.isStackAnchor, false);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados, mantiene el resto', () {
      final original = HabitModel.fromJson(_fullJson(), 'h1');
      final copy = original.copyWith(title: 'Yoga', currentStreak: 10);

      expect(copy.title, 'Yoga');
      expect(copy.currentStreak, 10);
      expect(copy.id, original.id);
      expect(copy.description, original.description);
      expect(copy.category, original.category);
    });

    test('clearGroupId pone groupId a null', () {
      final h = HabitModel.fromJson(_fullJson(), 'h1');
      expect(h.groupId, 'g1');
      final cleared = h.copyWith(clearGroupId: true);
      expect(cleared.groupId, isNull);
    });

    test('clearGroupId=false + nuevo groupId', () {
      final h = HabitModel.fromJson(_fullJson(), 'h1');
      final changed = h.copyWith(groupId: 'g2');
      expect(changed.groupId, 'g2');
    });
  });
}
