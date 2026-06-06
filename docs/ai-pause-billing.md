# Pausa selectiva de IA por presupuesto

> Reemplazo del antiguo kill switch (`killBillingOnBudgetExceeded`) que apagaba **todo** el proyecto al superar el presupuesto. La nueva arquitectura pausa **solo la IA** y deja el resto de la app operativa.

---

## El problema del kill switch original

El sistema anterior desvinculaba la cuenta de Cloud Billing al superar el umbral. Esto tumbaba Firestore, Auth y Functions simultáneamente — la app entera dejaba de funcionar. Imagen poco profesional y experiencia de usuario destructiva.

---

## Arquitectura: dos niveles

```
Nivel 1 (automático, implementado)
  Cloud Billing → Pub/Sub topic "billing-alerts"
    → pauseAiOnBudgetExceeded (Cloud Function)
      → system/ai_state.paused = true/false (Firestore)
        → assertAiAvailable() bloquea los callables
        → jobs hacen return temprano
        → cliente Flutter muestra banner + desactiva entradas

Nivel 2 (manual, backstop)
  Cuota dura de la Generative Language API en GCP
  → 429 aunque el Nivel 1 falle
```

---

## Nivel 1 — Pausa selectiva (implementado)

### Fuente de verdad: `system/ai_state`

Documento único en Firestore escrito **solo** por el admin SDK (la Cloud Function de billing) y leído por las funciones de IA y el cliente Flutter.

```
system/ai_state {
  paused:    bool       — true si el coste supera el presupuesto
  cost:      number     — último costAmount del presupuesto
  budget:    number     — último budgetAmount del presupuesto
  updatedAt: Timestamp  — cuándo se escribió
}
```

**Auto-recuperación:** Cloud Billing publica en el topic en cada cambio de gasto. Cuando `cost <= budget`, la función escribe `paused: false` sola, sin intervención manual.

---

### Backend — `functions/index.js`

#### Helper `assertAiAvailable()`

```js
async function assertAiAvailable() {
  const doc = await admin.firestore().doc("system/ai_state").get();
  if (doc.exists && doc.data().paused === true) {
    throw new HttpsError(
      "unavailable",
      "El asistente de IA está en pausa temporal. El resto de la app funciona con normalidad."
    );
  }
}
```

Se llama antes de consumir Gemini en cada callable, justo después de verificar auth y antes del rate limit.

#### Guards en los 5 callables

| Callable | Cuándo se inserta el guard |
|---|---|
| `generateHabitPlan` | Antes de `checkRateLimit` |
| `generateWeeklyReview` | Antes de `checkRateLimit` |
| `generateButterflyProjection` | Antes de `checkRateLimit` |
| `generateRenegotiation` | Tras verificar auth, antes de su rate limit propio |
| `generatePatternInsights` | Antes de `checkRateLimit` |

#### Short-circuit en los 4 jobs scheduled

Los jobs iteran sobre muchos usuarios, así que el flag se lee **una sola vez al inicio** del handler y se hace `return` temprano si está pausado. Evita N lecturas extra por usuario.

```js
const aiState = await db.doc("system/ai_state").get();
if (aiState.exists && aiState.data().paused === true) {
  console.log("[billing] IA pausada — saltando weeklyReviewJob");
  return;
}
```

Jobs afectados: `weeklyReviewJob`, `butterflyProjectionJob`, `renegotiationJob`, `patternInsightsJob`.

#### Función `pauseAiOnBudgetExceeded`

```js
exports.pauseAiOnBudgetExceeded = onMessagePublished(
  { topic: "billing-alerts", region: "europe-west1", maxInstances: 1 },
  async (event) => {
    const { costAmount: cost = 0, budgetAmount: budget = 0 } = event.data.message.json;
    const paused = cost > budget;

    await admin.firestore().doc("system/ai_state").set(
      { paused, cost, budget, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );

    console.log(`[billing] IA ${paused ? "pausada" : "reanudada"} — coste: ${cost}, presupuesto: ${budget}`);
  }
);
```

---

### Reglas de Firestore — `firestore.rules`

```
match /system/{doc} {
  allow read: if request.auth != null;  // cliente lee el flag
  allow write: if false;                // solo admin SDK (Cloud Function)
}
```

La colección `system` tiene `deny-by-default` heredado — la escritura desde el cliente ya estaba bloqueada. El bloque explícito lo documenta.

---

### Cliente Flutter

#### `AiAvailabilityService`

Singleton en `lib/core/services/ai_availability_service.dart`. Espeja el patrón de `ConnectivityService`.

```dart
class AiAvailabilityService {
  static final instance = AiAvailabilityService._();
  final ValueNotifier<bool> isPaused = ValueNotifier(false);

  Future<void> init() async {
    FirebaseFirestore.instance
      .doc('system/ai_state')
      .snapshots()
      .listen(
        (snap) => isPaused.value = snap.exists && snap.data()?['paused'] == true,
        onError: (_) => isPaused.value = false,  // fail-open
      );
  }
}
```

