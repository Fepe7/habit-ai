import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/mood/domain/mood_math.dart';

void main() {
  group('centeredMovingAverage', () {
    test('media de una serie completa (ventana ±2)', () {
      final v = [1.0, 2.0, 3.0, 4.0, 5.0];
      // índice 2: (1+2+3+4+5)/5 = 3
      expect(centeredMovingAverage(v, 2), 3.0);
    });

    test('en los bordes recorta la ventana', () {
      final v = [1.0, 2.0, 3.0, 4.0, 5.0];
      // índice 0: (1+2+3)/3 = 2
      expect(centeredMovingAverage(v, 0), 2.0);
      // índice 4: (3+4+5)/3 = 4
      expect(centeredMovingAverage(v, 4), 4.0);
    });

    test('ignora los huecos (null) dentro de la ventana', () {
      final v = <double?>[1.0, null, 3.0, null, 5.0];
      // índice 2: (1+3+5)/3 = 3
      expect(centeredMovingAverage(v, 2), 3.0);
    });

    test('devuelve null si el valor central es null', () {
      final v = <double?>[1.0, null, 3.0];
      expect(centeredMovingAverage(v, 1), isNull);
    });

    test('devuelve null fuera de rango', () {
      final v = [1.0, 2.0];
      expect(centeredMovingAverage(v, -1), isNull);
      expect(centeredMovingAverage(v, 5), isNull);
    });

    test('ventana personalizada', () {
      final v = [1.0, 2.0, 3.0, 4.0, 5.0];
      // ventana ±1 en índice 2: (2+3+4)/3 = 3
      expect(centeredMovingAverage(v, 2, window: 1), 3.0);
      // ventana ±1 en índice 0: (1+2)/2 = 1.5
      expect(centeredMovingAverage(v, 0, window: 1), 1.5);
    });

    test('valor único en la ventana se devuelve tal cual', () {
      final v = <double?>[null, null, 4.0, null, null];
      expect(centeredMovingAverage(v, 2), 4.0);
    });
  });

  group('moodDiffLabel', () {
    test('diferencia positiva lleva signo +', () {
      expect(moodDiffLabel(1.24), '+1.2');
      expect(moodDiffLabel(0.05), '+0.1');
    });

    test('cero se considera positivo (+0.0)', () {
      expect(moodDiffLabel(0), '+0.0');
    });

    test('diferencia negativa conserva el signo -', () {
      expect(moodDiffLabel(-0.5), '-0.5');
      expect(moodDiffLabel(-2.06), '-2.1');
    });
  });

  group('moodConfidenceLevel', () {
    test('alta con 15+ días', () {
      expect(moodConfidenceLevel(15), 2);
      expect(moodConfidenceLevel(40), 2);
    });

    test('media entre 5 y 14 días', () {
      expect(moodConfidenceLevel(5), 1);
      expect(moodConfidenceLevel(14), 1);
    });

    test('baja con menos de 5 días', () {
      expect(moodConfidenceLevel(0), 0);
      expect(moodConfidenceLevel(4), 0);
    });
  });
}
