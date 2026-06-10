# Política de retención de datos (TTL de Firestore)

Sin retención, la base de datos crece sin límite (chats de IA, revisiones,
tokens muertos…). La estrategia: campo `expiresAt` en cada documento efímero +
políticas TTL nativas de Firestore que los purgan automáticamente.

## Plazos por colección

| Collection group | Retención | Desde | Quién escribe `expiresAt` |
|---|---|---|---|
| `ai_conversations` | 30 días | creación | cliente (`ai_repository.dart`) |
| `weekly_reviews` | 56 días (8 semanas) | generación | Cloud Function |
| `butterfly_projections` | 90 días (3 meses) | generación | Cloud Function |
| `pattern_insights` | 60 días | generación | Cloud Function |
| `renegotiations` | 30 días | generación | Cloud Function |
| `follow_requests` | 90 días pendiente / 7 días resuelta | creación / respuesta | cliente (`follow_repository.dart`) |
| `fcm_tokens` | 120 días sin abrir la app | último arranque (se refresca en cada `_saveToken`) | cliente (`push_notification_service.dart`) |
| `rate_limits` | 7 días desde la última petición IA | última petición | Cloud Function |

**Excluidas a propósito:**

- `shield_grants` — son la deduplicación de escudos por hito de racha. Si
  expiraran con la racha aún viva, se volverían a conceder escudos por el mismo
  hito (escudos infinitos). Máx. 3 docs por hábito: peso despreciable.
- `achievements` — inmutables y emocionalmente valiosos.
- `logs` y `mood_entries` — tienen valor analítico (rachas, heatmaps,
  correlaciones). Pendiente: job de *rollup* mensual que agregue los de >12
  meses antes de borrarlos (ver ROADMAP).

## Activar las políticas TTL (una vez por proyecto)

TTL se configura por collection group sobre el campo `expiresAt`:

```bash
gcloud firestore fields ttls update expiresAt --collection-group=ai_conversations --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=weekly_reviews --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=butterfly_projections --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=pattern_insights --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=renegotiations --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=follow_requests --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=fcm_tokens --enable-ttl --async
gcloud firestore fields ttls update expiresAt --collection-group=rate_limits --enable-ttl --async
```

Verificar estado: `gcloud firestore fields ttls list`

También se puede hacer desde la consola: Firestore → tabla de datos → TTL.

## Backfill de documentos antiguos

Los documentos escritos antes de esta política no tienen `expiresAt` y el TTL
los ignora. Backfill una única vez:

```bash
node functions/backfill_expires_at.js --keyfile=/ruta/a/key.json --dry-run   # ver qué haría
node functions/backfill_expires_at.js --keyfile=/ruta/a/key.json             # ejecutar
```

## Cosas a saber del TTL de Firestore

- **No es puntual**: borra típicamente entre 24 y 72 h después de `expiresAt`.
  No usarlo para nada que necesite precisión temporal.
- **Las eliminaciones se facturan** como deletes normales (volumen aquí: trivial).
- **Ignora las reglas de seguridad** — funciona aunque la colección tenga
  `delete: if false`.
- **Dispara triggers `onDelete`** de Cloud Functions. Hoy no tenemos ninguno
  (solo `onDocumentCreated`/`onDocumentUpdated`), pero si se añade uno sobre
  estas colecciones, recordar que el TTL lo invocará.
- El campo TTL **no necesita índice**: si Firestore crea índice single-field
  para `expiresAt`, se puede añadir una exención para ahorrar escrituras de
  índice (Firestore → Índices → Single-field → Add exemption).
