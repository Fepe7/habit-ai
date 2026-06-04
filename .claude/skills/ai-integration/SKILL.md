---
name: ai-integration
description: >
  Integración de IA generativa en HabitAI. Usa esta skill para todo lo relacionado
  con Gemini (Google) via Firebase AI Logic: diseño de prompts, parseo de respuestas JSON,
  Cloud Functions como proxy seguro, flujo de onboarding con IA, chat con el
  asistente de hábitos, y manejo de errores de la API. También cuando necesites
  decidir cómo estructurar las peticiones asíncronas o el formato de datos entre
  el cliente y la IA.
---

# AI Integration — HabitAI

## Arquitectura de la integración

```
┌─────────────────┐     ┌───────────────────────┐     ┌──────────────────────────┐
│   Flutter App    │────▶│   Cloud Function       │────▶│  Gemini API              │
│  (AIRepository)  │◀────│  (generateHabitPlan)   │◀────│  (Firebase AI / Vertex)  │
└─────────────────┘     └───────────────────────┘     └──────────────────────────┘
        │                         │
        │                   1. Verifica auth token
        │                   2. Rate limiting (10/hora)
        │                   3. Config Gemini en servidor
        │                   4. Construye prompt
        │                   5. Parsea respuesta JSON
```

**Principio fundamental**: El cliente Flutter NUNCA habla directamente con Gemini. Siempre pasa por Cloud Functions. Esto protege la configuración del servidor y permite control centralizado (rate limiting, prompt engineering).

**SDK en Cloud Functions**: `@google-cloud/vertexai` o `@google/generative-ai` (Node.js).

**¿Por qué Gemini?** Tier gratuito generoso, integración nativa con Firebase (paquete `firebase_ai`), sin límite estricto de tokens, disponibilidad con Gemini Pro.

---

## System prompt para generación de hábitos

```text
Eres un coach experto en productividad y bienestar personal. Tu tarea es generar
un plan de hábitos personalizado basado en las metas del usuario.

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con un objeto JSON válido. Sin texto adicional, sin markdown,
   sin explicaciones fuera del JSON.
2. Genera entre 3 y 7 hábitos máximo.
3. Cada hábito debe ser específico, medible y realista para una persona normal.
4. Adapta los horarios y frecuencias al estilo de vida descrito por el usuario.
5. Categoriza cada hábito: "salud", "productividad", "bienestar", "social",
   "aprendizaje", "finanzas".

FORMATO DE RESPUESTA (JSON):
{
  "planTitle": "Título descriptivo del plan",
  "planDescription": "Breve descripción de 1-2 frases",
  "habits": [
    {
      "title": "Nombre corto del hábito",
      "description": "Descripción de qué hacer y por qué",
      "category": "salud|productividad|bienestar|social|aprendizaje|finanzas",
      "frequency": "daily|weekly|custom",
      "targetDays": [1,2,3,4,5,6,7],
      "suggestedTime": "HH:mm",
      "estimatedMinutes": 15,
      "difficultyLevel": "easy|medium|hard"
    }
  ],
  "coachMessage": "Un mensaje motivacional personalizado para el usuario"
}

CONTEXTO DEL USUARIO:
- Metas: {userGoals}
- Hábitos actuales: {existingHabits}
- Mensaje del usuario: {userMessage}
```

### ¿Por qué este diseño de prompt?

1. **JSON estricto**: Evita respuestas narrativas que requieran parseo complejo. El modelo devuelve datos estructurados que se mapean directamente a `HabitModel`.

2. **Límite de 3-7 hábitos**: Evita planes abrumadores. Las investigaciones sobre cambio de comportamiento muestran que más de 7 hábitos simultáneos reduce la adherencia.

3. **`targetDays` como array de ints**: Compatible directamente con el modelo de Firestore. [1,2,3,4,5] = lunes a viernes (ISO 8601).

