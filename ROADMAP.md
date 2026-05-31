# HabitAI — Roadmap y Backlog

Referenciado desde CLAUDE.md. Contiene el roadmap de lanzamiento público y el backlog de ideas.

**Estado**: TFG completado y defendido. Fase actual → preparación para lanzamiento público.

---

## Roadmap — Camino al lanzamiento público

### Fase A — Autenticación y onboarding mejorado

20. ✅ Inicio de sesión con Google/Apple — `google_sign_in` + `sign_in_with_apple`, OAuth en Firebase Console. FALTA CONFIGURAR APPLE_SIGN_IN EN CONSOLA DE APPLE Y FIREBASE PARA iOS.

### Fase B — IA como coach real (diferenciador clave)

21. ✅ Revisión semanal con IA — Cloud Scheduler + Cloud Function + Gemini. Desplegado en europe-west1.

22. ✅ Renegociación inteligente — Si 3 días fallando, IA propone adaptar. Desplegado.

23. ✅ Detección de patrones con IA — Correlaciones entre logs, Cloud Function + Gemini interpreta, pantalla de insights. Desplegado.

24. ✅ Modo día libre / escudos de racha — Escudos ganados en rachas largas, modo enfermedad congela racha.

### Fase C — Engagement diario

25. ✅ Habit stacking (Atomic Habits) — Cadenas de hábitos con grupos, drag & drop, bonus XP, onboarding. Desplegado.
26. ✅ Tracking de energía/ánimo — Registro multi-franja (rating 1-5 + etiquetas + nota), heatmap mensual, pantalla de correlación ánimo-hábitos con nivel de confianza y efecto retardado (día siguiente), integrado en la revisión semanal IA. Datos privados, borrados al eliminar cuenta. Lógica pura testeada (`mood_math.dart`).
27. 🔲 Widgets de home screen — `home_widget` (Android nativo + iOS WidgetKit). Check-in sin abrir app.

### Fase D — Marketing orgánico

28. 🔲 HabitAI Wrapped — Resumen visual mensual/anual tipo Spotify Wrapped. Compartible en redes.

29. ✅ Simulador del "Efecto Mariposa" — Proyección a 3 años con Gemini. Desplegado.

### Fase E — Red social tipo Instagram

**Modelo**: Instagram — perfiles públicos/privados, followers/following, solicitudes pendientes para cuentas privadas.

**Grafo social — `follows/{followId}`**: `followerId + followingId + status (pending|accepted) + createdAt`. Reglas: leer donde `followingId == auth.uid` o `followerId == auth.uid`.

**Visibilidad de hábitos**:
- `isProfilePublic: true` + `habitVisibility: "public"` → visible para todos
- `isProfilePublic: true` + `habitVisibility: "followers"` → solo seguidores aceptados
- `isProfilePublic: false` → requiere solicitud; tras aceptar, aplica `habitVisibility`
- `visibility` individual en hábito sobreescribe `habitVisibility` global

**FollowRepository** (`features/social/data/`):
- `sendFollowRequest(targetUid)` — pending (privado) o accepted (público)
- `acceptFollowRequest(followId)` / `rejectFollowRequest(followId)` / `removeFollower(followId)`
- `unfollow(targetUid)`
- `watchFollowers(uid)` / `watchFollowing(uid)` / `watchPendingRequests(uid)` — streams paginados
- `isFollowing(targetUid)` — bool reactivo

**PublicProfileScreen**: avatar + username + bio + contadores. Botón contextual: Seguir | Solicitar | Pendiente | Siguiendo. Feed de hábitos según visibilidad.

**SocialNotificationsScreen**: bandeja de solicitudes (Aceptar/Rechazar). Badge en BottomNav cuando hay pendientes.

