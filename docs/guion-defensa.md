# Guion de defensa — HabitAI (TFG 2º DAM)

> **Estado de la app:** rama `demo-presentacion-defensa` (commit `770410f`, 9 may 2026).
> Este guion describe SOLO lo que existe en esa rama.
> **Reparto de tiempo:** Setup 5 min · Exposición + demo 15-20 min · Preguntas 10 min.
> **IA en esta versión:** todas las funciones usan `gemini-2.5-pro` vía Cloud Functions.

---

## FASE 0 — Setup (5 min, antes de hablar)

Checklist para no quemar tiempo de exposición:

- [ ] Emulador/dispositivo ya arrancado y desbloqueado.
- [ ] App ya compilada e instalada (`flutter run` lanzado antes de entrar).
- [ ] Sesión iniciada con un **usuario de demo con datos reales y coherentes** (hábitos con varios días de historial, rachas vivas, un plan IA ya generado, algún logro desbloqueado).
- [ ] Conexión a internet verificada (la IA llama a Cloud Functions — sin red, no hay demo de IA).
- [ ] Proyectos abiertos en segundo plano: IDE en el código clave (por si piden ver código) y la consola de Firebase (Firestore + Functions).
- [ ] Pantalla espejada / cable HDMI probado.

> Si el emulador tarda, ten un **vídeo de respaldo de 60-90 s** del flujo principal por si falla la red.

---

## FASE 1 — Exposición (15-20 min)

### 1. Contexto y valor (≈2 min)

**Qué dices:**
> "HabitAI es una app móvil de gestión de hábitos con inteligencia artificial. El problema que resuelve: la mayoría de apps de hábitos son listas de tareas glorificadas — te dejan solo ante el 'qué hábito creo y cómo lo mantengo'. HabitAI usa IA generativa para construir un plan de hábitos personalizado, renegociarlo cuando fallas en vez de castigarte, y darte una revisión semanal con análisis de tu progreso."

Puntos a soltar:
- Público: cualquiera que quiera construir hábitos de forma sostenible.
- Diferenciador: la IA no solo sugiere, **acompaña** (renegociación inteligente, efecto mariposa, revisión semanal).
- Origen TFG, ahora en fase de lanzamiento público real (keystore de producción, hosting legal, App Check). Esto demuestra que no es un proyecto de juguete.

### 2. Arquitectura y stack (≈4 min)

**Diagrama mental que describes (apóyate en slide):**

```
┌─────────────┐     HTTPS callable     ┌──────────────────┐    ┌────────────┐
│  Flutter    │ ───────────────────▶  │  Cloud Functions  │──▶ │ Gemini 2.5 │
│  (cliente)  │                        │  (europe-west1)   │    │   (API)    │
│             │ ◀───── Firestore ────▶ │  + Admin SDK      │    └────────────┘
└─────────────┘    (caché offline)     └──────────────────┘
       │                                        │
       └────── Firebase Auth (UID) ─────────────┘
```

**Qué dices:**
- **Frontend:** Flutter 3.41 + Dart, Material Design 3. Compila a nativo real.
- **Backend:** Firebase como BaaS serverless — Auth, Firestore (NoSQL, Europa), Cloud Functions.
- **IA:** nunca llamo a Gemini desde el cliente. El cliente llama a una Cloud Function que verifica el token, aplica rate limiting y construye el prompt. **La API key jamás sale del servidor** — aunque descompilen el APK, no la encuentran.
- **Arquitectura del código:** feature-first, 3 capas por feature:
  - `domain/` → modelos Dart puros (sin Firebase).
  - `data/` → repositorios (única capa que toca Firebase).
  - `presentation/` → pantallas y widgets (nunca importan Firestore directo).
- **Modelo de datos:** jerárquico. El UID de Auth es el nexo: `users/{uid}/habits/{habitId}/logs/{logId}`. Las reglas de seguridad validan `request.auth.uid == userId` en cada operación.

**Si preguntan por gestión de estado:** StreamBuilder para datos reactivos de Firestore, FutureBuilder para operaciones puntuales (generar plan IA), setState para UI local. Bloc/Riverpod añadirían complejidad sin beneficio para este alcance.

### 3. Justificación de RAs (≈3 min)

> ⚠️ **Ajusta esta sección a los RAs que seleccionaste realmente.** Plantilla:

| RA | Cómo lo implementé | Dónde lo enseño |
|----|--------------------|-----------------|
| RA2 — Apps móviles | App completa multiplataforma en Flutter, navegación con go_router, UI declarativa Material 3 | Toda la demo |
| RA4 — Entornos/servicios | Control de versiones Git con ramas por feature, análisis estático (`analysis_options.yaml`), peticiones HTTP asíncronas a Cloud Functions | Repo + `ai_repository.dart` |
| RA1 — Serialización/nube | Modelos con `fromJson`/`toJson`, persistencia en Firestore (computación en la nube) | `*_model.dart` |
| RA5 — Sostenibilidad | Caché local de Firestore, queries con filtros server-side, paginación, constructores `const`, lazy loading. Comentado con `// EFICIENCIA:` | Código del dashboard/repos |

**Qué dices (ejemplo RA5):**
> "La sostenibilidad no es decorativa: cada lectura de Firestore cuesta dinero y energía. Por eso pagino a 20 documentos, filtro en servidor en vez de en cliente, y aprovecho la caché offline de Firestore. Lo dejé comentado en el código con la etiqueta `// EFICIENCIA:` para que sea trazable."

### 4. Demostración en vivo (≈7-8 min)

> Narra MIENTRAS tocas. El tribunal valora fluidez y datos coherentes. Orden propuesto (de menor a mayor "efecto wow"):

