# CLAUDE.md — HabitAI

## Identidad del proyecto

**HabitAI** — app móvil de gestión de hábitos con IA. Origen: TFG de 2º DAM (completado). Fase actual: lanzamiento público.  
**Autor**: Andrei Felipe Staicu  
**Código**: variables/clases en inglés, comentarios en español.

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter 3.41.6 + Dart 3.x, Material Design 3 |
| Navegación | go_router |
| Animaciones | flutter_animate |
| Auth | Firebase Authentication |
| BD | Cloud Firestore (Europa) |
| IA | Gemini via Cloud Functions (europe-west1): `gemini-2.5-pro` en chat, `gemini-2.5-flash` en jobs de fondo |
| Feedback | vibration, url_launcher |
| Charts | fl_chart |
| Storage | firebase_storage, image_picker |
| Paquetes | firebase_core, firebase_auth, cloud_firestore, cloud_functions, go_router, flutter_animate, google_sign_in, google_fonts, shared_preferences, flutter_local_notifications |

---

## Paleta de colores

| Rol | Hex |
|-----|-----|
| Primary | `#38BDF8` |
| Secondary | `#0EA5E9` |
| Success | `#10B981` |
| Streak/Logros | `#F59E0B` |
| Error | `#EF4444` |
| Surface light | `#F0F9FF` |
| Background | `#FFFFFF` |
| Dark bg | `#0F172A` |
| Texto principal | `#0F172A` |
| Texto secundario | `#64748B` |

**Categorías** (fondo / texto): Salud `#CCFBF1/#115E59` · Productividad `#E0F2FE/#0C4A6E` · Bienestar `#FEF3C7/#92400E` · Social `#FCE7F3/#9D174D` · Aprendizaje `#EDE9FE/#5B21B6` · Finanzas `#FEE2E2/#991B1B`

---

## Navegación de Contexto (Vía Graphify) — OBLIGATORIO

**PROHIBIDO** usar `Grep`, `Glob` o `Read` sobre archivos de código (`.dart`, `.js`, etc.) sin haber leído antes `graphify-out/GRAPH_REPORT.md` en la sesión actual.

Orden estricto:
1. **Graphify**: Lee `graphify-out/GRAPH_REPORT.md` (y `graph.json` si hace falta).
2. **Obsidian**: `obsidian-boveda/habit-ai-graph/` para decisiones de diseño.
3. **Código crudo**: solo el archivo concreto a editar.

**Excepción única**: ruta exacta dada por el usuario + edit puntual de una línea.  
Cualquier otra tarea (features, arquitectura, refactors, subagentes) → graphify primero.

---

## Arquitectura del proyecto

Feature-first: `lib/features/{auth,habits,dashboard,ai,achievements,settings,social,challenges,community,profile,levels,notifications,explore}/`  
Cada feature: `data/` (repositorios Firebase) → `domain/` (modelos Dart puros) → `presentation/` (screens/widgets, nunca Firebase directo).  
Core compartido: `core/theme/app_theme.dart`, `core/router/app_router.dart`, `core/widgets/`, `core/widgets/ux/`, `core/services/feedback_service.dart`.  
Servicios: `services/notification_service.dart`.  
Hosting: `public/` — landing, política de privacidad y términos de uso en Firebase Hosting.

---

## Reglas de codificación

1. **StatelessWidget** sin estado mutable; **StatefulWidget** con setState/controladores/animaciones.
2. **Nunca lógica de negocio en widgets** — widgets llaman al repositorio, reaccionan al resultado.
3. **`const`** en constructores siempre que sea posible.
4. **Named parameters** con `required` en widgets públicos. Trailing commas siempre.
5. Rutas en `core/router/app_router.dart`. `GoRoute` con `name`. Guards via `redirect`. `ShellRoute` para BottomNav.
6. **StreamBuilder** para datos reactivos; **FutureBuilder** para operaciones puntuales; **setState** para UI local.
7. **Nunca exponer API keys** en cliente. IA siempre via Cloud Functions.
8. Regla Firestore base: `request.auth.uid == userId`. Ver `firestore.rules`.
9. **Commits semánticos**: `feat:`, `fix:`, `docs:`.

---

## Modelo de datos (colecciones Firestore)

- `users/{uid}` — perfil, `isProfilePublic`, `habitVisibility`, `shieldsCount`, `sickModeStart/Until`, `username`
- `users/{uid}/habits/{habitId}` — hábitos con `visibility` individual, `isAIGenerated`, rachas, `groupId`, `stackOrder`
- `users/{uid}/habits/{habitId}/logs/{logId}` — check-ins diarios
- `users/{uid}/mood_entries/{entryId}` — registros de ánimo/energía por franja horaria (privados, nunca públicos)
- `users/{uid}/achievements/{achievementId}` — logros (inmutables)
- `users/{uid}/ai_conversations/{conversationId}` — historial chat IA (inmutables)
- `users/{uid}/weekly_reviews/{weekId}` — revisiones semanales Gemini (solo admin SDK)
- `users/{uid}/butterfly_projections/{monthId}` — proyecciones mensuales (solo admin SDK)
- `users/{uid}/pattern_insights/{periodId}` — detección de patrones IA (solo admin SDK)
- `users/{uid}/renegotiations/{habitId}` — propuestas de renegociación IA
- `users/{uid}/shield_grants/{grantId}` — deduplicación de escudos concedidos
- `users/{uid}/followers/{uid}` — seguidores (subcolección)
- `users/{uid}/following/{uid}` — seguidos (subcolección)
- `user_directory/{uid}` — entrada ligera para búsqueda por username y privacidad
- `usernames/{username}` — reserva de usernames únicos
- `follow_requests/{requestId}` — solicitudes de seguimiento (pending/accepted/declined)
- `community_templates/{templateId}` — plantillas globales

