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

Valores reales del tema (`lib/core/theme/app_theme.dart`). Sistema visual completo (escala de superficies, tipografía, componentes) → **DESIGN.md**.

| Rol | Hex |
|-----|-----|
| Primary (Deep Harbor Teal) | `#00668A` |
| Primary container (Sky) | `#38BDF8` |
| Secondary (Signal Blue) | `#006591` / container `#39B8FD` |
| Tertiary / Streak / Logros (Amber) | `#F59E0B` (deep `#855300`) |
| Success (gradiente emerald) | `#059669` → `#34D399` |
| Error | `#BA1A1A` / container `#FFDAD6` |
| Surface (campo) | `#F8F9FF` |
| Background / cards (lowest) | `#FFFFFF` |
| Escala de superficies (low→highest) | `#EFF4FF` · `#E5EEFF` · `#DCE9FF` · `#D3E4FE` |
| Dark bg | `#0F1620` |
| Texto principal (Ink) | `#0B1C30` |
| Texto secundario (Slate) | `#3E484F` |

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

Feature-first: `lib/features/{auth,onboarding,habits,dashboard,ai,achievements,settings,social,challenges,community,profile,levels,notifications,explore}/`  
Cada feature: `data/` (repositorios Firebase) → `domain/` (modelos Dart puros) → `presentation/` (screens/widgets, nunca Firebase directo).  
Core compartido: `core/theme/app_theme.dart`, `core/router/app_router.dart`, `core/widgets/`, `core/widgets/ux/`, `core/services/feedback_service.dart`.  
Servicios: `services/notification_service.dart`.  
Hosting: `public/` — landing, política de privacidad, términos de uso y `reset-password.html` (action handler propio de restablecimiento de contraseña: valida el `oobCode` y cambia la contraseña contra la REST API de Identity Toolkit, sin SDK; requiere "Personalizar URL de acción" en Authentication → Plantillas apuntando a `https://habit-ai-184ad.web.app/reset-password.html`).

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

- `users/{uid}` — perfil, `isProfilePublic`, `habitVisibility`, `shieldsCount`, `sickModeStart/Until`, `username`, `onboardingCompleted`, `onboardingGoals`, `lastActiveAt` (marca por sesión para la futura limpieza de cuentas inactivas), `isPremium`/`premiumUntil`/`freePlanUsage` (solo Admin SDK — bloqueados al cliente en rules)
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
- `users/{uid}/fcm_tokens/{token}` — tokens de dispositivo para push (FCM)
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
- `gemini-2.5-pro` → solo chat interactivo (`generateHabitPlan`, `routineChat`).
- `gemini-2.5-flash` → jobs de fondo (revisión semanal, mariposa, renegociación, patrones). ~10-20× más barato.
- Nombre válido es `gemini-2.5-flash`, NO `gemini-flash-2-5` (404). Precios y predicción de coste → `docs/gemini-costes.md`.

---

## Flujo de navegación

```
SplashScreen → auth state
  ├── No auth → LoginScreen ↔ RegisterScreen (con Google Sign-In)
  └── Auth
      ├── onboardingCompleted=false → OnboardingFlow (vía OnboardingGate)
      └── onboardingCompleted=true → MainShell (BottomNav 5 tabs, swipe entre tabs)
          Tab 1: HabitsScreen (/) · Tab 2: DashboardScreen (/dashboard) · Tab 3: AIScreen (/ai)
          Tab 4: ExploreScreen (/explore) · Tab 5: ProfileScreen (/profile)
```

- **OnboardingFlow** (`lib/features/onboarding/`): 8 pasos sobre fondo de gradiente animado — bienvenida → nombre → áreas → estilo de vida → plan generado por IA (con receta auto-escrita y confeti) → primer check-in real (racha de 1 día) → tour de funciones IA → permiso de notificaciones con preview. `OnboardingGate` envuelve el `MainShell` en el router y lee `onboardingCompleted` una vez por sesión (doc ausente = mostrar onboarding, por la carrera con `_ensureUserDoc` en el registro). El plan se guarda como grupo + hábitos reutilizando el flujo del chat IA; las áreas elegidas se persisten en `onboardingGoals`.

