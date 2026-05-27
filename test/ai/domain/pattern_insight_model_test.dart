import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/ai/domain/pattern_insight_model.dart';

void main() {
  final periodStart = DateTime(2026, 5, 1);
  final periodEnd = DateTime(2026, 5, 14);
  final generatedAt = DateTime(2026, 5, 15);

  group('PatternInsightModel.fromJson', () {
    test('parsea campos completos', () {
      final p = PatternInsightModel.fromJson({
        'periodId': '2026-w20',
        'generatedAt': Timestamp.fromDate(generatedAt),
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
        'stats': {
          'totalHabits': 5,
          'totalLogs': 30,
          'analyzedDays': 14,
        },
        'insights': [
          {
            'type': 'day_effect',
            'title': 'Lunes fuerte',
            'description': 'Más completados los lunes',
            'relatedHabits': ['Meditar', 'Leer'],
            'confidence': 'high',
            'actionable': 'Agenda más el lunes',
          },
        ],
        'summary': 'Buen rendimiento',
        'dataQuality': 'good',
      });

      expect(p.periodId, '2026-w20');
      expect(p.generatedAt, generatedAt);
      expect(p.periodStart, periodStart);
      expect(p.periodEnd, periodEnd);
      expect(p.stats.totalHabits, 5);
      expect(p.insights.length, 1);
      expect(p.insights[0].type, PatternType.dayEffect);
      expect(p.insights[0].title, 'Lunes fuerte');
      expect(p.summary, 'Buen rendimiento');
      expect(p.dataQuality, 'good');
    });

    test('defaults', () {
      final p = PatternInsightModel.fromJson({
        'periodId': 'x',
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
      });

      expect(p.insights, isEmpty);
      expect(p.summary, '');
      expect(p.dataQuality, 'limited');
    });
  });

  group('PatternInsightStats.fromJson', () {
    test('defaults', () {
      final s = PatternInsightStats.fromJson({});
      expect(s.totalHabits, 0);
      expect(s.totalLogs, 0);
      expect(s.analyzedDays, 0);
    });
  });

  group('PatternType.fromString', () {
    test('mapea todos los valores válidos', () {
      expect(PatternType.fromString('day_effect'), PatternType.dayEffect);
      expect(PatternType.fromString('cross_habit'), PatternType.crossHabit);
      expect(PatternType.fromString('time_cluster'), PatternType.timeCluster);
      expect(
          PatternType.fromString('category_synergy'), PatternType.categorySynergy);
      expect(
          PatternType.fromString('streak_predictor'), PatternType.streakPredictor);
      expect(PatternType.fromString('vulnerability'), PatternType.vulnerability);
    });

    test('default para valor desconocido', () {
      expect(PatternType.fromString('xyz'), PatternType.crossHabit);
      expect(PatternType.fromString(''), PatternType.crossHabit);
    });
  });

  group('PatternType propiedades', () {
    test('todos tienen label no vacío', () {
      for (final t in PatternType.values) {
        expect(t.label.isNotEmpty, true, reason: '$t sin label');
      }
    });

    test('todos tienen icon', () {
      for (final t in PatternType.values) {
        expect(t.icon, isA<IconData>(), reason: '$t sin icon');
      }
    });

    test('todos tienen color', () {
      for (final t in PatternType.values) {
        expect(t.color, isA<Color>(), reason: '$t sin color');
      }
    });
  });

  group('PatternInsight', () {
    test('fromJson defaults', () {
      final i = PatternInsight.fromJson({});
      expect(i.type, PatternType.crossHabit);
      expect(i.title, '');
      expect(i.description, '');
      expect(i.relatedHabits, isEmpty);
      expect(i.confidence, 'medium');
      expect(i.actionable, '');
    });

    test('confidenceColor', () {
      final high = PatternInsight(
        type: PatternType.dayEffect, title: '', description: '',
        relatedHabits: [], confidence: 'high', actionable: '',
      );
      expect(high.confidenceColor, const Color(0xFF10B981));

      final medium = PatternInsight(
        type: PatternType.dayEffect, title: '', description: '',
        relatedHabits: [], confidence: 'medium', actionable: '',
      );
      expect(medium.confidenceColor, const Color(0xFFF59E0B));

      final low = PatternInsight(
        type: PatternType.dayEffect, title: '', description: '',
        relatedHabits: [], confidence: 'low', actionable: '',
      );
      expect(low.confidenceColor, const Color(0xFF94A3B8));
    });
  });
}
