---
name: tribunal-defense
description: >
  Preparación para la defensa del TFG ante el tribunal. Usa esta skill cuando
  necesites preparar argumentos, anticipar preguntas del tribunal, justificar
  decisiones técnicas, preparar la presentación, o repasar los RAs (Resultados
  de Aprendizaje) cubiertos. También cuando quieras formular una respuesta
  defensible para cualquier decisión arquitectónica del proyecto.
---

# Tribunal Defense — HabitAI

## Estructura de respuesta ante el tribunal

Para cada pregunta técnica, responde con este esquema:

1. **¿Qué es?** → Definición breve (1-2 frases técnicas)
2. **¿Por qué lo elegimos?** → Justificación en el contexto de HabitAI
3. **¿Qué alternativas descartamos?** → Demostrar que se evaluaron opciones
4. **Ejemplo concreto** → Referencia al código del proyecto

---

## Preguntas frecuentes preparadas

### Sobre el stack tecnológico

**P: ¿Por qué Flutter y no React Native si ya lo conocías?**
- Flutter compila a código nativo real (ARM), mientras que RN usa un puente JavaScript.
- Dart tiene tipado fuerte y null safety, lo que reduce bugs en tiempo de compilación.
- Material Design 3 es nativo en Flutter, sin librerías externas.
- Salir de mi zona de confort es uno de los vectores de complejidad del TFG — aprender un stack nuevo demuestra capacidad de adaptación.

**P: ¿Por qué Firebase y no un backend propio con Symfony?**
- Firebase es una plataforma BaaS (Backend as a Service) serverless: no hay que provisionar ni mantener servidores.
- Integración nativa con Flutter mediante FlutterFire.
- Auth, Firestore y Cloud Functions cubren todas las necesidades del proyecto.
- Escalabilidad automática y plan gratuito generoso (Spark plan) para un TFG.
- El RA 6 pide específicamente demostrar comprensión de computación en la nube.
- Alternativa descartada: Supabase (menos madurez en el ecosistema Flutter, menos documentación en español).

**P: ¿Por qué go_router y no Navigator 2.0 manual?**
- Navigator 2.0 es excesivamente verboso para apps de tamaño medio (requiere RouterDelegate, RouteInformationParser...).
- go_router abstrae esa complejidad con una API declarativa limpia.
- Soporta deep linking, guards con redirect, y ShellRoute para tabs.
- Es el paquete de routing mantenido oficialmente por el equipo de Flutter.

**P: ¿Por qué Cloud Firestore y no Realtime Database?**
- Firestore soporta queries complejos (where + orderBy + limit).
- Modelo de datos jerárquico con subcolecciones (ideal para users/{uid}/habits/{id}).
- Escalabilidad horizontal superior.
- Modo offline por defecto (caché local automática).
- Realtime Database es más simple pero limitado en queries y estructura.

### Sobre la arquitectura

**P: ¿Qué patrón arquitectónico sigue la app?**
- Feature-first con separación en 3 capas: domain (modelos), data (repositorios), presentation (UI).
- Inspirado en Clean Architecture pero simplificado — sin use cases separados porque añadirían complejidad innecesaria para el tamaño del proyecto.
- Los repositorios actúan como capa de abstracción entre Firebase y la UI.

**P: ¿Por qué no usas Bloc o Riverpod para gestión de estado?**
- Para el alcance del proyecto, StreamBuilder + FutureBuilder + setState cubren todas las necesidades.
- StreamBuilder para datos reactivos de Firestore (listas, stats).
- FutureBuilder para operaciones puntuales (generar plan IA).
- setState para estado local de UI (formularios, toggles).
- Bloc/Riverpod añadirían complejidad arquitectónica sin beneficio proporcional para un MVP.
- Si la app creciera, migrar a Provider/Riverpod sería el siguiente paso natural.

**P: ¿Qué es el patrón Repository y por qué lo usas?**
- El Repository encapsula el acceso a datos (Firebase) detrás de una interfaz limpia.
- La UI nunca importa `cloud_firestore` directamente — solo conoce el repositorio.
- Beneficios: testeable (se puede mockear), intercambiable (si cambias de Firebase a Supabase, solo tocas el repositorio), separación de responsabilidades (SRP).

**P: ¿Por qué el UID de Firebase Auth es importante arquitectónicamente?**
- Es el nexo que conecta la identidad del usuario (Auth) con sus datos (Firestore).
- Estructura: `users/{uid}/habits/{habitId}/logs/{logId}`.
- Las reglas de seguridad validan `request.auth.uid == userId` en cada operación.
- Sin esta relación, no hay forma segura de vincular datos a usuarios.

