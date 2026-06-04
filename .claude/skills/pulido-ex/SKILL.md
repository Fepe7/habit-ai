---
name: ux-polish
description: >
  Pulido de UX y microinteracciones para HabitAI. Usa esta skill cuando trabajes
  en mejorar la sensación de fluidez de la app: transiciones entre pantallas,
  animaciones de estado (carga, éxito, error), feedback visual al tocar elementos,
  estados vacíos, skeleton loaders, haptic feedback, y el flujo de onboarding.
  También cuando quieras que una pantalla existente se sienta más profesional
  sin reescribirla entera — pequeños detalles que marcan diferencia.
---

# UX Polish — HabitAI

## Principios rectores

Cada interacción del usuario tiene que sentirse **viva pero no invasiva**. Una app de hábitos se usa todos los días — si las animaciones son exageradas, cansan. Si son inexistentes, la app se siente muerta. El equilibrio está en microinteracciones sutiles que refuerzan la acción del usuario sin robar protagonismo.

Tres reglas no negociables:

1. **Toda acción del usuario tiene respuesta visual en menos de 100ms**. Si tocan un botón, algo pasa inmediatamente — un ripple, un cambio de color, una contracción. Nunca silencio.

2. **Los estados de carga nunca son un spinner en blanco**. Skeleton loaders, shimmer sobre la estructura real de la UI, o transiciones optimistas.

3. **Los errores y éxitos se comunican con color, icono y movimiento**, no solo con texto.

---

## Microinteracciones clave por pantalla

### Check-in de hábito (la acción más frecuente)

Cuando el usuario marca un hábito como completado, deben ocurrir varias cosas coordinadas:

```dart
// 1. El checkbox se escala con easeOutBack (efecto rebote)
// 2. El texto del título cambia de color y añade tachado
// 3. La card de fondo se tinta suavemente con el color de éxito
// 4. Vibración háptica suave (HapticFeedback.lightImpact)
// 5. Si rompe récord de racha, confeti animado y sonido opcional

import 'package:flutter/services.dart';

void _onHabitChecked() {
  HapticFeedback.lightImpact();
  setState(() => _isCompleted = true);
  // animate el card con flutter_animate
}
```

La clave es que las cuatro reacciones pasen a la vez, no secuencialmente. El usuario percibe una "respuesta unificada" en vez de una cascada de eventos.

### Transiciones entre pantallas

Con `go_router`, la transición por defecto es un push lateral de Android. Está bien, pero para momentos clave conviene personalizarla:

```dart
// Transición de "generar plan con IA" — el usuario espera algo importante
GoRoute(
  path: '/ai/result',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const AIResultScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  ),
),
```

### Estados vacíos con invitación a la acción

Nunca mostrar una pantalla vacía con texto plano. Cada estado vacío debe tener:

- Icono grande (64-80dp) en color primario
- Título claro ("Aún no tienes hábitos")
- Subtítulo explicativo ("Pide a la IA que te genere un plan personalizado")
- CTA (call to action) visible y con animación de atracción suave

```dart
FilledButton.icon(
  onPressed: onCreatePlan,
  icon: const Icon(Icons.auto_awesome),
  label: const Text('Crear plan con IA'),
).animate(onPlay: (c) => c.repeat(reverse: true))
 .scale(
   begin: const Offset(1, 1),
   end: const Offset(1.03, 1.03),
   duration: const Duration(seconds: 2),
   curve: Curves.easeInOut,
 );
```

---

## Estados de carga: skeleton loaders

En vez de un `CircularProgressIndicator` genérico, mostrar la estructura de la pantalla en gris con efecto shimmer:

```dart
/// Placeholder que imita la estructura de una HabitCard mientras carga.
class HabitCardSkeleton extends StatelessWidget {
  const HabitCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Círculo del checkbox
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            // Líneas de texto simuladas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 180, color: surface),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: surface),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: const Duration(milliseconds: 1500));
  }
}
```

**Dónde usarlo**: mientras el `StreamBuilder` está en `ConnectionState.waiting`, mostrar 3-4 skeletons en vez del spinner.

---

## Feedback háptico (Android nativo)

Flutter incluye `HapticFeedback` sin dependencias extra. Usarlo en momentos concretos refuerza la sensación de app profesional:

```dart
import 'package:flutter/services.dart';

// Al marcar un hábito
HapticFeedback.lightImpact();

// Al desbloquear un logro
HapticFeedback.mediumImpact();

// Al cometer un error (ej: no se puede enviar formulario)
HapticFeedback.heavyImpact();

// Al cambiar de pestaña o selector
HapticFeedback.selectionClick();
```