4. **`coachMessage`**: Añade un toque humano. Se muestra en la UI como mensaje del asistente después de generar el plan.

**Pregunta de tribunal**: *¿Cómo garantizas que la IA devuelve JSON válido?*  
→ Triple protección: (1) System prompt explícito pidiendo solo JSON, (2) try-catch en el parseo del lado de Cloud Functions, (3) fallback a texto plano si el parseo falla, mostrando la respuesta como mensaje del coach sin hábitos estructurados.

---

## Modelos de dominio para IA

```dart
/// Plan completo generado por la IA.
class HabitPlanModel {
  final String planTitle;
  final String planDescription;
  final List<GeneratedHabitModel> habits;
  final String coachMessage;

  const HabitPlanModel({
    required this.planTitle,
    required this.planDescription,
    required this.habits,
    required this.coachMessage,
  });

  factory HabitPlanModel.fromJson(Map<String, dynamic> json) {
    return HabitPlanModel(
      planTitle: json['planTitle'] as String? ?? 'Tu plan personalizado',
      planDescription: json['planDescription'] as String? ?? '',
      habits: (json['habits'] as List<dynamic>?)
              ?.map((h) => GeneratedHabitModel.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      coachMessage: json['coachMessage'] as String? ?? '',
    );
  }
}

/// Hábito individual generado por la IA (antes de guardarse en Firestore).
class GeneratedHabitModel {
  final String title;
  final String description;
  final String category;
  final String frequency;
  final List<int> targetDays;
  final String? suggestedTime;
  final int estimatedMinutes;
  final String difficultyLevel;

  const GeneratedHabitModel({
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.suggestedTime,
    this.estimatedMinutes = 15,
    this.difficultyLevel = 'medium',
  });

  factory GeneratedHabitModel.fromJson(Map<String, dynamic> json) {
    return GeneratedHabitModel(
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'productividad',
      frequency: json['frequency'] as String? ?? 'daily',
      targetDays: List<int>.from(json['targetDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      suggestedTime: json['suggestedTime'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      difficultyLevel: json['difficultyLevel'] as String? ?? 'medium',
    );
  }

  /// Convierte a HabitModel para guardar en Firestore.
  /// Marca isAIGenerated = true para distinguir de hábitos manuales.
  HabitModel toHabitModel() {
    return HabitModel(
      id: '',  // Firestore asignará el ID al crear el documento
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      targetDays: targetDays,
      reminderTime: suggestedTime,
      isAIGenerated: true,
      createdAt: DateTime.now(),
    );
  }
}
```

**¿Por qué dos modelos separados (`GeneratedHabitModel` y `HabitModel`)?**  
→ `GeneratedHabitModel` tiene campos de IA (estimatedMinutes, difficultyLevel) que no se persisten. `HabitModel` es el modelo de Firestore. `toHabitModel()` transforma uno en otro, marcando `isAIGenerated: true`.

---

## Flujo de onboarding con IA

```
1. Pantalla de bienvenida → Explica qué hace HabitAI
2. Pantalla de metas → El usuario escribe o selecciona sus metas
   Ejemplos: "Quiero hacer ejercicio", "Dormir mejor", "Ser más productivo"
3. Pantalla de contexto → Preguntas sobre su rutina actual
   "¿A qué hora te levantas?", "¿Trabajas de lunes a viernes?"
4. Pantalla de generación → Se llama a la Cloud Function con:
   - Metas seleccionadas
   - Contexto de rutina
   - Mensaje construido automáticamente
5. Pantalla de resultado → Muestra el plan generado
   - El usuario puede aceptar, modificar o rechazar cada hábito
   - Los hábitos aceptados se guardan en Firestore con isAIGenerated: true
6. Marcar onboardingCompleted: true en users/{uid}
```

### Construcción del mensaje de onboarding

