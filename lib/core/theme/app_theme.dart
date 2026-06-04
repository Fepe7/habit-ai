import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jerarquia por superficie, sin bordes 1px duros, radios grandes, tipografia dual Manrope+Inter
class AppTheme {
  // paleta core Stitch
  static const Color primary = Color(0xFF00668A);
  static const Color primaryContainer = Color(0xFF38BDF8);
  static const Color primaryFixed = Color(0xFFC4E7FF);
  static const Color primaryFixedDim = Color(0xFF7BD0FF);

  static const Color secondary = Color(0xFF006591);
  static const Color secondaryContainer = Color(0xFF39B8FD);

  static const Color tertiary = Color(0xFF855300);
  static const Color tertiaryContainer = Color(0xFFF59E0B);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // surfaces
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceDim = Color(0xFFCBDBF5);

  // textos
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF3E484F);
  static const Color outline = Color(0xFF6E7980);
  static const Color outlineVariant = Color(0xFFBDC8D1);

  // dark surfaces
  static const Color darkSurface = Color(0xFF0F1620);
  static const Color darkSurfaceContainerLowest = Color(0xFF0A1119);
  static const Color darkSurfaceContainerLow = Color(0xFF141D28);
  static const Color darkSurfaceContainerHighest = Color(0xFF1F2A38);
  static const Color darkOnSurface = Color(0xFFE2E8F0);

  // aliases compat (viejo codigo)
  static const Color success = tertiaryContainer;
  static const Color accent = tertiaryContainer;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // helpers visuales
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiary, tertiaryContainer],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF34D399)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, errorContainer],
  );

  static List<BoxShadow> ambientShadow({double opacity = 0.06}) => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 24,
      color: onSurface.withValues(alpha: opacity),
    ),
  ];

  // sombra con tinte de color — para cards con logros o rachas destacadas
  static List<BoxShadow> tintedShadow(
    Color color, {
    double opacity = 0.22,
    double blurRadius = 16,
  }) => [
    BoxShadow(
      offset: const Offset(0, 6),
      blurRadius: blurRadius,
      color: color.withValues(alpha: opacity),
    ),
  ];

  static Border get ghostBorder => Border.all(
    color: outlineVariant.withValues(alpha: 0.15),
    width: 1,
  );

  // temas
  static ThemeData get lightTheme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF004965),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF004666),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF613B00),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF93000A),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceDim: surfaceDim,
      outline: outline,
      outlineVariant: outlineVariant,
    );
    return _buildTheme(scheme);
  }

  static ThemeData get darkTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryContainer,
      onPrimary: Color(0xFF001E2C),
      primaryContainer: Color(0xFF004C69),
      onPrimaryContainer: primaryFixed,
      secondary: secondaryContainer,
      onSecondary: Color(0xFF001E2F),
      secondaryContainer: Color(0xFF004C6E),
      onSecondaryContainer: Color(0xFFC9E6FF),
      tertiary: tertiaryContainer,
      onTertiary: Color(0xFF2A1700),
      tertiaryContainer: Color(0xFF653E00),
      onTertiaryContainer: Color(0xFFFFDDB8),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: Color(0xFFBDC7D1),
      surfaceContainerLowest: darkSurfaceContainerLowest,
      surfaceContainerLow: darkSurfaceContainerLow,
      surfaceContainer: Color(0xFF1A2432),
      surfaceContainerHigh: Color(0xFF1D2836),
      surfaceContainerHighest: darkSurfaceContainerHighest,
      surfaceDim: Color(0xFF0A1119),
      outline: Color(0xFF87919B),
      outlineVariant: Color(0xFF3E484F),
    );
    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // tipografia dual: Manrope para display/headlines, Inter para body/labels
    final display = GoogleFonts.manropeTextTheme(base.textTheme);
    final body = GoogleFonts.interTextTheme(base.textTheme);

    final textTheme = base.textTheme.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.12,
        color: scheme.onSurface,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.88,
        color: scheme.onSurface,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.18,
        color: scheme.onSurface,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.25),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.4,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.15),
        thickness: 1,
        space: 0,
      ),
    );
  }

  // colores por categoria (fondo + texto). valores ajustados para combinar con Editorial Vitality.
  // En modo oscuro se devuelven variantes profundas (bg) + claras (fg) para mantener el contraste,
  // igual que MoodTheme. El parámetro brightness es opcional (default light) por compatibilidad.
  static Color categoryBg(String category, [Brightness brightness = Brightness.light]) {
    if (brightness == Brightness.dark) {
      switch (category) {
        case 'salud':
          return const Color(0xFF042F2E);
        case 'productividad':
          return const Color(0xFF082F49);
        case 'bienestar':
          return const Color(0xFF422006);
        case 'social':
          return const Color(0xFF500724);
        case 'aprendizaje':
          return const Color(0xFF2E1065);
        case 'finanzas':
          return const Color(0xFF450A0A);
        default:
          return const Color(0xFF1A2432);
      }
    }
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
        return const Color(0xFFE5EEFF);
    }
  }

  static Color categoryFg(String category, [Brightness brightness = Brightness.light]) {
    if (brightness == Brightness.dark) {
      switch (category) {
        case 'salud':
          return const Color(0xFF5EEAD4);
        case 'productividad':
          return const Color(0xFF7DD3FC);
        case 'bienestar':
          return const Color(0xFFFCD34D);
        case 'social':
          return const Color(0xFFF9A8D4);
        case 'aprendizaje':
          return const Color(0xFFC4B5FD);
        case 'finanzas':
          return const Color(0xFFFCA5A5);
        default:
          return const Color(0xFFBDC7D1);
      }
    }
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
        return const Color(0xFF3E484F);
    }
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'salud':
        return Icons.favorite_rounded;
      case 'productividad':
        return Icons.rocket_launch_rounded;
      case 'bienestar':
        return Icons.spa_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'aprendizaje':
        return Icons.school_rounded;
      case 'finanzas':
        return Icons.savings_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'salud':
        return 'Salud';
      case 'productividad':
        return 'Productividad';
      case 'bienestar':
        return 'Bienestar';
      case 'social':
        return 'Social';
      case 'aprendizaje':
        return 'Aprendizaje';
      case 'finanzas':
        return 'Finanzas';
      default:
        return category.isEmpty
            ? category
            : category[0].toUpperCase() + category.substring(1);
    }
  }

  static const List<String> categories = [
    'salud',
    'productividad',
    'bienestar',
    'social',
    'aprendizaje',
    'finanzas',
  ];
}
