# Sesión 2026-06-10 — Retención de datos (TTL de Firestore)

Resumen de todo lo decidido, implementado y activado en esta sesión, para
retomarlo sin perderse. Referencia técnica permanente → `docs/retencion-datos.md`.

---

## El problema

Sin política de retención, Firestore crece sin límite: cada chat con la IA,
revisión semanal, token push o solicitud de follow se quedaba para siempre.
A largo plazo eso no es rentable (y choca con la minimización de datos del RGPD).

## La solución elegida

**TTL nativo de Firestore**: cada documento efímero nace con un campo
`expiresAt` (timestamp), y una política TTL por collection group lo purga
automáticamente cuando caduca. Sin Cloud Functions de limpieza, sin cron, sin
mantenimiento.

### Plazos elegidos (política agresiva, a petición)

| Colección | Retención | Quién escribe `expiresAt` |
|---|---|---|
| `ai_conversations` | 30 días | cliente (`ai_repository.dart`) |
| `weekly_reviews` | 8 semanas (56 días) | Cloud Function |
| `butterfly_projections` | 3 meses (90 días) | Cloud Function |
| `pattern_insights` | 60 días | Cloud Function |
| `renegotiations` | 30 días | Cloud Function |
| `follow_requests` | 90 días pendiente / 7 días resuelta | cliente (`follow_repository.dart`) |
| `fcm_tokens` | 120 días sin abrir la app (se renueva en cada arranque) | cliente (`push_notification_service.dart`) |
| `rate_limits` | 7 días desde la última petición IA | Cloud Function |

### Exclusiones deliberadas (NO tienen TTL — no añadirlo)

- **`shield_grants`**: es la deduplicación de escudos por hito de racha
  (7/30/90 días). Si el doc expirara con la racha aún viva,
  `_grantShieldsForStreak` volvería a regalar escudos por el mismo hito →
  escudos infinitos. Máx. 3 docs por hábito, peso despreciable.
- **`achievements`**: inmutables y emocionalmente valiosos.
- **`logs` y `mood_entries`**: tienen valor analítico (rachas, heatmaps,
  correlación ánimo-hábitos). Su limpieza será por *rollup*, no por TTL
  (ver "Pendiente" abajo).

---

## Cambios en el código (commit pendiente al cierre de la sesión)

| Archivo | Cambio |
|---|---|
| `functions/index.js` | Helper `expiresInDays(days)` + campo `expiresAt` en los docs de weekly review (56d), butterfly (90d), renegotiation (30d), pattern insights (60d) y rate_limits (7d) |
| `lib/features/ai/data/ai_repository.dart` | `expiresAt` 30 días en `saveConversation` |
| `lib/features/social/data/follow_repository.dart` | `expiresAt` 90d al crear solicitud; 7d al aceptar/rechazar |
| `lib/services/push_notification_service.dart` | `expiresAt` 120d en `_saveToken` (se refresca en cada arranque) |
| `lib/features/auth/data/user_repository.dart` | Nuevo `touchLastActive()` — escribe `lastActiveAt` en `users/{uid}` |
| `lib/core/router/main_shell.dart` | Llama a `touchLastActive()` una vez por sesión (initState, fire-and-forget) |
| `firestore.rules` | El update de `follow_requests` permite ahora `['status', 'respondedAt', 'expiresAt']` (antes la regla habría rechazado el accept/decline) |
| `public/privacy.html` | Sección 7 ampliada con los plazos concretos de eliminación automática; fecha actualizada a 10/06/2026 |
| `functions/backfill_expires_at.js` | **Nuevo script**: pone `expiresAt` a docs antiguos (calculado desde su timestamp original), con `--dry-run` |
| `functions/enable_ttl.js` | **Nuevo script**: activa las políticas TTL vía API REST (sustituye a `gcloud`, que no está instalado en esta máquina) |
| `docs/retencion-datos.md` | **Nuevo doc**: política completa, comandos, caveats del TTL |
| `CLAUDE.md` | Política documentada en "Estado del proyecto" + `lastActiveAt` en el modelo de datos |
| `.gitignore` | `**/serviceAccount*.json` y `**/*service-account*.json` para no subir claves |

