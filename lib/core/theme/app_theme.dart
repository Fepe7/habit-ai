import 'package:flutter/material.dart';

class AppTheme {
  // colores principales
  static const Color primary = Color(0xFF38BDF8);     // azul cielo
  static const Color secondary = Color(0xFF0EA5E9);   // azul mas intenso
  static const Color success = Color(0xFF10B981);     // verde (habito completado)
  static const Color accent = Color(0xFFF59E0B);      // ambar (rachas, logros)
  static const Color error = Color(0xFFEF4444);

  // textos
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      error: error,
      surface: const Color(0xFFF0F9FF),
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      error: error,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0F172A),
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFF1E293B),
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

      // bottom nav bar con etiquetas
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),

      // snackbars y dialogs redondeados
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // colores por categoria (fondo + texto)
  static Color categoryBg(String category) {
    switch (category) {
      case 'salud':
        return const Color(0xFFCCFBF1);
      case 'productividad':
        return const Color(0xFFE0F2FE);
      case 'bienestar':
        return const Color(0xFFFEF3C7);
      case 'social':
        return const Color(0xFFFCE7F3);
      case 'aprendizaje':
        return const Color(0xFFEDE9FE);
      case 'finanzas':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  static Color categoryFg(String category) {
    switch (category) {
      case 'salud':
        return const Color(0xFF115E59);
      case 'productividad':
        return const Color(0xFF0C4A6E);
      case 'bienestar':
        return const Color(0xFF92400E);
      case 'social':
        return const Color(0xFF9D174D);
      case 'aprendizaje':
        return const Color(0xFF5B21B6);
      case 'finanzas':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF374151);
    }
  }
}
