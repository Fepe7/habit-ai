---
name: firebase-backend
description: >
  Todo lo relacionado con Firebase en HabitAI: Authentication, Cloud Firestore,
  Cloud Functions, reglas de seguridad, modelado NoSQL y optimización de queries.
  Usa esta skill cuando implementes auth, CRUD en Firestore, reglas de seguridad,
  índices, Cloud Functions como proxy de IA, o cualquier operación de backend.
---

# Firebase Backend — HabitAI

## Firebase Authentication

### Implementación actual (ya completada)

El sistema de auth usa el patrón Repository con las siguientes piezas:

1. **`UserModel`** (domain): Clase pura que representa al usuario autenticado.
2. **`AuthRepository`** (data): Encapsula `FirebaseAuth`, maneja errores con mensajes localizados en español.
3. **`LoginScreen`** (presentation): Formulario con validación, estados de carga, y manejo de errores.
4. **Auth guard** en `main.dart`: `StreamBuilder<User?>` sobre `FirebaseAuth.instance.authStateChanges()`.

### Flujo de autenticación

```
App inicia → StreamBuilder escucha authStateChanges()
  ├── User == nul[SKILL.md](../ai-integration/SKILL.md)l → LoginScreen
  └── User != null → Comprobar onboardingCompleted
       ├── false → OnboardingScreen
       └── true → MainShell (tabs)
```

**Pregunta de tribunal**: *¿Por qué `authStateChanges()` y no `idTokenChanges()`?*  
→ `authStateChanges()` emite cuando el usuario inicia/cierra sesión. `idTokenChanges()` también emite cuando se refresca el token, causando rebuilds innecesarios. Para un auth guard, `authStateChanges()` es suficiente y más eficiente.

### UID como nexo arquitectónico

```
Firebase Auth (UID: "abc123")
       ↓
Firestore: users/abc123
       ├── habits/
       ├── achievements/
       └── ai_conversations/
```

El UID que genera Firebase Auth al registrarse es la **clave primaria** que vincula al usuario con todos sus datos en Firestore. No es un campo más — es el pilar de la estructura de datos.

---

## Cloud Firestore — Modelado NoSQL

### Principios de diseño NoSQL para Firestore

1. **Desnormalización controlada**: Duplicar datos es aceptable si evita queries costosos. Ejemplo: `currentStreak` vive en el documento del hábito aunque se calcula desde los logs.

2. **Subcolecciones para datos que crecen**: Los logs diarios van en `habits/{id}/logs/` porque un hábito puede tener cientos de logs. Si fueran un array dentro del hábito, el documento crecería hasta superar el límite de 1MB.

3. **Evitar arrays de objetos complejos**: Los arrays en Firestore no se pueden consultar eficientemente. Usa subcolecciones cuando necesites filtrar o paginar.

4. **Timestamps nativos**: Siempre usar `Timestamp` de Firestore (no strings de fecha). Permite orderBy y queries por rango.

### Queries optimizados

```dart
/// ✅ BIEN: Query con índice simple (un campo + orderBy)
_habitsRef
    .where('isActive', isEqualTo: true)
    .orderBy('createdAt', descending: true)

/// ✅ BIEN: Query de logs por rango de fechas (para gráficas semanales)
_logsRef
    .where('date', isGreaterThanOrEqualTo: startOfWeek)
    .where('date', isLessThanOrEqualTo: endOfWeek)
    .orderBy('date')

/// ❌ MAL: Filtrar en el cliente después de traer todo
final allHabits = await _habitsRef.get(); // Trae TODOS los documentos
allHabits.where((h) => h.isActive); // Filtra en memoria → ineficiente

/// ✅ BIEN: Filtrar en Firestore con .where() → solo trae lo necesario
```

**Pregunta de tribunal**: *¿Por qué no usas SQL si ya lo conoces?*  
→ Firestore escala horizontalmente sin configuración, tiene sincronización en tiempo real integrada (streams), modo offline automático, y se integra nativamente con Firebase Auth para reglas de seguridad basadas en UID. Para una app móvil con datos por usuario, NoSQL con Firestore es más natural que un esquema relacional.

### Paginación con `limit` y cursores

```dart
/// Para listas largas (ej: historial de logs), paginar para no cargar todo
Future<List<HabitLogModel>> getLogsPaginated({
  required String habitId,
  DocumentSnapshot? lastDoc,
  int pageSize = 20,
}) async {
  Query query = _logsRef(habitId)
      .orderBy('date', descending: true)
      .limit(pageSize);

  // Si tenemos el último documento de la página anterior, continuar desde ahí
  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }

  final snapshot = await query.get();
  return snapshot.docs
      .map((doc) => HabitLogModel.fromJson(doc.data(), doc.id))
      .toList();
}
```

---

## Reglas de seguridad de Firestore

### Reglas base (ya definidas en CLAUDE.md)

Principio: **denegar todo por defecto, permitir explícitamente**.