30. ✅ Plantillas de la comunidad — `community_templates/{templateId}`. Feed paginado, filtros, import con tap.
31. ✅ Perfiles públicos — Perfil completo con logros, stats, seguidores, sincronización en tiempo real.
32. ✅ Sistema de follows / solicitudes — FollowRepository, solicitudes para privados, follow directo para públicos, badges en BottomNav, pantalla de seguidores/seguidos, cancelación de solicitudes.
33. ✅ Retos compartidos — 21 días con otro usuario. Doc compartido, seguimiento de progreso dual. Desplegado.
34. 🔲 Aplausos anónimos — 👏 desde perfil de seguido → notificación push. Solo entre follows.
35. 🔲 Tabla de líderes por categoría — Rankings semanales entre seguidores. Cloud Function agrega filtrando grafo.
36. 🔲 Accountability buddy — Match automático por hábitos similares. 7 días de check-ins mutuos.
37. 🔲 Grupos de hábito público — Alguien publica grupo, otros se unen. Contador global de participantes activos.
38. 🔲 "Ola de constancia" — Mapa de calor global anónimo con contadores por categoría.

### Fase F — Gamificación avanzada

39. ✅ Sistema de logros con niveles — Principiante → Experto por categoría, radar chart hexagonal.
40. 🔲 Contrato de compromiso — Cantidad simbólica o donación a ONG. Modelo StickK. Requiere pasarela de pago.

### Fase G — Preparación para lanzamiento público

41. ✅ Política de privacidad y términos de uso — Documentos legales en Firebase Hosting, links en Settings y registro.
42. ✅ Release signing Android — Keystore de producción, build.gradle.kts configurado, AAB generado.
43. ✅ Eliminación de cuenta — Borrado completo de datos (Firestore, Storage, Auth) con doble confirmación.
44. ✅ Feedback háptico — Vibración en check-in, navegación entre pestañas, botones. FeedbackService centralizado.
45. ✅ Reordenamiento de hábitos — Drag & drop global y edición por lotes.
46. ✅ Visibilidad granular de hábitos — Cada hábito con visibility individual, sobreescribe config global.
47. ✅ Firebase Crashlytics + Analytics — Crashlytics captura errores de framework y asíncronos (`main.dart` con `runZonedGuarded`), `AnalyticsService` para eventos.
48. 🔲 Manejo de modo offline
49. 🔲 Push notifications con FCM
50. 🔲 Tests mínimos (modelos + repos) — en progreso: tests de modelos de dominio (hábitos, social, IA, retos, niveles…) y de la lógica de ánimo (modelo `MoodEntryModel` + funciones puras de correlación).
51. ✅ Blindaje de costes Firebase/Gemini — `maxInstances` (10 global, 3 IA), modelos Flash en jobs de fondo (Pro solo en chat), App Check (cliente activado, app registrada con upload key), kill switch de facturación a 20€ (`killBillingOnBudgetExceeded` + topic `billing-alerts`), caché Firestore 100MB, límite en `watchConversations`. Precios y predicción → `docs/gemini-costes.md`.
    - 🔲 PENDIENTE: activar Enforce de App Check tras subir a Play (+ añadir App Signing SHA), migrar functions a Node.js 22 antes del 2026-10-30, subir presupuesto de 20€ al crecer (autoapaga la app si se supera).

---

## Ideas de features futuras (backlog)

### Prioridad alta (viables para el TFG)

- **Emojis en hábitos**: campo `emoji: string?` en HabitModel. UI más personal.
- **Modo "En Llamas" (Streak Fire)**: racha >5 días → borde brillante + icono fuego animado (flutter_animate/Rive).
- **Sonidos y háptica de recompensa**: feedback sonoro al completar hábito. Patrones configurables.
- **Aura de perfil evolutiva**: borde de foto: bronce → plata → oro → fuego → cósmico. Campo `auraLevel: int`.

### Prioridad media (post-TFG)

- **Mascota virtual (Tamagotchi)**: avatar que sube nivel con check-ins. `PetModel` con nivel/estado/experiencia.
- **Árbol de habilidades RPG**: hábitos alimentan stats de personaje (radar hexagonal). `UserStatsModel`.
- **"Pergamino de Victorias"**: feed infinito de días exitosos y rachas. Acceso desde foto de perfil.
- **Modo "Monje" (Focus Timer)**: temporizador — salir de la app = hábito falla. `AppLifecycleState`.

### Prioridad baja (infraestructura adicional)

- **Ghost Racing**: rival anónimo con el mismo hábito. Queries cross-user + matchmaking.
- **Widgets Live Activities**: pantalla de bloqueo con progreso circular. MethodChannel Android + iOS WidgetKit.
