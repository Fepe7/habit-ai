---
name: ui-design
description: >
  Diseño de UI/UX para HabitAI con Material Design 3 y flutter_animate.
  Usa esta skill cuando crees pantallas, componentes visuales, el tema de la app,
  animaciones, gráficas de progreso, el sistema de diseño, colores, tipografía,
  o cualquier elemento de interfaz. También para decisiones de UX como flujos
  de usuario, estados vacíos, feedback visual y accesibilidad.
---

# UI Design — HabitAI

## Sistema de diseño Material 3

### Configuración del tema

```dart
// lib/core/theme/app_theme.dart

/// Tema centralizado de la aplicación.
/// Material 3 genera paletas de color automáticamente a partir de un color semilla.
class AppTheme {
  // Color principal de la marca — todos los demás se derivan de aquí
  static const Color seedColor = Color(0xFF6750A4); // Violeta Material 3

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Tipografía personalizada (opcional, Google Fonts)
      textTheme: GoogleFonts.interTextTheme(),
      // Cards con bordes redondeados M3
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Botones elevados con esquinas redondeadas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Input fields consistentes
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      // ... mismas personalizaciones que lightTheme
    );
  }
}
```

**¿Por qué `ColorScheme.fromSeed`?** Material 3 introduce el concepto de "Dynamic Color". A partir de un solo color semilla, genera automáticamente una paleta completa y accesible (primario, secundario, terciario, surface, error...). Garantiza contraste WCAG sin esfuerzo manual.

### Uso en la app

```dart
// lib/app.dart
MaterialApp.router(
  title: 'HabitAI',
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Respeta preferencia del dispositivo
  routerConfig: appRouter,
);
```

### Acceder a colores del tema (nunca hardcodear colores)

```dart
// ✅ BIEN: Usa el color del tema
final primaryColor = Theme.of(context).colorScheme.primary;
final surfaceColor = Theme.of(context).colorScheme.surface;

// ❌ MAL: Color hardcodeado
final color = Color(0xFF6750A4); // No se adapta al tema oscuro
```

---

## Componentes reutilizables

### HabitCard — Card de un hábito en la lista

```dart
/// Card que representa un hábito en la lista diaria.
/// Stateless porque solo muestra datos, no tiene estado interno.
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCompletedToday
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox circular animado
              _CompletionCheckbox(
                isCompleted: isCompletedToday,
                onToggle: onToggle,
              ),
              const SizedBox(width: 16),
              // Info del hábito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Racha actual
                    Text(
                      '🔥 ${habit.currentStreak} días',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Categoría como chip
              Chip(
                label: Text(habit.category),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Estado vacío

```dart
/// Pantalla que se muestra cuando el usuario no tiene hábitos.
/// Anima al usuario a crear su primer plan con IA.
class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const EmptyHabitsView({super.key, required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '¡Empieza tu camino!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cuéntale a la IA tus metas y te creará un plan de hábitos personalizado.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreatePlan,
              icon: const Icon(Icons.chat),
              label: const Text('Crear mi plan con IA'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Animaciones con flutter_animate

### Principios de animación

1. **Sutil y funcional**: Las animaciones deben guiar la atención, no distraer.
2. **Consistentes**: Usar duraciones y curvas estándar.
3. **Performantes**: Animar solo `opacity`, `transform` y `clip` (composición GPU).

### Patrones de animación comunes

```dart
// Aparición suave de elementos en listas
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: habits.length,
    itemBuilder: (context, index) {
      return HabitCard(habit: habits[index])
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: index * 100), // Escalonado
            duration: const Duration(milliseconds: 400),
          )
          .slideY(
            begin: 0.1,
            curve: Curves.easeOutCubic,
          );
    },
  );
}

// Animación de completar hábito (satisfacción visual)
_CompletionCheckbox(isCompleted: true)
    .animate(target: isCompleted ? 1 : 0)
    .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.2, 1.2),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
    )
    .then()  // Encadenar animación
    .scale(
      begin: const Offset(1.2, 1.2),
      end: const Offset(1, 1),
      duration: const Duration(milliseconds: 150),
    );

// Shimmer loading placeholder
Container(
  height: 80,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Theme.of(context).colorScheme.surfaceVariant,
  ),
).animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: const Duration(seconds: 2),
      color: Theme.of(context).colorScheme.surface,
    );
```

---

## Gráficas de progreso (Dashboard)

### Librería recomendada: fl_chart

```dart
/// Gráfica de barras mostrando hábitos completados por día de la semana.
class WeeklyProgressChart extends StatelessWidget {
  final Map<int, int> completedByDay; // {1: 3, 2: 5, 3: 2, ...}
  final int totalHabits;

  // ... constructor

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: totalHabits.toDouble(),
          barGroups: completedByDay.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
          // ... configuración de ejes, grid, etc.
        ),
      ),
    );
  }
}
```

---

## Responsive y accesibilidad

### Principios
- **`MediaQuery`** para adaptar layouts a tamaño de pantalla.
- **`Semantics`** en widgets interactivos para lectores de pantalla.
- **Contraste**: Material 3 con `fromSeed` ya garantiza WCAG AA.
- **Touch targets**: Mínimo 48x48 dp para elementos táctiles (Material guideline).
- **Texto escalable**: Usar `textScaleFactor` y no tamaños fijos en dp.

```dart
// Ejemplo: Scaffold adaptativo que muestra NavigationRail en tablets
final isWide = MediaQuery.of(context).size.width > 600;

if (isWide) {
  return Row(
    children: [
      NavigationRail(...),  // Sidebar en tablets
      Expanded(child: child),
    ],
  );
} else {
  return Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(...),  // Bottom nav en móviles
  );
}
```

---

## Paleta de colores por categoría de hábito

```dart
/// Colores asignados a cada categoría de hábito.
/// Se usan como acento en HabitCard, chips y gráficas.
Color categoryColor(String category, ColorScheme scheme) {
  switch (category) {
    case 'salud':
      return const Color(0xFF4CAF50);       // Verde
    case 'productividad':
      return scheme.primary;                 // Violeta del tema
    case 'bienestar':
      return const Color(0xFF42A5F5);       // Azul
    case 'social':
      return const Color(0xFFFF7043);       // Naranja
    case 'aprendizaje':
      return const Color(0xFFAB47BC);       // Púrpura
    case 'finanzas':
      return const Color(0xFF66BB6A);       // Verde claro
    default:
      return scheme.tertiary;
  }
}
```
