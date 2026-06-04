---
name: performance-and-quality
description: >
  Calidad de código y rendimiento para HabitAI. Usa esta skill para configurar
  linting con analysis_options.yaml, optimizar rendimiento de consultas Firestore,
  implementar caché local, lazy loading, paginación, o cualquier mejora de
  eficiencia y sostenibilidad (RA 5). También para preparar el código con
  comentarios explicativos que sirvan como evidencia ante el tribunal.
---

# Performance & Quality — HabitAI

## Linting y análisis estático

### analysis_options.yaml

```yaml
# Configuración estricta del analizador de Dart.
# El tribunal puede preguntar por herramientas de calidad de código (RA 4).
include: package:flutter_lints/flutter.yaml

analyzer:
  strong-mode:
    implicit-casts: false      # Prohíbe casts implícitos — más seguro
    implicit-dynamic: false    # Prohíbe tipos dynamic implícitos
  errors:
    missing_return: error      # Funciones sin return son error, no warning
    missing_required_param: error

linter:
  rules:
    - prefer_const_constructors           # Fuerza const donde sea posible
    - prefer_const_declarations           # Variables que no cambian → const
    - avoid_print                         # Usar logger en vez de print
    - prefer_single_quotes                # Consistencia en strings
    - sort_constructors_first             # Constructores primero en la clase
    - annotate_overrides                  # @override obligatorio
    - prefer_final_locals                 # Variables locales inmutables por defecto
    - unnecessary_this                    # No usar this. innecesariamente
    - use_key_in_widget_constructors      # super.key obligatorio
```

**Pregunta de tribunal**: *¿Cómo garantizas la calidad del código?*
→ Dos herramientas: (1) `analysis_options.yaml` con reglas estrictas que el IDE detecta en tiempo real, (2) `dart analyze` antes de cada commit para verificar 0 warnings.

---

## Rendimiento y sostenibilidad (RA 5)

### Optimización de consultas Firestore

```dart
/// EFICIENCIA: Solo traer hábitos activos del día actual.
/// Reduce lecturas facturadas en Firestore y transferencia de datos.
Stream<List<HabitModel>> watchTodayHabits() {
  final today = DateTime.now().weekday; // 1=Lunes, 7=Domingo
  return _habitsRef
      .where('isActive', isEqualTo: true)
      .where('targetDays', arrayContains: today)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => HabitModel.fromJson(d.data(), d.id))
          .toList());
}
```

### Caché local con streams

```dart
/// SOSTENIBILIDAD: Firestore tiene modo offline por defecto.
/// Los datos se cachean localmente y se sincronizan cuando hay conexión.
/// Esto reduce transferencia de datos y consumo de batería.
///
/// Configurar persistencia explícitamente:
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,          // Activar caché local
  cacheSizeBytes: 50 * 1024 * 1024,  // 50MB máximo de caché
);
```

### Lazy loading de imágenes y listas

```dart
/// EFICIENCIA: Cargar datos bajo demanda, no todo de golpe.
/// Ejemplo: historial de logs paginado.
class HabitLogsList extends StatefulWidget {
  // Usa paginación con ScrollController para cargar más logs
  // solo cuando el usuario hace scroll hasta abajo.
}
```

### Comentarios de eficiencia (evidencia RA 5)

Cada optimización en el código debe tener un comentario que empiece con `// EFICIENCIA:` o `// SOSTENIBILIDAD:` para que sea fácil de localizar como evidencia del RA 5.

```dart
// EFICIENCIA: Usamos const constructor para que Flutter no reconstruya
// este widget si sus inputs no cambian. Reduce trabajo del framework.
const HabitCard({super.key, required this.habit});

// SOSTENIBILIDAD: Limitamos a 20 documentos por página para reducir
// la transferencia de datos y el consumo de batería del dispositivo.
.limit(20)

// EFICIENCIA: StreamBuilder se desuscribe automáticamente del stream
// cuando el widget se desmonta, evitando memory leaks.
StreamBuilder<List<HabitModel>>(...)
```

---

## Dependencias del proyecto (pubspec.yaml orientativo)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  cloud_functions: ^latest
  # Navegación
  go_router: ^latest
  # UI
  google_fonts: ^latest
  flutter_animate: ^latest
  fl_chart: ^latest
  # Utilidades
  intl: ^latest              # Formateo de fechas y números

dev_dependencies:
  flutter_lints: ^latest
```
