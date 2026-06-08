import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

/// Resuelve etiquetas de categoría y títulos de nivel localizados
/// sin tocar la capa de dominio.
class CategoryL10n {
  /// Versión de conveniencia que resuelve la localización desde el [context].
  static String labelOf(String category, BuildContext context) =>
      label(category, S.of(context));

  static String label(String category, S l10n) {
    switch (category) {
      case 'salud':
        return l10n.categorySalud;
      case 'productividad':
        return l10n.categoryProductividad;
      case 'bienestar':
        return l10n.categoryBienestar;
      case 'social':
        return l10n.categorySocial;
      case 'aprendizaje':
        return l10n.categoryAprendizaje;
      case 'finanzas':
        return l10n.categoryFinanzas;
      default:
        return category.isEmpty
            ? category
            : category[0].toUpperCase() + category.substring(1);
    }
  }

  static String levelTitle(String category, int level, S l10n) {
    switch (category) {
      case 'salud':
        return _pick(level, [
          l10n.levelSalud1, l10n.levelSalud2, l10n.levelSalud3,
          l10n.levelSalud4, l10n.levelSalud5,
        ]);
      case 'productividad':
        return _pick(level, [
          l10n.levelProductividad1, l10n.levelProductividad2, l10n.levelProductividad3,
          l10n.levelProductividad4, l10n.levelProductividad5,
        ]);
      case 'bienestar':
        return _pick(level, [
          l10n.levelBienestar1, l10n.levelBienestar2, l10n.levelBienestar3,
          l10n.levelBienestar4, l10n.levelBienestar5,
        ]);
      case 'social':
        return _pick(level, [
          l10n.levelSocial1, l10n.levelSocial2, l10n.levelSocial3,
          l10n.levelSocial4, l10n.levelSocial5,
        ]);
      case 'aprendizaje':
        return _pick(level, [
          l10n.levelAprendizaje1, l10n.levelAprendizaje2, l10n.levelAprendizaje3,
          l10n.levelAprendizaje4, l10n.levelAprendizaje5,
        ]);
      case 'finanzas':
        return _pick(level, [
          l10n.levelFinanzas1, l10n.levelFinanzas2, l10n.levelFinanzas3,
          l10n.levelFinanzas4, l10n.levelFinanzas5,
        ]);
      default:
        return level.toString();
    }
  }

  static String _pick(int level, List<String> titles) =>
      titles[(level - 1).clamp(0, titles.length - 1)];
}
