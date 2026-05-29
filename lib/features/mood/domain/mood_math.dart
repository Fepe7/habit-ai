// Funciones puras de cálculo para el mood tracker.
// Viven fuera de los widgets/repositorios para poder testearse sin Firestore.

/// Media móvil centrada (ventana ±[window]) sobre una serie con huecos (null).
///
/// Devuelve null si el valor central es null, para no inventar puntos donde
/// no hubo registro. Si toda la ventana es null, también devuelve null.
double? centeredMovingAverage(List<double?> values, int index,
    {int window = 2}) {
  if (index < 0 || index >= values.length) return null;
  if (values[index] == null) return null;

  double sum = 0;
  int count = 0;
  for (int j = index - window; j <= index + window; j++) {
    if (j < 0 || j >= values.length) continue;
    final v = values[j];
    if (v != null) {
      sum += v;
      count++;
    }
  }
  return count == 0 ? null : sum / count;
}

/// Etiqueta con signo de una diferencia de ánimo: `+1.2`, `-0.5`, `+0.0`.
String moodDiffLabel(double diff) {
  final sign = diff >= 0 ? '+' : '';
  return '$sign${diff.toStringAsFixed(1)}';
}

/// Nivel de fiabilidad de una correlación según los días con el hábito hecho.
/// 2 = alta (≥15 días), 1 = media (≥5), 0 = baja. Mapea a [MoodConfidence].
int moodConfidenceLevel(int daysCompleted) {
  if (daysCompleted >= 15) return 2;
  if (daysCompleted >= 5) return 1;
  return 0;
}