### Reglas avanzadas con validación de datos

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Denegar todo por defecto
    match /{document=**} {
      allow read, write: if false;
    }
    
    match /users/{userId} {
      // Solo el propio usuario puede leer/escribir su documento
      allow read: if isOwner(userId);
      allow create: if isOwner(userId) && isValidUserDoc();
      allow update: if isOwner(userId);
      
      // Hábitos del usuario
      match /habits/{habitId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && isValidHabit();
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
        
        // Logs de cada hábito
        match /logs/{logId} {
          allow read: if isOwner(userId);
          allow create: if isOwner(userId) && isValidLog();
          allow update, delete: if isOwner(userId);
        }
      }
      
      // Logros y conversaciones IA
      match /achievements/{achievementId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        // Los logros no se editan ni borran una vez desbloqueados
        allow update, delete: if false;
      }
      
      match /ai_conversations/{conversationId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update, delete: if false; // Las conversaciones son inmutables
      }
    }
    
    // Funciones helper reutilizables
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    function isValidUserDoc() {
      let data = request.resource.data;
      return data.keys().hasAll(['email', 'displayName', 'createdAt'])
          && data.email is string
          && data.displayName is string;
    }
    
    function isValidHabit() {
      let data = request.resource.data;
      return data.keys().hasAll(['title', 'category', 'frequency', 'createdAt'])
          && data.title is string
          && data.title.size() > 0
          && data.title.size() <= 100;
    }
    
    function isValidLog() {
      let data = request.resource.data;
      return data.keys().hasAll(['date', 'completed'])
          && data.completed is bool;
    }
  }
}
```

**¿Por qué funciones helper?** Reducen duplicación y hacen las reglas más legibles. `isOwner()` se usa en todas las subcolecciones — si cambia la lógica de auth, se actualiza una vez.

**¿Por qué logros y conversaciones son inmutables?** Integridad de datos. Un logro desbloqueado no debe poder borrarse (fraude). Una conversación IA es un registro histórico.

---

## Cloud Functions — Proxy seguro para IA

### Estructura del proyecto Cloud Functions

```
functions/
├── package.json
├── index.js                  # Punto de entrada
├── src/
│   ├── generateHabitPlan.js  # Función principal de generación con IA
│   └── middleware/
│       ├── authMiddleware.js # Verificación de token Firebase
│       └── rateLimiter.js    # Rate limiting por usuario
└── .env                      # Variables de entorno (NO commitear)
```

### Ejemplo de Cloud Function

```javascript
// functions/src/generateHabitPlan.js
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// La API key se almacena en Secret Manager de Google Cloud
const CLAUDE_API_KEY = defineSecret("CLAUDE_API_KEY");

exports.generateHabitPlan = onCall(
  { secrets: [CLAUDE_API_KEY] },
  async (request) => {
    // 1. Verificar que el usuario está autenticado
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar esta función."
      );
    }

    const { userMessage, existingHabits, userGoals } = request.data;

    // 2. Validar datos de entrada
    if (!userMessage || typeof userMessage !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "El mensaje del usuario es obligatorio."
      );
    }

    // 3. Construir el prompt para la IA
    const systemPrompt = `Eres un coach de hábitos experto...`; // Ver skill ai-integration

    // 4. Llamar a la API de Claude
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": CLAUDE_API_KEY.value(),
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2000,
        system: systemPrompt,
        messages: [{ role: "user", content: userMessage }],
      }),
    });

    if (!response.ok) {
      throw new HttpsError("internal", "Error al comunicar con la IA.");
    }

    const aiData = await response.json();
    const aiText = aiData.content[0].text;

    // 5. Parsear la respuesta JSON de la IA
    try {
      const habitPlan = JSON.parse(aiText);
      return { success: true, plan: habitPlan };
    } catch (e) {
      // Si la IA no devolvió JSON válido, devolver como texto
      return { success: true, rawResponse: aiText };
    }
  }
);
```

### Llamada desde Flutter

```dart
/// Repositorio que conecta con la Cloud Function de generación de hábitos.
class AIRepository {
  final FirebaseFunctions _functions;

  AIRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Envía el mensaje del usuario a la Cloud Function y recibe el plan generado.
  Future<HabitPlanModel> generatePlan({
    required String userMessage,
    List<String>? existingHabits,
    List<String>? userGoals,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateHabitPlan');
      final result = await callable.call({
        'userMessage': userMessage,
        'existingHabits': existingHabits ?? [],
        'userGoals': userGoals ?? [],
      });

      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true && data['plan'] != null) {
        return HabitPlanModel.fromJson(data['plan']);
      }
      throw Exception('Respuesta inesperada de la IA');
    } on FirebaseFunctionsException catch (e) {
      // Manejo de errores específicos de Cloud Functions
      throw _mapError(e);
    }
  }
}
```

**¿Por qué `onCall` y no `onRequest`?** `onCall` verifica automáticamente el token de Firebase Auth del cliente y deserializa los datos. Con `onRequest` tendrías que hacer todo eso manualmente.

---

## Manejo de errores Firebase — Patrones

```dart
/// Mapeo centralizado de errores de Firebase a mensajes en español.
/// Evita exponer códigos técnicos al usuario.
String mapFirebaseError(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return 'No tienes permiso para realizar esta acción.';
    case 'not-found':
      return 'El recurso solicitado no existe.';
    case 'unavailable':
      return 'Servicio no disponible. Comprueba tu conexión a internet.';
    case 'deadline-exceeded':
      return 'La operación tardó demasiado. Inténtalo de nuevo.';
    default:
      return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
  }
}
```

---

## Checklist de seguridad Firebase

- [ ] API keys de IA almacenadas en Secret Manager, NUNCA en el cliente
- [ ] Reglas de Firestore: denegar todo por defecto
- [ ] Toda lectura/escritura validada con `request.auth.uid == userId`
- [ ] Validación de estructura de datos en reglas (campos obligatorios, tipos)
- [ ] Rate limiting en Cloud Functions para prevenir abuso
- [ ] Variables de entorno en `.env` añadidas al `.gitignore`
- [ ] Firebase App Check habilitado (protección contra bots)