```dart
/// Construye el mensaje que se envía a la IA a partir de las respuestas del onboarding.
String buildOnboardingMessage({
  required List<String> goals,
  required String wakeUpTime,
  required String sleepTime,
  required List<int> workDays,
}) {
  return '''
Mis metas personales son: ${goals.join(', ')}.
Mi rutina: me levanto a las $wakeUpTime y me acuesto a las $sleepTime.
Trabajo de ${_formatDays(workDays)}.
Necesito un plan de hábitos que encaje con este horario.
''';
}
```

---

## Chat con IA (post-onboarding)

Después del onboarding, el usuario puede chatear para:
- Pedir ajustes al plan existente
- Preguntar consejos sobre un hábito
- Solicitar un nuevo plan si sus metas cambian

### Modelo de conversación

```dart
class AIConversationModel {
  final String id;
  final DateTime createdAt;
  final String userMessage;
  final String aiResponse;
  final List<Map<String, dynamic>>? generatedHabits;

  // ... fromJson, toJson
}
```

Las conversaciones se guardan en `users/{uid}/ai_conversations/` como registro histórico. Son inmutables (no se editan ni borran) por integridad de datos.

---

## Manejo de errores de la API de IA

```dart
/// Errores posibles al comunicar con la IA y cómo manejarlos.
enum AIError {
  /// La Cloud Function no está disponible
  networkError,
  /// El usuario ha superado el límite de peticiones
  rateLimited,
  /// La IA devolvió una respuesta no parseable
  invalidResponse,
  /// Error interno de la Cloud Function
  internalError,
  /// El usuario no está autenticado
  unauthenticated,
}

String aiErrorMessage(AIError error) {
  switch (error) {
    case AIError.networkError:
      return 'No se pudo conectar con el asistente. Comprueba tu conexión.';
    case AIError.rateLimited:
      return 'Has hecho demasiadas peticiones. Espera unos minutos.';
    case AIError.invalidResponse:
      return 'El asistente tuvo un problema. Inténtalo de nuevo.';
    case AIError.internalError:
      return 'Error del servidor. Inténtalo más tarde.';
    case AIError.unauthenticated:
      return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
  }
}
```

---

## Rate limiting en Cloud Functions

```javascript
// functions/src/middleware/rateLimiter.js
const admin = require("firebase-admin");

/**
 * Limita las peticiones a la IA a 10 por hora por usuario.
 * Usa un documento en Firestore para trackear las peticiones.
 * 
 * ¿Por qué 10/hora? Equilibrio entre usabilidad y coste de API.
 * La generación de planes es una acción puntual, no continua.
 */
async function checkRateLimit(uid) {
  const rateLimitRef = admin.firestore()
    .collection("rate_limits")
    .doc(uid);
  
  const doc = await rateLimitRef.get();
  const now = Date.now();
  const oneHourAgo = now - (60 * 60 * 1000);

  if (doc.exists) {
    const requests = doc.data().requests || [];
    // Filtrar solo las peticiones de la última hora
    const recentRequests = requests.filter(ts => ts > oneHourAgo);
    
    if (recentRequests.length >= 10) {
      return false; // Límite alcanzado
    }
    
    // Añadir la nueva petición
    recentRequests.push(now);
    await rateLimitRef.update({ requests: recentRequests });
  } else {
    await rateLimitRef.set({ requests: [now] });
  }
  
  return true; // Petición permitida
}
```

---

## Sostenibilidad y eficiencia (RA 5)

Criterios de eficiencia técnica relacionados con la IA:

1. **Caché de planes**: Si el usuario ya tiene un plan generado, no regenerar automáticamente. Mostrar el existente y ofrecer "Generar nuevo plan".
2. **Prompt conciso**: Minimizar tokens enviados a la API (reduce coste y latencia).
3. **Respuestas acotadas**: `max_tokens: 2000` evita respuestas excesivamente largas.
4. **Rate limiting**: 10 peticiones/hora previene abuso y gasto innecesario.
5. **Lazy loading de conversaciones**: Cargar el historial de chat solo cuando el usuario accede a esa tab.
