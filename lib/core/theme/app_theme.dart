import 'package:flutter/material.dart';

class AppTheme {
  static const Color seedColor = Color(0xFF6750A4); // violeta Material 3

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  // tema comun para light y dark
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // cards planas con bordes redondeados
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // botones a ancho completo
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // inputs con fondo y bordes redondeados
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // appbar sin sombra
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
      ),

      // bottom nav bar con M3
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  // colores por categoria de habito
  static Color categoryColor(String category, ColorScheme scheme) {
    switch (category) {
      case 'salud':
        return const Color(0xFF4CAF50);
      case 'productividad':
        return scheme.primary;
      case 'bienestar':
        return const Color(0xFF42A5F5);
      case 'social':
        return const Color(0xFFFF7043);
      case 'aprendizaje':
        return const Color(0xFFAB47BC);
      case 'finanzas':
        return const Color(0xFF66BB6A);
      default:
        return scheme.tertiary;
    }
  }
}
