# Costes de modelos Gemini — HabitAI

> Precios oficiales del tier de pago (plan Blaze). Última verificación: **2026-05-31**.
> Fuente: https://ai.google.dev/gemini-api/docs/pricing
> Para esta app todo es **texto** y los prompts están muy por debajo de 200k tokens → aplican siempre los tramos más baratos.

## Tabla de precios (USD por 1 millón de tokens)

| Modelo | Input (texto) | Output | Uso recomendado aquí |
|--------|--------------|--------|----------------------|
| ⚡ `gemini-2.5-flash-lite` | $0.10 | $0.40 | El más barato. Jobs de resumen muy simples |
| ⚡ `gemini-2.5-flash` | $0.30 | $2.50 | Revisión semanal, mariposa, patrones, renegociación |
| 🔵 `gemini-2.5-pro` | $1.25 | $10.00 | Chat interactivo (calidad alta) |

- Los 3 tienen **tier gratuito** con cuota limitada (útil en desarrollo).
- Solo **Pro** tiene tramo por longitud de contexto: input/output se **duplican** si el prompt supera 200k tokens ($2.50 / $15.00). No nos afecta.
- ⚠️ Nombre correcto: `gemini-2.5-flash` (generación primero). `gemini-flash-2-5` NO existe → da 404.

## Comparativa relativa (por output, que es lo que más pesa)

| | vs Flash | vs Pro |
|---|---|---|
| **Flash-Lite** ($0.40) | 6.25× más barato | 25× más barato |
| **Flash** ($2.50) | — | 4× más barato |
| **Pro** ($10.00) | 4× más caro | — |

## Ejemplo práctico (revisión semanal: ~3k input + ~1.5k output)

| Modelo | Coste/revisión | 1000 usuarios/semana |
|--------|---------------|----------------------|
| Pro | ~$0.019 | ~$19 |
| Flash (actual) | ~$0.0046 | ~$4.6 |
| Flash-Lite | ~$0.0009 | ~$0.9 |

## Reparto actual en `functions/index.js`

| Función | Modelo |
|---------|--------|
| `generateHabitPlan` (chat) | 🔵 Pro |
| `generateWeeklyReview` / `weeklyReviewJob` | ⚡ Flash |
| `generateButterflyProjection` / `butterflyProjectionJob` | ⚡ Flash |
| `generateRenegotiation` / `renegotiationJob` | ⚡ Flash |
| `generatePatternInsights` / `patternInsightsJob` | ⚡ Flash |

Definido por constantes al inicio del archivo:
```js
const MODEL_PRO = "gemini-2.5-pro";
const MODEL_FLASH = "gemini-2.5-flash";
```

## Criterio

- **Pro** → solo chat interactivo (el usuario nota la calidad en tiempo real).
- **Flash** → tareas automáticas de fondo que resumen datos a JSON (~10-20× más barato).
- **Flash-Lite** → candidato para jobs muy mecánicos (ej. renegociación) si la calidad aguanta. Otro ~80% de ahorro sobre Flash.

## Predicción de gasto mensual — 1000 usuarios

> Estimación con suposiciones explícitas. Convertido USD→EUR (×0.92).
> El coste lo domina la **actividad real** (no los registrados) y dentro de eso el **chat (Pro)**.

### Suposiciones

| Variable | Conservador | Realista | Alto |
|----------|-------------|----------|------|
| % usuarios activos | 25% (250) | 40% (400) | 60% (600) |
| Mensajes chat/usuario activo/mes | 4 | 8 | 20 |

### Coste mensual estimado (€)

| Concepto | Modelo | Conservador | Realista | Alto |
|----------|--------|-------------|----------|------|
| Chat | Pro | ~€12 | ~€39 | ~€145 |
| Revisión semanal (×4/mes) | Flash | ~€4 | ~€7 | ~€10 |
| Mariposa (mensual) | Flash | ~€1.5 | ~€2.4 | ~€3.6 |
| Patrones (mensual) | Flash | ~€1.5 | ~€2.4 | ~€3.6 |
| Renegociación | Flash | ~€0.4 | ~€0.6 | ~€1 |
| Firestore + Functions + Storage | infra | ~€3 | ~€8 | ~€18 |
| **TOTAL/mes** | | **~€22** | **~€59** | **~€181** |

### Conclusiones

- **El chat (Pro) es el 50-80% de la factura.** Los jobs Flash + infra suman solo ~€10-25/mes incluso en el caso alto.
- **Por usuario activo/mes:** ~€0.05 (conservador) a ~€0.30 (alto).

### Control de costes — dos niveles

#### Nivel 1 — Pausa selectiva de IA (implementado)

La función `pauseAiOnBudgetExceeded` recibe mensajes Pub/Sub del presupuesto de Cloud Billing y escribe el flag `system/ai_state.paused` en Firestore. Cuando `paused = true`:
- Los 5 callables de IA lanzan `HttpsError("unavailable")` antes de llamar a Gemini.
- Los 4 jobs `onSchedule` hacen `return` temprano con un log.
- El cliente Flutter muestra un banner y desactiva los campos de entrada.
- Auto-recuperación: cuando `cost <= budget`, el flag vuelve a `false` automáticamente.

**Pasos manuales para activar el Nivel 1** (una sola vez en GCP):
1. En Cloud Billing → Presupuestos y alertas → editar el presupuesto existente → activar **"Connect a Pub/Sub topic"** → seleccionar `billing-alerts`. Si el topic no existe, crearlo primero en Pub/Sub (mismo proyecto).
2. El presupuesto debe tener **solo alertas por email**, sin acciones de corte automático (ningún check en "Link Billing account actions"). El Nivel 1 se encarga del corte selectivo.
3. Regla orientativa: umbral ≈ 2-3× el gasto mensual normal. Para 1000 usuarios → **~80-120€**.
4. **Pausa manual opcional**: editar `system/ai_state.paused = true` a mano en la consola de Firestore corta la IA de inmediato; `false` la reactiva sin redesplegar.

#### Nivel 2 — Red dura (backstop manual, no automatizado)

Protección de último recurso que actúa incluso si el Nivel 1 falla:
1. **Cuota dura de la API**: GCP → APIs y Servicios → *Generative Language API* → Cuotas → fijar un techo de requests/min y/o requests/día. Al superarlo Gemini devuelve `429` aunque el Nivel 1 no haya actuado.
2. **Presupuesto solo-email**: asegurarse de que el presupuesto de Cloud Billing **no** tenga configurada ninguna acción de desvinculación de cuenta (solo notificación). El Nivel 1 es el freno; el presupuesto solo avisa.

### Palancas para bajar el coste del chat

- Flash en el chat → ~4× más barato (los ~€39 realistas → ~€10), algo menos de calidad.
- Bajar el rate limit (ahora 10/h).
- Recortar el historial enviado en cada mensaje (menos tokens de input).

## Cómo verificar que un modelo existe (sin exponer la clave)

```bash
KEY=$(firebase functions:secrets:access GEMINI_API_KEY)
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=${KEY}" \
  | grep -o '"name": "models/gemini-2.5[^"]*"'
```
