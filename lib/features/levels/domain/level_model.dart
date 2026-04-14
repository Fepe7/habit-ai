// Sistema de niveles por categoría de hábito
// XP se calcula en tiempo real desde logs y rachas — no se persiste

/// Umbrales de XP acumulado para cada nivel (índice = nivel - 1)
const List<int> kXpThresholds = [0, 200, 600, 1500, 3500];

/// Títulos temáticos por categoría y nivel (índice 0=nivel 1, 4=nivel 5)
const Map<String, List<String>> kCategoryTitles = {
  'salud':         ['Novato', 'Atleta', 'Guerrero', 'Campeón', 'Titán'],
  'productividad': ['Aprendiz', 'Organizado', 'Estratega', 'Ejecutor', 'Maestro'],
  'bienestar':     ['Inquieto', 'Sereno', 'Equilibrado', 'Zen', 'Iluminado'],
  'social':        ['Tímido', 'Amigable', 'Conector', 'Líder', 'Embajador'],
  'aprendizaje':   ['Curioso', 'Estudiante', 'Erudito', 'Sabio', 'Maestro'],
  'finanzas':      ['Ahorrador', 'Prudente', 'Inversor', 'Magnate', 'Mecenas'],
};

/// Nivel de maestría de una categoría concreta
class CategoryLevel {
  final String category;
  final int xp;
  final int level;
  final String titleCurrent;
  final String? titleNext;
  final double progressToNext;
  final int xpToNext;

  const CategoryLevel({
    required this.category,
    required this.xp,
    required this.level,
    required this.titleCurrent,
    this.titleNext,
    required this.progressToNext,
    required this.xpToNext,
  });

  /// Construye un CategoryLevel desde XP acumulado
  factory CategoryLevel.fromXp(String category, int xp) {
    int level = 1;
    for (int i = kXpThresholds.length - 1; i >= 0; i--) {
      if (xp >= kXpThresholds[i]) {
        level = i + 1;
        break;
      }
    }

    final titles = kCategoryTitles[category] ??
        ['Novato', 'Aprendiz', 'Experto', 'Maestro', 'Leyenda'];
    final titleCurrent = titles[level - 1];
    final titleNext = level < 5 ? titles[level] : null;

    final xpCurrent = kXpThresholds[level - 1];
    final xpNext = level < 5 ? kXpThresholds[level] : null;
    final xpToNext = xpNext != null ? (xpNext - xp).clamp(0, xpNext - xpCurrent) : 0;
    final progress = xpNext != null
        ? ((xp - xpCurrent) / (xpNext - xpCurrent)).clamp(0.0, 1.0)
        : 1.0;

    return CategoryLevel(
      category: category,
      xp: xp,
      level: level,
      titleCurrent: titleCurrent,
      titleNext: titleNext,
      progressToNext: progress,
      xpToNext: xpToNext,
    );
  }

  /// Valor normalizado (0.0–1.0) para el radar chart: nivel / 5
  double get radarValue => level / 5.0;
}

/// Perfil completo de maestría del usuario
class LevelsProfile {
  final Map<String, CategoryLevel> categories;

  const LevelsProfile({required this.categories});

  /// Categoría con más XP
  CategoryLevel? get topCategory {
    if (categories.isEmpty) return null;
    return categories.values.reduce((a, b) => a.xp > b.xp ? a : b);
  }

  /// Nivel medio redondeado
  double get averageLevel {
    if (categories.isEmpty) return 1.0;
    final total = categories.values.fold(0, (sum, c) => sum + c.level);
    return total / categories.length;
  }

  /// XP total sumado de todas las categorías
  int get totalXp =>
      categories.values.fold(0, (sum, c) => sum + c.xp);
}