---

## Lo que se ejecutó en producción (proyecto `habit-ai-184ad`)

Todo verificado, en este orden:

1. **`firebase deploy --only firestore:rules,hosting,functions`** ✅
   - Reglas publicadas, 23 functions actualizadas, política de privacidad en
     https://habit-ai-184ad.web.app/privacy.html
   - De paso se confirmó que los triggers FCM ya estaban desplegados de antes
     (el pendiente de CLAUDE.md estaba obsoleto).
2. **Backfill** ✅ — `node functions/backfill_expires_at.js --keyfile=... `
   (dry-run primero): 92 docs antiguos marcados — 13 chats, 6 reviews,
   4 butterfly, 6 patterns, 52 renegociaciones, 4 follow_requests, 3 tokens,
   4 rate_limits.
3. **Activación de las 8 políticas TTL** ✅ — `node functions/enable_ttl.js --keyfile=...`
   - Verificado por API: las 8 en estado `CREATING` al cierre de la sesión
     (pasan a `ACTIVE` en minutos).
   - ⚠️ Requirió añadir el rol **"Cloud Datastore Owner"** al service account
     `firebase-adminsdk-fbsvc@habit-ai-184ad.iam.gserviceaccount.com` en IAM
     (su rol por defecto puede tocar datos pero no configuración TTL).
     **Se puede retirar ese rol** ahora que está hecho; si se reejecuta
     `enable_ttl.js` en el futuro, volver a añadirlo.

### Qué va a pasar ahora

- En 24-72 h Firestore hace la primera pasada y **purga lo ya caducado** del
  backfill (las 52 renegociaciones viejas, chats >30 días, solicitudes
  resueltas…). Es lo esperado.
- A partir de ahí, limpieza automática continua. Mantenimiento: cero.
- Los datos que escriba la **app cliente** (chats, solicitudes, tokens) solo
  llevan `expiresAt` desde la versión de la app con este código → hasta el
  próximo release, los docs nuevos del cliente nacen sin caducidad. No es
  grave: se puede reejecutar el backfill cuando se quiera (es idempotente,
  salta los que ya tienen el campo).

---

## Cómo verificar / operar

- **Ver estado de las políticas**: [console.cloud.google.com/firestore](https://console.cloud.google.com/firestore?project=habit-ai-184ad)
  → base de datos `(default)` → pestaña Time-to-live / "Período de habilitación de TTL".
- **Reejecutar backfill** (p. ej. tras un período sin app actualizada):
  `node functions/backfill_expires_at.js --keyfile=RUTA_AL_KEYFILE --dry-run` y luego sin `--dry-run`.
- **Keyfile**: clave del Admin SDK descargada de Firebase Console → Service
  accounts. La usada hoy está en Downloads (NO subirla al repo; el .gitignore
  ya la bloquea por patrón).

---

## Pendiente (tarjetas en Trello, tablero habitAI)

- ✅ ~~[Activar retención de datos (TTL) en producción](https://trello.com/c/AaOeJkBg)~~ — hecho hoy, movida a Done.
- ⏳ [Rollup mensual de logs y mood_entries](https://trello.com/c/k6jYntlf) — comprimir
  historial >12 meses en agregados mensuales antes de borrarlo. **No urge hasta
  ~junio 2027** (no existe historial tan viejo aún). Es código destructivo:
  diseñar mirando qué necesitan las pantallas, probar con seed y dry-run.
- ⏳ [Limpieza de cuentas inactivas](https://trello.com/c/ASkIUnhZ) — job que detecte
  `lastActiveAt` > 18-24 meses, email de aviso (requiere configurar un servicio
  de email, hoy no hay), y borrado a los 30 días. **No urge hasta ~2028.**
  El prerequisito (registrar `lastActiveAt`) quedó hecho hoy.
- Commit de todos los cambios de esta sesión (única cosa del repo sin cerrar).
- Opcional: retirar el rol "Cloud Datastore Owner" del service account en IAM.
- Opcional: en 24-72 h, comprobar que la primera purga del TTL ocurrió
  (los docs viejos de renegotiations/chats desaparecen solos).
