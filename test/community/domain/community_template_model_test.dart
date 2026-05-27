import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/community/domain/community_template_model.dart';

void main() {
  final createdAt = DateTime(2026, 5, 10);
  final updatedAt = DateTime(2026, 5, 20);

  Map<String, dynamic> _fullJson() => {
        'authorUid': 'u1',
        'authorUsername': 'andrei',
        'authorDisplayName': 'Andrei S',
        'title': 'Rutina matutina',
        'emoji': '🌅',
        'description': 'Hábitos para empezar el día',
        'category': 'bienestar',
        'habitCount': 4,
        'importCount': 12,
        'reportCount': 0,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'authorPhotoUrl': 'https://example.com/photo.jpg',
      };

  group('fromJson', () {
    test('parsea todos los campos', () {
      final t = CommunityTemplateModel.fromJson(_fullJson(), 't1');

      expect(t.id, 't1');
      expect(t.authorUid, 'u1');
      expect(t.authorUsername, 'andrei');
      expect(t.authorDisplayName, 'Andrei S');
      expect(t.title, 'Rutina matutina');
      expect(t.emoji, '🌅');
      expect(t.description, 'Hábitos para empezar el día');
      expect(t.category, 'bienestar');
      expect(t.habitCount, 4);
      expect(t.importCount, 12);
      expect(t.reportCount, 0);
      expect(t.createdAt, createdAt);
      expect(t.updatedAt, updatedAt);
      expect(t.authorPhotoUrl, 'https://example.com/photo.jpg');
    });

    test('defaults', () {
      final t = CommunityTemplateModel.fromJson({
        'authorUid': 'u1',
        'title': 'T',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      }, 't2');

      expect(t.authorUsername, '');
      expect(t.authorDisplayName, '');
      expect(t.emoji, isNull);
      expect(t.description, '');
      expect(t.category, 'productividad');
      expect(t.habitCount, 0);
      expect(t.importCount, 0);
      expect(t.reportCount, 0);
      expect(t.authorPhotoUrl, isNull);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = CommunityTemplateModel.fromJson(_fullJson(), 't1');
      final json = original.toJson();
      final restored = CommunityTemplateModel.fromJson(json, 't1');

      expect(restored.title, original.title);
      expect(restored.authorUid, original.authorUid);
      expect(restored.category, original.category);
      expect(restored.importCount, original.importCount);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('copyWith', () {
    test('cambia campos indicados', () {
      final t = CommunityTemplateModel.fromJson(_fullJson(), 't1');
      final copy = t.copyWith(importCount: 20, reportCount: 1);

      expect(copy.importCount, 20);
      expect(copy.reportCount, 1);
      expect(copy.title, t.title);
      expect(copy.id, t.id);
    });

    test('authorPhotoUrl', () {
      final t = CommunityTemplateModel.fromJson(_fullJson(), 't1');
      final copy = t.copyWith(authorPhotoUrl: 'https://new.url/photo.jpg');
      expect(copy.authorPhotoUrl, 'https://new.url/photo.jpg');
    });
  });
}