- **HabitsScreen**: grupos como acordeones + hábitos sueltos, todos visibles (completados incluidos — ver lo logrado refuerza al usuario; NO ocultar completados, decisión explícita). Header con campana de notificaciones (badge) que abre `NotificationsBottomSheet`. Las propuestas de renegociación IA NO van como banner por hábito (empapelaban la lista a usuarios poco activos): se agrupan en una única tarjeta `RenegotiationInboxCard` arriba de la lista que abre `RenegotiationInboxSheet` (cada propuesta con aplicar/descartar, reutilizando `CoachBanner` de `widgets/renegotiation_inbox.dart`).
- **ExploreScreen** agrupa lo social: desde ahí se llega a Comunidad (`/community`), Retos (`/challenges`) y perfiles públicos (`/profiles/:userId`).
- **ProfileScreen** (propio): header centrado clásico (avatar grande, @username, seguidores, bento de stats) + tabs deslizables Hábitos · Maestría debajo. El header compacto estilo Instagram se probó y se descartó; las tabs sí gustaron. Tap en avatar abre `ProfilePhotoViewer` (foto fullscreen con swipe-to-dismiss). Ajustes via icono ⚙ (`/settings`).
- **PublicProfileScreen** (otros usuarios): header centrado + tabs Hábitos · Logros + visor de foto.
- **Drawer** (hamburguesa en headers): Logros, Ánimo, Todos los hábitos, Revisión semanal, Mariposa, Crear hábito, Chat IA, Modo enfermedad, Ajustes. Sin Niveles (duplicaría Perfil → Maestría).
- Badge en tab Perfil = solicitudes de seguimiento pendientes.

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