**Fail-open:** si el documento no existe o hay error de red, `isPaused` queda en `false` y la app funciona con normalidad.

Inicializado en `main.dart` junto a `ConnectivityService` y `UpdateService`:

```dart
await AiAvailabilityService.instance.init();
```

#### AIScreen (`lib/features/ai/presentation/ai_screen.dart`)

- Escucha `AiAvailabilityService.instance.isPaused` via listener → `setState`
- **Banner amber** visible encima del input bar cuando pausado
- **Campo de texto deshabilitado** (`enabled: !isLoading && !isPaused`)
- **Botón de envío deshabilitado** (`onTap: isLoading || isPaused ? null : onSend`)
- Check temprano en `_sendMessage` antes de llamar a la Cloud Function

#### DashboardScreen

Botones deshabilitados cuando `_isAiPaused`:

| Botón | Condición original | Condición nueva |
|---|---|---|
| Generar revisión semanal | `_generatingReview ? null : fn` | `_generatingReview \|\| _isAiPaused ? null : fn` |
| Generar proyección mariposa | `_generatingButterfly ? null : fn` | `_generatingButterfly \|\| _isAiPaused ? null : fn` |
| Generar patrones | `_generatingPatterns ? null : fn` | `_generatingPatterns \|\| _isAiPaused ? null : fn` |
| Renegociación (onTap) | directo | check `_isAiPaused` + snackbar antes de llamar |

#### PatternInsightsScreen

Check al inicio de `_regenerate()`, igual al de conectividad:

```dart
if (AiAvailabilityService.instance.isPaused.value) {
  AppSnackBar.showInfo(context, S.of(context).aiPausedMessage);
  return;
}
```

#### Fallback en `AIRepository._mapError`

```dart
case 'unavailable':
  return 'El asistente de IA está en pausa temporal. El resto de la app funciona con normalidad.';
```

Cubre la ventana entre que el flag cambia en Firestore y el cliente lo refleja en su `ValueNotifier`.

---

## Nivel 2 — Red dura (pasos manuales en GCP)

Actúa aunque el Nivel 1 falle. **No está automatizado** — se configura una sola vez.

### 1. Conectar el presupuesto al topic Pub/Sub

En Cloud Billing → Presupuestos y alertas → editar el presupuesto existente:
- Activar **"Connect a Pub/Sub topic"**
- Seleccionar o crear el topic `billing-alerts` en el mismo proyecto
- **No** activar ninguna acción de desvinculación de cuenta (solo email + Pub/Sub)

El topic `billing-alerts` era el mismo que usaba el kill switch. Si se borró al eliminar ese sistema, recrearlo en Pub/Sub antes de conectarlo.

### 2. Umbral del presupuesto

Regla orientativa: umbral ≈ 2-3× el gasto mensual normal con tráfico real.  
Para 1000 usuarios → **~80-120€**.

El presupuesto actúa solo como notificador; el Nivel 1 es el freno real.

### 3. Cuota dura de la API (backstop)

GCP → APIs y Servicios → *Generative Language API* → Cuotas:
- Fijar un techo de requests/min y/o requests/día
- Al superarlo Gemini devuelve `429` — el cliente lo verá como error genérico

### 4. Pausa manual (sin redesplegar)

Editar `system/ai_state.paused = true` directamente en la consola de Firestore corta la IA al instante. Volver a `false` la reactiva. Útil para mantenimiento planificado.

---

## Flujo completo cuando se supera el presupuesto

```
1. Cloud Billing detecta cost > budget
2. Publica mensaje en topic "billing-alerts"
3. pauseAiOnBudgetExceeded escribe system/ai_state.paused = true
4. Los clientes Flutter suscritos reciben el cambio en tiempo real
   → AIScreen muestra banner, desactiva input
   → Botones del Dashboard se atenúan
5. Si el usuario intenta enviar un mensaje igualmente:
   → _sendMessage hace return antes de la llamada
6. Si la llamada llega al backend (ventana de propagación):
   → assertAiAvailable() lanza HttpsError("unavailable")
   → _mapError devuelve mensaje amable
7. Los jobs scheduled de esa noche leen el flag y hacen return temprano
   → Cero gasto en Gemini hasta que el flag vuelva a false
8. Al día siguiente, cuando el nuevo ciclo de facturación reduce cost:
   → Nuevo mensaje Pub/Sub con cost <= budget
   → pauseAiOnBudgetExceeded escribe paused = false
   → Todo vuelve a la normalidad automáticamente
```

---

## Deploy

```bash
firebase deploy --only functions,firestore:rules
```

Después del deploy, conectar el presupuesto al topic (Nivel 2, paso 1) para que la pausa real se dispare.