Regla: háptica solo en acciones del usuario, NUNCA en eventos automáticos (notificaciones, llegada de datos). El móvil vibrando sin que hayas tocado nada es molesto.

---

## Animaciones de la navegación principal

### BottomNavigationBar con transición suave

El cambio de tab debe animar el icono seleccionado:

```dart
// Usar NavigationBar de Material 3 que ya anima el indicador
// Pero añadimos escala al icono activo
IconThemeData(
  color: isSelected
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.onSurfaceVariant,
  size: isSelected ? 26 : 24,
)
```

### AppBar que desaparece con el scroll

Para maximizar espacio visible en listas largas:

```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
      SliverAppBar(
        floating: true,
        snap: true,
        title: const Text('Mis hábitos'),
      ),
      SliverList(/* hábitos */),
    ],
  ),
)
```

---

## El flujo de onboarding

El onboarding es la primera experiencia del usuario. Si es largo, abandonan. Si es corto, no entienden la app. HabitAI debería tener 4 pantallas:

### Pantalla 1 — Bienvenida
- Logo animado (fadeIn + scale)
- "HabitAI" grande
- Subtítulo: "Tu asistente personal de hábitos"
- Botón "Empezar" grande al final

### Pantalla 2 — ¿Qué quieres mejorar?
- Chips seleccionables con iconos: "Salud física", "Productividad", "Bienestar mental", "Estudios", "Finanzas", "Relaciones sociales"
- El usuario puede marcar múltiples
- Animación de escala al seleccionar

### Pantalla 3 — Cuéntanos sobre ti
- TextField grande y amigable: "Cuéntame en tus palabras qué quieres conseguir"
- Placeholder con ejemplos rotando cada 3s: "Quiero dormir mejor...", "Quiero hacer ejercicio 3 días a la semana...", "Quiero leer más..."
- Botón "Generar mi plan" que lanza el loading del plan

### Pantalla 4 — Tu plan generado
- Card grande con el título del plan
- Lista de hábitos sugeridos con animación staggered (uno tras otro)
- Botón "Empezar con este plan" o "Pedir ajustes"

Al final, marca `onboardingCompleted: true` en el UserModel y navega al MainShell.

### Animación staggered para listas

```dart
// Cuando aparece el plan generado, los hábitos entran uno a uno
for (int i = 0; i < habits.length; i++)
  HabitPreviewCard(habit: habits[i])
      .animate()
      .fadeIn(
        delay: Duration(milliseconds: i * 120),
        duration: const Duration(milliseconds: 400),
      )
      .slideY(begin: 0.15, curve: Curves.easeOutCubic),
```

---

## Feedback de acciones de red

Cada llamada a Firebase o a la IA puede:
1. **Iniciarse**: mostrar loading state
2. **Tener éxito**: confirmación breve (SnackBar con icono verde, haptic light)
3. **Fallar**: mensaje de error claro (SnackBar rojo, haptic heavy, botón "Reintentar")

```dart
/// Helper para mostrar feedback uniforme en toda la app.
void showSuccessToast(BuildContext context, String message) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

void showErrorToast(BuildContext context, String message, {VoidCallback? onRetry}) {
  HapticFeedback.heavyImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(label: 'Reintentar', textColor: Colors.white, onPressed: onRetry)
          : null,
    ),
  );
}
```

---

## Checklist de pulido por pantalla

Aplica esto a cada pantalla de la app:

- [ ] ¿Tiene skeleton loader mientras carga datos?
- [ ] ¿Tiene estado vacío con CTA si no hay datos?
- [ ] ¿Tiene estado de error con botón "Reintentar"?
- [ ] ¿Los botones tienen feedback visual al pulsar (ripple, escala)?
- [ ] ¿Las transiciones entre secciones son suaves?
- [ ] ¿Las acciones importantes tienen háptica?
- [ ] ¿Los errores muestran mensaje en español comprensible?
- [ ] ¿El AppBar o título da contexto claro de dónde estás?
- [ ] ¿Los elementos clicables tienen al menos 48x48dp de área táctil?
- [ ] ¿Hay alguna microinteracción que refuerce la acción completada?

---

## Qué NO hacer

- **No animar todo**. Si todo se mueve, nada destaca. Reserva las animaciones para los momentos que importan.
- **No usar transiciones exageradas** (rebotes grandes, rotaciones completas). Material Design recomienda curvas sutiles.
- **No abusar de la háptica**. Si cada scroll vibra, la gente desactiva la vibración del sistema.
- **No usar spinners genéricos**. Siempre skeletons o loading optimista.
- **No silenciar errores**. Si algo falla, el usuario tiene que saberlo con claridad.