**Features implementadas (junio 2026):**
- Auth: email/password + Google Sign-In. Recuperación de contraseña: enlace en login → diálogo (`_ForgotPasswordDialog`, posee su controller — hacer dispose desde fuera rompe la animación de cierre) → `AuthRepository.sendPasswordResetEmail` (lo envía Firebase Auth gratis, sin SMTP). Mensaje de éxito genérico a propósito (no revela si la cuenta existe). El enlace del correo aterriza en `public/reset-password.html`
- Onboarding interactivo: 8 pasos animados que terminan con plan IA generado y primer check-in hecho (ver Flujo de navegación)
- Hábitos: CRUD, check-ins, rachas, escudos de racha, modo enfermedad, reordenamiento drag & drop, edición por lotes
- Habit stacking: cadenas de hábitos (Atomic Habits), grupos, bonus XP, drag & drop dentro de cadena
- IA: chat con Gemini, revisión semanal, renegociación inteligente, efecto mariposa, detección de patrones
- Chat de rutina (premium): callable `routineChat` (Gemini Pro) con contexto completo del grupo — hábitos, rachas y logs de 30 días reconstruidos en cada mensaje. Propone cambios estructurados (updates con whitelist de campos + newHabits, máx. 3, nunca borrados) que `RoutineChatScreen` aplica con un toque via `updateHabit`/`createHabit`. Acceso: icono ✨ en `GroupDetailScreen` y opción en el menú ⋮ del acordeón de grupo en `HabitsScreen` → ruta `/group/:groupId/chat` tras `PremiumGuard`
- Ánimo: tracking de energía/ánimo multi-franja (rating 1-5 + etiquetas + nota), heatmap mensual, correlación ánimo-hábitos con nivel de confianza y efecto retardado, integrado en la revisión semanal IA
- Social: perfiles públicos/privados, sistema de follows con solicitudes, visibilidad granular, badges de notificación, directorio de usuarios con búsqueda por username
- Retos compartidos: 21 días con otro usuario, seguimiento dual
- Comunidad: plantillas compartidas, feed paginado con filtros
- Gamificación: logros con niveles por categoría, radar chart hexagonal
- UX: feedback háptico, skeleton loaders, animaciones con flutter_animate, notificaciones locales
- Push FCM (`functions/index.js`, helper `sendPushToUser` con limpieza de tokens muertos): follows y solicitudes, retos (invitación, aceptado/rechazado, completado, pique al completar día el rival, marcador a 3 días y último día), reacciones de perfil, logros (`skipForeground` evita duplicar el overlay in-app), jobs IA (revisión semanal, mariposa, patrones, renegociación con cap 1/usuario/día — el `renegotiationJob` genera UNA sola propuesta por usuario, la del hábito fallado más recientemente, no una por cada hábito atascado), racha en riesgo (20:30), fin de modo enfermedad y resumen dominical (domingo 19:00). Deep links via campo `route` en data
- Widgets de home screen (#27): paquete `home_widget` 0.7 (0.8 exige compileSdk 37). `HomeWidgetService` (`lib/services/`) publica el payload del día y procesa check-ins; Android = RemoteViews (`HabitWidgetProvider.kt`) con check-in vía callback Dart en fondo; iOS = extensión WidgetKit (`ios/HabitWidget/`) con App Intent (iOS 17+) que marca optimista y encola en App Group `group.com.andreistaicu.habitai` — la app reconcilia al abrir. En iOS 15/16 el tap abre la app
- Legal: política de privacidad + términos en Firebase Hosting, eliminación de cuenta con doble confirmación
- Release: keystore de producción configurado, AAB generado
- iOS: cuenta Apple Developer activa, CI/CD con Codemagic (`codemagic.yaml`) compila y firma sin Mac, sube a TestFlight. App probada y funcionando en iPhone vía testing interno. Bundle ID `com.andreistaicu.habitai`, mínimo iOS 15.0. Clave privada de firma persistente en variable `CERTIFICATE_PRIVATE_KEY` (grupo `ios_signing`) de Codemagic.
- Costes: blindaje Firebase/Gemini — `maxInstances` (10 global, 3 IA), modelos Flash en jobs, App Check (cliente activado), caché Firestore 100MB. Ver `docs/gemini-costes.md`.
- Monetización freemium (premium 3,99 €/mes): gates en backend — los 4 callables IA premium (`assertPremium`), los 4 jobs `onSchedule` saltan usuarios free, `generateHabitPlan` con cuota free de 7 mensajes/mes (`consumeFreePlanQuota`, contador `users/{uid}.freePlanUsage`, errores con `details.reason` = `premium_required`/`free_plan_quota`). Cliente: `PremiumService` (`lib/core/services/`, ValueNotifiers `isPremium` y `freePlanMessagesLeft`), `PremiumLimits` (7 hábitos free), `PaywallScreen` + ruta `/paywall`, `PremiumGuard` envuelve revisión semanal/mariposa/patrones/mood-insights en el router, `PremiumGate.checkHabitLimit` en los 3 puntos de creación manual de hábitos (onboarding/retos/plantillas exentos), contador de mensajes free en el chat IA. **Billing real con RevenueCat (código hecho, falta config en paneles):** `purchases_flutter` en pubspec; `BillingService` (`lib/core/services/billing_service.dart`) envuelve el SDK — `init` se autoconfigura solo si hay API key (si no, queda inerte y la app arranca igual), sigue `authStateChanges` para mantener `app_user_id` = uid de Firebase (`Purchases.logIn`), expone `purchaseMonthly`/`restore`/`monthlyPackage` contra el entitlement `premium`. `PaywallScreen` (ahora StatefulWidget) conecta el CTA a la compra + botón "Restaurar compras" (obligatorio iOS); distingue cancelación de error vía `PurchasesErrorCode.purchaseCancelledError`. Backend: webhook HTTP `revenueCatWebhook` (`onRequest`, europe-west1, secret `REVENUECAT_WEBHOOK_TOKEN` en header `Authorization`) — concede premium en INITIAL_PURCHASE/RENEWAL/PRODUCT_CHANGE/UNCANCELLATION/NON_RENEWING_PURCHASE/SUBSCRIPTION_EXTENDED escribiendo `isPremium`+`premiumUntil` (de `expiration_at_ms`) con Admin SDK, revoca en EXPIRATION; ignora ids `$RCAnonymousID:`; la cancelación NO revoca (manda `premiumUntil`). El estado premium sigue siendo Firestore→`PremiumService` (RevenueCat solo cobra y avisa). **Falta (manual, no-código):** crear suscripción `habitai_premium_monthly` 3,99€/mes en Play Console + App Store Connect, crear proyecto/entitlement `premium`/offering en RevenueCat, pegar las 2 API keys públicas en `billing_service.dart` (`_androidApiKey`/`_iosApiKey`), `firebase functions:secrets:set REVENUECAT_WEBHOOK_TOKEN` + mismo valor en el panel de RevenueCat, registrar la URL del webhook desplegado, probar en sandbox
- Retención de datos: campo TTL `expiresAt` en colecciones efímeras (chats IA 30d, revisiones 8 sem, mariposa 3 m, patrones 60d, renegociaciones 30d, follow_requests 90d/7d, fcm_tokens 120d, rate_limits 7d). `shield_grants` excluida a propósito (la dedupe de escudos debe vivir tanto como la racha). Plazos, comandos `gcloud` y backfill → `docs/retencion-datos.md`.

**Pendiente para lanzamiento:** rematar el billing RevenueCat (config en paneles + API keys + secret del webhook + sandbox — el código ya está, ver bullet de monetización). URL de acción de las plantillas de Auth → `https://gethabitai.com/reset-password.html`: BLOQUEADA por un **registro huérfano del dominio de correo personalizado** atascado en el backend (diagnóstico 2026-06-13). Estado real: `notification.sendEmail.dnsInfo.customDomain = "gethabitai.com"`, `customDomainState: NOT_STARTED`, `domainVerificationRequestTime: 1970-01-01T00:00:00Z` (época cero = la verificación NUNCA llegó a arrancar; no es que Google tarde 48 h, el job jamás se disparó). Mientras ese `customDomain` exista, cualquier edición de plantillas/URL de la sección de correo devuelve `EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED` (probado: PATCH de solo `callbackUri` también falla). **Lo que YA se probó y NO funciona** (no repetir): (a) togglear `useCustomDomain` por API no dispara la verificación ni cambia `domainVerificationRequestTime`; (b) "Aplicar dominio personalizado" + "Guardar" en consola no persiste en el backend (UI y config quedan desincronizadas — la consola acaba mostrando el remitente por defecto pero el `customDomain` huérfano sigue ahí); (c) borrar `customDomain` por API se ignora silenciosamente (responde 200 pero conserva el valor — guard de servidor). **Vía de salida real:** abrir caso en soporte de Firebase (https://firebase.google.com/support/troubleshooter/contact) pidiendo que limpien/reseteen el custom email domain huérfano del proyecto `habit-ai-184ad`. En cuanto `customDomain` desaparezca de la config, la URL se desbloquea y se escribe por API: PATCH `identitytoolkit.googleapis.com/admin/v2/projects/habit-ai-184ad/config?updateMask=notification.sendEmail.callbackUri` con el token del CLI de Firebase (`~/.config/configstore/firebase-tools.json`). **No bloquea el lanzamiento:** la recuperación de contraseña funciona hoy con el handler por defecto (`https://habit-ai-184ad.firebaseapp.com/__/auth/action`), solo que sin la marca/dominio propio. Los DNS de correo (SPF/DKIM en Porkbun) están correctos — dejarlos puestos, no tocar. Activar políticas TTL en Firestore (`gcloud firestore fields ttls update …`, comandos en `docs/retencion-datos.md`) + backfill `node functions/backfill_expires_at.js`. Widget iOS sin validar (App Group `group.com.andreistaicu.habitai` ya creado y asignado en el portal de Apple; falta build de Codemagic → TestFlight para probarlo), manejo offline, tests mínimos. App Check: activar Enforce tras subir a Play (+ añadir App Signing SHA). Presupuesto de Cloud Billing solo-email (~80-120€ al crecer) y freno selectivo que pause solo la IA al superar el presupuesto.

**Desplegado el 2026-06-11:** functions completas (incluye triggers FCM, gates premium, `routineChat`) + firestore.rules (campos premium protegidos) + hosting (`reset-password.html`). Functions ya corren en **Node.js 22** (runtime en `firebase.json`) — la migración pre-2026-10-30 está hecha.

**Dominio propio (2026-06-11): `gethabitai.com`** — comprado en Porkbun, conectado a Firebase Hosting (A `199.36.158.100` + TXT `hosting-site`, verificado y sirviendo con SSL) y configurado para los correos de Auth (SPF fusionado Porkbun+Firebase en un único TXT, DKIM `firebase1/2._domainkey`, TXT `firebase=` — todo propagado y comprobado en DNS público; la verificación del lado de Google estaba pendiente a 2026-06-11, ver pendientes). Hasta que verifique, los correos siguen saliendo del dominio firebaseapp.com. Dominio añadido a dominios autorizados de Auth. DNS en Porkbun — ojo: el campo Host añade `.gethabitai.com` solo (no escribir el dominio completo, se duplica). Solo puede existir UN registro SPF: si se añade otro servicio de correo, fusionar el include en el TXT existente. MX de Porkbun presentes para redirección de correo entrante (sin activar).

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

**Rebuild manual, sin hooks.** El grafo se reconstruye a mano (normalmente `/graphify --update` al empezar sesión). No hay auto-rebuild: los hooks `post-commit`/`post-checkout` se quitaron porque saltaban en cada commit y cada `git switch`, lo cual molestaba más que ayudaba en el flujo multi-equipo.

`graphify-out/` está en `.gitignore` (artefacto derivado, 16M) — cada equipo genera el suyo, nunca se sube al repo.

⚠️ **No correr `graphify hook install`**: vuelve a meter los hooks. Si querés auto-rebuild de nuevo, reinstalalos y acordate de añadir `export PATH="$HOME/.local/bin:$PATH"` al inicio (Android Studio no hereda el PATH de fish).