`visibility` individual en hábito sobreescribe `habitVisibility` global del usuario.

---

## Integración con IA (Gemini 2.5)

```
Flutter → Cloud Function (HTTPS callable, europe-west1) → Gemini API
```
Cloud Function: verifica auth token → rate limiting (10 req/hora) → construye prompt → parsea JSON → devuelve al cliente.  
Prompts: JSON estricto, contexto usuario, máx. 5-7 hábitos, incluir categoría/frecuencia/horario.

**Modelos** (constantes `MODEL_PRO`/`MODEL_FLASH` en `functions/index.js`):
- `gemini-2.5-pro` → solo chat interactivo (`generateHabitPlan`).
- `gemini-2.5-flash` → jobs de fondo (revisión semanal, mariposa, renegociación, patrones). ~10-20× más barato.
- Nombre válido es `gemini-2.5-flash`, NO `gemini-flash-2-5` (404). Precios y predicción de coste → `docs/gemini-costes.md`.

---

## Flujo de navegación

```
SplashScreen → auth state
  ├── No auth → LoginScreen ↔ RegisterScreen (con Google Sign-In)
  └── Auth
      ├── onboardingCompleted=false → OnboardingFlow
      └── onboardingCompleted=true → MainShell (BottomNav 4 tabs)
          Tab 1: HabitsScreen · Tab 2: DashboardScreen · Tab 3: AIScreen · Tab 4: SettingsScreen
          + Drawer: Perfil, Explorar, Retos, Niveles, Notificaciones, Comunidad
```

---

## Skills disponibles

| Skill | Cuándo usarla |
|-------|---------------|
| `flutter-architecture` | Estructura, widgets, patrones |
| `firebase-backend` | Auth, Firestore, Cloud Functions, seguridad |
| `ai-integration` | Prompt engineering, Cloud Functions proxy, parseo |
| `ui-design` | Material 3, animaciones, componentes |
| `performance-and-quality` | Linting, rendimiento, RA 5 |
| `tribunal-defense` | Preparación defensa TFG |

---

## Estado del proyecto

TFG completado y defendido. Fase actual: **lanzamiento público**.

**Features implementadas (mayo 2026):**
- Auth: email/password + Google Sign-In, onboarding
- Hábitos: CRUD, check-ins, rachas, escudos de racha, modo enfermedad, reordenamiento drag & drop, edición por lotes
- Habit stacking: cadenas de hábitos (Atomic Habits), grupos, bonus XP, drag & drop dentro de cadena
- IA: chat con Gemini, revisión semanal, renegociación inteligente, efecto mariposa, detección de patrones
- Ánimo: tracking de energía/ánimo multi-franja (rating 1-5 + etiquetas + nota), heatmap mensual, correlación ánimo-hábitos con nivel de confianza y efecto retardado, integrado en la revisión semanal IA
- Social: perfiles públicos/privados, sistema de follows con solicitudes, visibilidad granular, badges de notificación, directorio de usuarios con búsqueda por username
- Retos compartidos: 21 días con otro usuario, seguimiento dual
- Comunidad: plantillas compartidas, feed paginado con filtros
- Gamificación: logros con niveles por categoría, radar chart hexagonal
- UX: feedback háptico, skeleton loaders, animaciones con flutter_animate, notificaciones locales
- Legal: política de privacidad + términos en Firebase Hosting, eliminación de cuenta con doble confirmación
- Release: keystore de producción configurado, AAB generado
- Costes: blindaje Firebase/Gemini — `maxInstances` (10 global, 3 IA), modelos Flash en jobs, App Check (cliente activado), kill switch de facturación a 20€ (función `killBillingOnBudgetExceeded` + topic `billing-alerts`), caché Firestore 100MB. Ver `docs/gemini-costes.md`.

**Pendiente para lanzamiento:** manejo offline, FCM push, tests mínimos. App Check: activar Enforce tras subir a Play (+ añadir App Signing SHA). Migrar functions a Node.js 22 antes del 2026-10-30. Subir presupuesto de 20€ al crecer (autoapaga la app si se supera).

Ver roadmap completo y backlog → **ROADMAP.md**

---

## Entorno de desarrollo

- SO: EndeavourOS Linux | Flutter 3.41.6 | Emulador: Android API 36
- Firebase: Firestore en Europa, plan Blaze activo
- Cloud Functions: Node.js 20 (⚠️ decomisado 2026-10-30, migrar a 22), region europe-west1, API key Gemini como secret. `setGlobalOptions` con `maxInstances: 10`

---

## graphify

Grafo en `graphify-out/`. Si `graphify-out/wiki/index.md` existe, usarlo en vez de leer archivos raw.

Tras editar código en la sesión, actualizar el grafo:
```
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

| Situación | Comando |
|-----------|---------|
| Sesión nueva / muchos cambios | `/graphify` |
| Cambios incrementales | `/graphify --update` |
| Sesión larga en Android Studio | `/graphify --watch` |
| Tras `git commit` | Automático (post-commit hook) |

**Git hook**: `.git/hooks/post-commit` y `post-checkout` tienen `export PATH="$HOME/.local/bin:$PATH"` al inicio (Android Studio no hereda el PATH de fish). Si reinstalás el hook con `graphify hook install`, hay que añadir el export manualmente.  
Verificar hook activo: `graphify hook status`