**Flujo A — Auth (rápido, 30 s):**
- Muestra login. Menciona email/password + Google Sign-In. No pierdas tiempo registrándote en vivo: entra con el usuario de demo ya preparado.

**Flujo B — Hábitos y rachas (≈2 min):**
- Pantalla de hábitos con datos reales (rachas vivas, historial).
- Haz un **check-in en vivo** de un hábito → enseña cómo sube la racha (feedback háptico + animación).
- Muestra **habit stacking**: un grupo/cadena de hábitos (concepto de *Atomic Habits*), reordenamiento drag & drop.
- Di: "Los check-ins se guardan en la subcolección `logs` de cada hábito; la racha se recalcula a partir de ahí."

**Flujo C — IA (el plato fuerte, ≈3 min):**
- Abre el chat de IA y **genera un plan de hábitos en vivo** (esto llama a `generateHabitPlan` → Gemini 2.5 Pro).
- Mientras carga, explica: "Esto va a una Cloud Function en `europe-west1`, que verifica mi token, aplica rate limiting de 10 peticiones/hora, construye el prompt pidiendo JSON estricto, y Gemini devuelve un plan estructurado que parseo y muestro."
- Enseña también (aunque sea de datos ya generados, más rápido):
  - **Revisión semanal** (`weekly_review_screen`): análisis IA del progreso.
  - **Efecto mariposa** (`butterfly_projection_screen`): proyección a futuro.
  - **Renegociación**: cómo la IA reajusta un hábito en vez de penalizar.

**Flujo D — Gamificación y social (≈1-2 min):**
- Logros desbloqueados + niveles por categoría (radar chart).
- Comunidad: feed de plantillas compartidas, explorar usuarios, perfiles.

**Flujo E — Seguridad (30 s, opcional pero potente):**
- Abre la consola de Firebase → Firestore rules. Señala el `deny all` por defecto y `request.auth.uid == userId`.
- "Si intento leer datos de otro usuario, Firestore corta la petición antes de tocar la BD y devuelve `permission-denied`."

### 5. Cierre (≈1 min)

**Qué dices:**
> "HabitAI cubre el ciclo completo: una app móvil nativa, un backend serverless seguro, e IA generativa integrada de forma responsable — sin exponer claves y controlando costes. Salí de mi zona de confort aprendiendo Flutter y Firebase desde cero, lo que añade el vector de complejidad que pide el TFG. Y no se queda en prototipo: está preparada para lanzamiento real. Gracias, quedo a vuestras preguntas."

---

## FASE 2 — Preguntas y validación de autoría (10 min)

### Preguntas técnicas frecuentes (respuesta en 4 pasos: qué es → por qué → alternativa descartada → ejemplo)

**¿Por qué Flutter y no React Native?**
Compila a nativo real (no puente JS), Dart con null safety reduce bugs en compilación, Material 3 nativo. Y aprender stack nuevo = vector de complejidad del TFG.

**¿Por qué Firebase y no backend propio (Symfony/Node)?**
BaaS serverless: cero provisión de servidores, integración nativa con Flutter (FlutterFire), Auth+Firestore+Functions cubren todo, escalado automático. Descarté Supabase: menos madurez en ecosistema Flutter.

**¿Por qué Firestore y no Realtime Database?**
Queries compuestos (where+orderBy+limit), subcolecciones jerárquicas, caché offline por defecto, mejor escalado horizontal.

**¿Por qué Cloud Functions como proxy de IA y no llamar a Gemini directo?**
Seguridad (la API key nunca en el cliente), rate limiting centralizado, logging de costes, y flexibilidad (cambiar de modelo solo toca la función).

**¿Cómo garantizas que la IA devuelve datos usables?**
Prompt que exige JSON estricto + try-catch en el parseo + fallback. Triple red de seguridad.

**¿Por qué go_router?**
Navigator 2.0 es demasiado verboso; go_router da API declarativa, deep linking, guards con `redirect` y ShellRoute para los tabs. Es el router oficial del equipo Flutter.

### Validación de autoría — preparación

> El tribunal puede pedir explicar código concreto **o una pequeña modificación en vivo**. Aunque lo veas improbable, ten esto listo:

**Código que debes saber explicar de memoria** (ten estos archivos abiertos):
- `lib/features/auth/data/auth_repository.dart` → flujo de login (email + Google Sign-In).
- `lib/features/habits/data/` → cómo se guarda un check-in y se recalcula la racha.
- `functions/index.js` → `generateHabitPlan`: verificación de token, rate limiting, construcción del prompt, parseo del JSON.
- `firestore.rules` → la regla `request.auth.uid == userId`.

**Si piden una modificación pequeña en vivo, candidatas seguras y rápidas:**
- Cambiar un texto/label de una pantalla y hot reload (demuestra dominio del ciclo Flutter).
- Cambiar un color del tema en `core/theme/app_theme.dart`.
- Añadir un campo a un modelo y enseñar dónde se serializa (`toJson`/`fromJson`).
- Subir/bajar el límite de rate limiting en la Cloud Function.

> Regla de oro: si no sabes algo, di "esa parte la resolví así por X; si me das un momento lo localizo en el código" — buscarlo en vivo con criterio es mejor que inventar.

### Vocabulario para soltar con naturalidad
BaaS · serverless · NoSQL · UI declarativa · hot reload · null safety · Stream · widget tree · prompt engineering · Secret Manager · HTTPS callable.

---

## Recordatorios finales
- Habla a un ritmo que te deje margen: 15-20 min de contenido, no 25 comprimidos.
- Ante un fallo de demo: respira, usa el vídeo de respaldo, sigue. El tribunal valora la gestión del imprevisto.
- No menciones features que no están en esta rama (ánimo, escudos, retos, Flash, kill switch).
- Cierra cada respuesta técnica con el "ejemplo concreto en el código" — es lo que valida autoría.
