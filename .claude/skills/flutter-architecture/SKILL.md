---
name: flutter-architecture
description: >
  Guía de arquitectura Flutter para HabitAI. Usa esta skill cuando trabajes con
  estructura de carpetas, creación de widgets (Stateless/Stateful), modelos de dominio,
  repositorios, navegación con go_router, o gestión de estado. También para decidir
  dónde colocar un archivo nuevo o cómo conectar capas entre sí.
---

# Flutter Architecture — HabitAI

## Principio fundamental: Feature-First + 3 capas

Cada feature se organiza en `domain/`, `data/`, `presentation/`. Esta separación no es
capricho — es la base para defender el proyecto ante el tribunal.

### domain/ — Modelos puros

```dart
/// Modelo de dominio para un hábito.
/// No depende de Firebase, solo Dart puro.
class HabitModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency;        // "daily", "weekly", "custom"
  final List<int> targetDays;    // [1,2,3,4,5] = L-V
  final String? reminderTime;    // "08:00" formato HH:mm
  final int currentStreak;
  final int bestStreak;
  final bool isAIGenerated;
  final DateTime createdAt;
  final bool isActive;

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.reminderTime,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isAIGenerated = false,
    required this.createdAt,
    this.isActive = true,
  });

  /// Factoría desde documento Firestore
  factory HabitModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitModel(
      id: docId,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      frequency: json['frequency'] as String,
      targetDays: List<int>.from(json['targetDays'] ?? []),
      reminderTime: json['reminderTime'] as String?,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      isAIGenerated: json['isAIGenerated'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serializar para enviar a Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'frequency': frequency,
      'targetDays': targetDays,
      'reminderTime': reminderTime,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isAIGenerated': isAIGenerated,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Copia inmutable con campos modificados
  HabitModel copyWith({
    String? title,
    String? description,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    // ... más campos según necesidad
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      frequency: frequency,
      targetDays: targetDays,
      reminderTime: reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isAIGenerated: isAIGenerated,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
```

**¿Por qué `fromJson` recibe `docId` separado?** Porque el ID del documento en Firestore no está dentro del `data()` del documento, sino en `doc.id`. Pasarlo como parámetro mantiene el modelo independiente de Firestore internamente.

**¿Por qué `copyWith`?** Dart favorece inmutabilidad. En vez de mutar un objeto, creamos uno nuevo con los campos cambiados. Esto evita bugs de estado compartido y facilita comparaciones.

---

### data/ — Repositorios

```dart
/// Repositorio que encapsula todas las operaciones de hábitos en Firestore.
/// La capa de presentación NUNCA accede a Firestore directamente.
class HabitRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HabitRepository({
    required String uid,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la colección de hábitos del usuario actual
  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _firestore.collection('users').doc(_uid).collection('habits');

  /// Stream reactivo de hábitos activos, ordenados por fecha de creación
  Stream<List<HabitModel>> watchActiveHabits() {
    return _habitsRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Crear un nuevo hábito
  Future<String> createHabit(HabitModel habit) async {
    final docRef = await _habitsRef.add(habit.toJson());
    return docRef.id;
  }

  /// Actualizar un hábito existente
  Future<void> updateHabit(String habitId, Map<String, dynamic> data) async {
    await _habitsRef.doc(habitId).update(data);
  }

  /// Soft delete: marcar como inactivo en vez de borrar
  Future<void> deactivateHabit(String habitId) async {
    await _habitsRef.doc(habitId).update({'isActive': false});
  }
}
```

**¿Por qué inyectar `FirebaseFirestore` en el constructor?** Para testing. En tests puedes pasar un mock de Firestore sin tocar la instancia real. Esto es un punto fuerte para el tribunal.

**¿Por qué soft delete?** Borrar datos es irreversible y pierde historial. Marcar `isActive: false` permite recuperar hábitos y mantener estadísticas históricas.

---

### presentation/ — Widgets