### Sobre la IA

**P: ¿Por qué usas Cloud Functions como proxy y no llamas a la API directamente?**
- Seguridad: la API key de Claude/OpenAI NUNCA está en el código del cliente. Si alguien descompila la APK, no encontrará la clave.
- Rate limiting centralizado: controlar cuántas peticiones hace cada usuario.
- Logging: registrar uso para monitorizar costes.
- Flexibilidad: si cambias de Claude a OpenAI, solo modificas la Cloud Function, no la app.

**P: ¿Cómo garantizas que la IA devuelve datos estructurados?**
- System prompt explícito que pide SOLO JSON sin texto adicional.
- Formato de respuesta definido con campos obligatorios y tipos.
- Triple validación: (1) prompt restrictivo, (2) try-catch en parseo, (3) fallback a texto plano.
- Los modelos modernos de IA (Claude, GPT-4) siguen instrucciones de formato con alta fiabilidad.

**P: ¿Cómo manejas los costes de la API de IA?**
- Rate limiting: máximo 10 peticiones/hora por usuario.
- max_tokens limitado a 2000 (respuestas acotadas).
- Caché de planes: no regenerar si ya existe uno.
- La generación de hábitos es puntual (onboarding + ajustes ocasionales), no continua.

### Sobre seguridad

**P: ¿Qué reglas de seguridad tiene Firestore?**
- Deny all por defecto — ningún documento es accesible sin regla explícita.
- Cada usuario solo puede leer/escribir sus propios datos (`request.auth.uid == userId`).
- Validación de estructura: los documentos deben tener campos obligatorios con tipos correctos.
- Logros y conversaciones IA son inmutables (no se pueden editar ni borrar).
- Cloud Functions usan tokens de auth verificados por Firebase Admin SDK.

**P: ¿Qué pasa si alguien intenta acceder a datos de otro usuario?**
- Las reglas de Firestore bloquean la petición antes de que llegue a la base de datos.
- Firestore devuelve un error `permission-denied` que la app traduce a un mensaje amigable.
- No se expone información sobre la existencia del documento ajeno.

### Sobre sostenibilidad (RA 5)

**P: ¿Cómo reduces el impacto ambiental de la app?**
- Caché local de Firestore: reduce transferencia de datos al servidor.
- Queries optimizados con filtros server-side: solo traer datos necesarios.
- Paginación: cargar 20 documentos por vez, no todos.
- Constructores `const`: reducir rebuilds innecesarios del framework.
- Lazy loading: cargar datos solo cuando el usuario los necesita.
- Cada optimización está comentada con `// EFICIENCIA:` o `// SOSTENIBILIDAD:` en el código.

---

## Mapeo de evidencias a RAs

| RA | Evidencia | Ubicación en el código |
|----|-----------|----------------------|
| RA 2 (Móviles) | App completa en Flutter | Todo `lib/` |
| RA 4 (Entornos) | Git + análisis estático | `.gitignore`, `analysis_options.yaml`, GitHub repo |
| RA 1 (Marcas) | Serialización JSON | `*_model.dart` (fromJson/toJson) |
| RA 4 (Servicios) | Peticiones HTTP asíncronas | `features/ai/data/ai_repository.dart` |
| RA 5 (Sostenibilidad) | Optimizaciones de eficiencia | Comentarios `// EFICIENCIA:` en el código |
| RA 1 (Nube) | Documento técnico Firebase | Anexo a la memoria del TFG |

---

## Vocabulario técnico clave para la defensa

- **BaaS**: Backend as a Service — Firebase provee backend sin gestionar servidores.
- **Serverless**: Ejecutar código en la nube sin administrar infraestructura.
- **NoSQL**: Base de datos no relacional — documentos JSON en vez de tablas SQL.
- **UI declarativa**: Describes QUÉ quieres ver, no CÓMO construirlo paso a paso.
- **Hot Reload**: Recarga el código en caliente sin perder el estado de la app.
- **Null Safety**: Garantía del compilador de que no hay `null` donde no se espera.
- **Stream**: Flujo continuo de datos que emite valores a lo largo del tiempo.
- **Widget tree**: Árbol jerárquico que describe toda la UI de la app.
- **Prompt engineering**: Diseño de instrucciones para obtener respuestas específicas de la IA.
- **Secret Manager**: Servicio de Google Cloud para almacenar credenciales de forma segura.
