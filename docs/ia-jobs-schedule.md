# Jobs de IA programados (Cloud Functions)

Jobs de fondo en `functions/index.js`, todos con `onSchedule`, región `europe-west1`, zona horaria `Europe/Madrid`, modelo `gemini-2.5-flash`.

## Resumen

| Job | Cron | Cuándo |
|-----|------|--------|
| `renegotiationJob` | `0 7 * * *` | diario, 07:00 |
| `weeklyReviewJob` | `0 8 * * 1` | lunes, 08:00 |
| `patternInsightsJob` | `0 10 * * 2` | martes, 10:00 |
| `butterflyProjectionJob` | `0 9 1 * *` | día 1 del mes, 09:00 |

---

## Suggested adjustments — `renegotiationJob`

**Cron: `0 7 * * *` → cada día a las 07:00 Europe/Madrid.**

La revisión es diaria, pero no genera una sugerencia para cada hábito cada día. Filtros antes de generar:

1. **Hábito activo** (`isActive == true`) y usuario con `onboardingCompleted == true`.
2. **Tiene `targetDays`** definidos.
3. **≥3 días objetivo** en los últimos 14 días.
4. **Los últimos 3 días objetivo fallados seguidos** (ni `completed` ni `shielded`). ← gatillo real.
5. **No hay ya una pendiente** (sin `appliedAt` ni `dismissedAt`); si existe, no regenera.

Resultado: revisión diaria, pero solo dispara cuando fallas 3 sesiones programadas seguidas, y como máximo 1 sugerencia pendiente por hábito.

### Trigger manual

`generateRenegotiation` (HTTPS callable) desde el botón en `HabitDetailScreen`. Rate limit propio: **5 renegociaciones/hora por usuario**.

Las sugerencias se guardan en `users/{uid}/renegotiations/{habitId}`.