```dart
/// Pantalla principal de hábitos del día.
/// Usa StreamBuilder para reaccionar a cambios en Firestore en tiempo real.
class HabitsScreen extends StatelessWidget {
  final HabitRepository repository;

  const HabitsScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HabitModel>>(
      stream: repository.watchActiveHabits(),
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error de Firestore
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar hábitos: ${snapshot.error}'),
          );
        }

        // Lista vacía
        final habits = snapshot.data ?? [];
        if (habits.isEmpty) {
          return const _EmptyHabitsView();
        }

        // Lista de hábitos
        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) => HabitCard(habit: habits[index]),
        );
      },
    );
  }
}
```

---

## Navegación con go_router

### Configuración centralizada

```dart
// lib/core/router/app_router.dart

/// Router principal de la aplicación.
/// Gestiona auth guards y la estructura de navegación con tabs.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  
  /// Guard global: redirige según estado de autenticación
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
                        state.matchedLocation == '/register';

    // Si no está autenticado y no está en auth → al login
    if (!isLoggedIn && !isAuthRoute) return '/login';
    // Si está autenticado y está en auth → al home
    if (isLoggedIn && isAuthRoute) return '/';
    // En cualquier otro caso, no redirigir
    return null;
  },

  routes: [
    // Rutas de autenticación (sin bottom nav)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Shell con BottomNavigationBar para las tabs principales
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'habits',
          builder: (context, state) => const HabitsScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/ai',
          name: 'ai-chat',
          builder: (context, state) => const AIChatScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
```

**¿Por qué `ShellRoute`?** Permite que las tabs principales compartan un `Scaffold` con `BottomNavigationBar` sin reconstruirlo en cada cambio de tab. El `child` es la pantalla activa.

**¿Por qué `redirect` en vez de listeners?** Es el mecanismo declarativo de go_router. Se ejecuta antes de cada navegación, garantizando que el usuario no accede a rutas protegidas. Es más predecible que push/pop manual.

---

## Cuándo usar StatelessWidget vs StatefulWidget

### StatelessWidget (preferido)
- Muestra datos que recibe por parámetro.
- No tiene estado interno mutable.
- Ejemplos: `HabitCard`, `AchievementBadge`, `StatsChart`, `EmptyStateView`.

### StatefulWidget (necesario)
- Tiene `TextEditingController` (formularios).
- Usa `setState` para toggles o animaciones locales.
- Necesita `initState` / `dispose` para inicializar/limpiar recursos.
- Ejemplos: `LoginScreen` (formulario), `HabitCheckIn` (animación de completar), `OnboardingWizard` (pasos).

### Regla de oro
> Si el widget no necesita `initState`, `dispose` o `setState`, es Stateless.

---

## Constantes de rutas Firestore

```dart
// lib/core/constants/firestore_paths.dart

/// Rutas centralizadas para evitar errores de typo en strings de colecciones.
/// Si una ruta cambia, solo se modifica aquí.
class FirestorePaths {
  static String userDoc(String uid) => 'users/$uid';
  static String habitsCollection(String uid) => 'users/$uid/habits';
  static String habitDoc(String uid, String habitId) => 'users/$uid/habits/$habitId';
  static String logsCollection(String uid, String habitId) =>
      'users/$uid/habits/$habitId/logs';
  static String achievementsCollection(String uid) => 'users/$uid/achievements';
  static String aiConversationsCollection(String uid) =>
      'users/$uid/ai_conversations';
}
```

---

## Checklist antes de crear un archivo nuevo

1. ¿En qué feature va? → `features/{feature}/`
2. ¿Es modelo, repositorio o widget? → `domain/`, `data/`, `presentation/`
3. ¿Es compartido entre features? → `core/`
4. ¿Tiene constructor `const`? → Sí, si no tiene campos mutables.
5. ¿Necesita `super.key`? → Sí, en todo Widget.
6. ¿Los comentarios están en español? → Sí.
7. ¿Los nombres de clase/variable están en inglés? → Sí.
