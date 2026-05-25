const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

admin.initializeApp();

// La API key se guarda como secret en Firebase, nunca en el codigo
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// System prompt para la generacion de habitos
const SYSTEM_PROMPT = `
Eres un coach experto en productividad y bienestar personal. Tu tarea es generar
un plan de hábitos personalizado basado en las metas del usuario.

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con un objeto JSON válido. Sin texto adicional, sin markdown,
   sin explicaciones fuera del JSON.
2. Genera entre 3 y 7 hábitos máximo.
3. Cada hábito debe ser específico, medible y realista para una persona normal.
4. Adapta los horarios y frecuencias al estilo de vida descrito por el usuario.
5. Categoriza cada hábito: "salud", "productividad", "bienestar", "social",
   "aprendizaje", "finanzas".

FORMATO DE RESPUESTA (JSON):
{
  "planTitle": "Título descriptivo del plan (ej: 'Nuevo en el gimnasio', 'Rutina de estudio')",
  "planEmoji": "Un solo emoji que represente el plan (ej: 🏋️, 📚, 🧘, 🥗)",
  "planDescription": "Breve descripción de 1-2 frases",
  "habits": [
    {
      "title": "Nombre corto del hábito",
      "description": "Descripción de qué hacer y por qué",
      "category": "salud|productividad|bienestar|social|aprendizaje|finanzas",
      "frequency": "daily|weekly|custom",
      "targetDays": [1,2,3,4,5,6,7],
      "suggestedTime": "HH:mm",
      "estimatedMinutes": 15,
      "difficultyLevel": "easy|medium|hard"
    }
  ],
  "coachMessage": "Un mensaje motivacional personalizado para el usuario"
}
`;

// System prompt para la revision semanal — formato distinto al plan
const WEEKLY_REVIEW_PROMPT = `
Eres un coach personal que analiza el progreso semanal del usuario y genera
una revisión honesta, motivadora y accionable.

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con un objeto JSON válido. Sin texto fuera del JSON.
2. Sé específico: menciona hábitos concretos por su título.
3. Sé empático pero honesto. Si la semana fue mala, no edulcores, propón ajustes.
4. Las recomendaciones deben ser concretas: qué hábito ajustar y cómo.
5. Máximo 3 wins, 3 struggles y 3 recommendations.
6. El "focus" es UN solo consejo principal para la semana siguiente.

FORMATO DE RESPUESTA (JSON):
{
  "wins": [
    "Logro concreto de la semana (ej: 'Racha de 5 días en meditación')"
  ],
  "struggles": [
    "Dificultad concreta (ej: 'Leer 30 min solo 1 de 7 días')"
  ],
  "recommendations": [
    {
      "habitId": "id del hábito al que se refiere (usar el del contexto)",
      "habitTitle": "título del hábito",
      "action": "ajuste concreto propuesto (ej: 'Baja a 15 minutos y muévelo a las 22:00')",
      "reason": "por qué este ajuste ayudará"
    }
  ],
  "focus": "Consejo principal para la próxima semana en 1-2 frases"
}
`;

// Comprueba que el usuario no ha superado el limite de peticiones (10/hora)
async function checkRateLimit(uid) {
  const ref = admin.firestore().collection("rate_limits").doc(uid);
  const doc = await ref.get();
  const now = Date.now();
  const oneHourAgo = now - 60 * 60 * 1000;

  if (doc.exists) {
    const requests = (doc.data().requests || []).filter(
      (ts) => ts > oneHourAgo
    );

    if (requests.length >= 15) {
      return false;
    }

    requests.push(now);
    await ref.update({ requests });
  } else {
    await ref.set({ requests: [now] });
  }

  return true;
}



// Cloud Function callable desde Flutter
exports.generateHabitPlan = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async (request) => {
    // 1. Verificar autenticacion
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    const { message, history } = request.data;

    if (!message || typeof message !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "El mensaje no puede estar vacío."
      );
    }

     const allowed = await checkRateLimit(uid);
     if (!allowed) {
       throw new HttpsError(
         "resource-exhausted",
         "Has hecho demasiadas peticiones. Espera unos minutos."
       );
     }

    // 3. Llamar a Gemini
    try {
      console.log("Llamando a Gemini con mensaje:", message.substring(0, 50));
      const apiKey = geminiApiKey.value();
      console.log("API key presente:", apiKey ? "SI" : "NO");
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-pro",
        systemInstruction: SYSTEM_PROMPT,
      });

      // Reconstruir historial si existe
      const chatHistory = (history || []).map((msg) => ({
        role: msg.role,
        parts: [{ text: msg.text }],
      }));

      const chat = model.startChat({ history: chatHistory });
      const result = await chat.sendMessage(message);
      const text = result.response.text();

      // 4. Intentar parsear la respuesta como JSON
      let parsed = null;
      try {
        const clean = extractJson(text);
        parsed = JSON.parse(clean);
      } catch {
        // Si no es JSON valido, lo devolvemos como texto
      }

      return {
        text: text,
        plan: parsed,
      };
    } catch (error) {
      console.error("Error llamando a Gemini:", error);
      throw new HttpsError(
        "internal",
        "Error del asistente. Inténtalo más tarde."
      );
    }
  }
);

// ==================== REVISION SEMANAL ====================

// Devuelve el ID ISO de la semana de una fecha: "2026-W15"
function getIsoWeekId(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  // jueves de la semana ISO determina el año
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNum = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

// Devuelve el lunes y el domingo (inclusive) de la semana anterior a 'now'
function getPreviousWeekRange(now) {
  const day = now.getDay() || 7; // 1=lunes, 7=domingo
  // domingo de la semana pasada
  const endOfLastWeek = new Date(now);
  endOfLastWeek.setDate(now.getDate() - day);
  endOfLastWeek.setHours(23, 59, 59, 999);
  // lunes de la semana pasada
  const startOfLastWeek = new Date(endOfLastWeek);
  startOfLastWeek.setDate(endOfLastWeek.getDate() - 6);
  startOfLastWeek.setHours(0, 0, 0, 0);
  return { start: startOfLastWeek, end: endOfLastWeek };
}

// Devuelve el lunes (00:00) de la semana en curso hasta 'now' (inclusive).
// Se usa desde el boton manual para analizar los dias que llevan hechos.
function getCurrentWeekRange(now) {
  const day = now.getDay() || 7; // 1=lunes, 7=domingo
  const startOfThisWeek = new Date(now);
  startOfThisWeek.setDate(now.getDate() - (day - 1));
  startOfThisWeek.setHours(0, 0, 0, 0);
  return { start: startOfThisWeek, end: new Date(now) };
}

// Lee los datos de la semana y construye el contexto que se le pasa a Gemini
async function buildWeeklyContext(uid, start, end) {
  const db = admin.firestore();
  const habitsSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("habits")
    .where("isActive", "==", true)
    .get();

  const habits = habitsSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  // Para cada hábito, contar logs completados dentro del rango
  const habitStats = [];
  let totalLogs = 0;
  for (const habit of habits) {
    const logsSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("habits")
      .doc(habit.id)
      .collection("logs")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(end))
      .get();

    const completed = logsSnapshot.docs.filter(
      (d) => d.data().completed === true
    ).length;

    // Días esperados de ese hábito que caen dentro del rango (lun=1..dom=7)
    const targetDays = habit.targetDays || [];
    let expected = 0;
    const cursor = new Date(start);
    while (cursor <= end) {
      const weekday = cursor.getDay() === 0 ? 7 : cursor.getDay();
      if (targetDays.includes(weekday)) expected += 1;
      cursor.setDate(cursor.getDate() + 1);
    }

    habitStats.push({
      id: habit.id,
      title: habit.title,
      category: habit.category,
      completed,
      expected,
      currentStreak: habit.currentStreak || 0,
      bestStreak: habit.bestStreak || 0,
    });
    totalLogs += completed;
  }

  return { habits: habitStats, totalLogs };
}

// Lógica compartida: genera la revisión de una semana para un usuario.
// Si currentWeek=true analiza la semana en curso (lun hasta 'now').
// Si no, analiza la semana anterior completa (uso del job automatico).
async function runWeeklyReview(uid, now, { currentWeek = false } = {}) {
  const { start, end } = currentWeek
    ? getCurrentWeekRange(now)
    : getPreviousWeekRange(now);
  const weekId = getIsoWeekId(start);

  const context = await buildWeeklyContext(uid, start, end);

  // No generar revisión si no hay datos suficientes
  if (context.totalLogs < 3) {
    return { skipped: true, reason: "insufficient_logs", weekId };
  }

  const userMessage = `Analiza mi semana y dame una revisión.

Datos de la semana (${start.toISOString().slice(0, 10)} a ${end.toISOString().slice(0, 10)}):
${context.habits
  .map(
    (h) =>
      `- "${h.title}" (${h.category}) [id: ${h.id}] → ${h.completed}/${h.expected} días, racha actual: ${h.currentStreak}, mejor: ${h.bestStreak}`
  )
  .join("\n")}

Total de check-ins de la semana: ${context.totalLogs}`;

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-pro",
    systemInstruction: WEEKLY_REVIEW_PROMPT,
  });

  const result = await model.generateContent(userMessage);
  const text = result.response.text();

  let parsed;
  try {
    parsed = JSON.parse(extractJson(text));
  } catch (e) {
    console.error("No se pudo parsear la revisión:", text);
    throw new HttpsError("internal", "La IA devolvió un formato no válido.");
  }

  // Construir stats agregadas para el card del dashboard
  const stats = {
    totalLogs: context.totalLogs,
    totalHabits: context.habits.length,
    bestHabit:
      context.habits
        .filter((h) => h.expected > 0)
        .sort((a, b) => b.completed / b.expected - a.completed / a.expected)[0]
        ?.title || null,
    habitsAtRisk: context.habits
      .filter((h) => h.expected > 0 && h.completed / h.expected < 0.3)
      .map((h) => h.title),
  };

  const reviewDoc = {
    weekId,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    weekStart: admin.firestore.Timestamp.fromDate(start),
    weekEnd: admin.firestore.Timestamp.fromDate(end),
    stats,
    wins: parsed.wins || [],
    struggles: parsed.struggles || [],
    recommendations: parsed.recommendations || [],
    focus: parsed.focus || "",
  };

  await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("weekly_reviews")
    .doc(weekId)
    .set(reviewDoc);

  return { skipped: false, weekId };
}

// Trigger manual desde la app (sirve para pruebas y botón "generar ahora")
exports.generateWeeklyReview = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
     const allowed = await checkRateLimit(uid);
     if (!allowed) {
       throw new HttpsError(
         "resource-exhausted",
         "Has hecho demasiadas peticiones. Espera unos minutos."
       );
     }

    try {
      // El boton manual analiza la semana en curso (mas intuitivo para el usuario).
      // El job scheduled sigue usando la semana anterior.
      return await runWeeklyReview(uid, new Date(), { currentWeek: true });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error en generateWeeklyReview:", error);
      throw new HttpsError(
        "internal",
        "No se pudo generar la revisión. Inténtalo más tarde."
      );
    }
  }
);

// Job programado: lunes a las 08:00 hora Europa/Madrid
// Procesa todos los usuarios con onboardingCompleted=true
exports.weeklyReviewJob = onSchedule(
  {
    schedule: "0 8 * * 1",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();

    // Solo usuarios que han terminado el onboarding
    const usersSnapshot = await db
      .collection("users")
      .where("onboardingCompleted", "==", true)
      .get();

    console.log(`weeklyReviewJob: procesando ${usersSnapshot.size} usuarios`);

    let generated = 0;
    let skipped = 0;
    let errors = 0;

    for (const userDoc of usersSnapshot.docs) {
      try {
        const result = await runWeeklyReview(userDoc.id, now);
        if (result.skipped) {
          skipped += 1;
        } else {
          generated += 1;
        }
      } catch (e) {
        errors += 1;
        console.error(`Error procesando ${userDoc.id}:`, e.message);
      }
    }

    console.log(
      `weeklyReviewJob terminado: ${generated} generadas, ${skipped} omitidas, ${errors} errores`
    );
  }
);

// ==================== EFECTO MARIPOSA ====================

// Prompt para la proyección de vida a 3 años — dos escenarios
const BUTTERFLY_PROMPT = `
Eres un narrador cinematográfico y coach de vida. Tu tarea es generar una pequeña
historia inmersiva que proyecte la vida del usuario en 3 años bajo dos escenarios:
si mantiene sus hábitos actuales, o si los abandona.

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con un objeto JSON válido. Sin texto fuera del JSON.
2. Usa segunda persona ("tú"), presente narrativo mezclado con futuro.
3. Sé evocador y concreto: menciona hábitos reales del contexto, logros tangibles.
4. No uses cifras frías ni porcentajes — usa imágenes y emociones.
5. Cada historia: 4-6 frases, fluidas, con impacto emocional.
6. El escenario de abandono no debe ser catastrófico — sutil, melancólico.
7. keyMoments: 3 hitos concretos que marcarán la diferencia (uno por hábito destacado).
8. closingMessage: 1-2 frases que inviten a actuar, no a rendirse.

FORMATO DE RESPUESTA (JSON):
{
  "titleKeep": "Título evocador del camino de continuidad (ej: 'El día que todo encajó')",
  "storyKeep": "Historia de 4-6 frases si el usuario mantiene sus hábitos...",
  "titleAbandon": "Título melancólico del camino de abandono (ej: 'Lo que pudo ser')",
  "storyAbandon": "Historia de 4-6 frases si el usuario abandona sus hábitos...",
  "keyMoments": [
    {
      "habitTitle": "título del hábito del contexto",
      "impact": "impacto concreto en 3 años en 1-2 frases, evocador"
    }
  ],
  "closingMessage": "Mensaje motivacional de cierre en 1-2 frases"
}
`;

// Devuelve el ID de mes: "2026-04"
function getMonthId(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

// Rango del mes anterior completo
function getPreviousMonthRange(now) {
  const firstOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfLastMonth = new Date(firstOfThisMonth - 1);
  endOfLastMonth.setHours(23, 59, 59, 999);
  const startOfLastMonth = new Date(endOfLastMonth.getFullYear(), endOfLastMonth.getMonth(), 1);
  startOfLastMonth.setHours(0, 0, 0, 0);
  return { start: startOfLastMonth, end: endOfLastMonth };
}

// Rango del mes en curso desde el 1 hasta 'now'
function getCurrentMonthRange(now) {
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  start.setHours(0, 0, 0, 0);
  return { start, end: new Date(now) };
}

// Construye el contexto mensual para Gemini
async function buildMonthlyContext(uid, start, end) {
  const db = admin.firestore();
  const habitsSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("habits")
    .where("isActive", "==", true)
    .get();

  const habits = habitsSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  const habitStats = [];
  let totalLogs = 0;
  let totalExpected = 0;
  const categoryCounts = {};
  let longestStreak = 0;

  for (const habit of habits) {
    const logsSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("habits")
      .doc(habit.id)
      .collection("logs")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(end))
      .get();

    const completed = logsSnapshot.docs.filter(
      (d) => d.data().completed === true
    ).length;

    const targetDays = habit.targetDays || [];
    let expected = 0;
    const cursor = new Date(start);
    while (cursor <= end) {
      const weekday = cursor.getDay() === 0 ? 7 : cursor.getDay();
      if (targetDays.includes(weekday)) expected += 1;
      cursor.setDate(cursor.getDate() + 1);
    }

    // Agrupar por categoría
    const cat = habit.category || "otro";
    categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;

    // Racha más larga del mes
    if ((habit.currentStreak || 0) > longestStreak) {
      longestStreak = habit.currentStreak || 0;
    }

    habitStats.push({
      id: habit.id,
      title: habit.title,
      category: cat,
      completed,
      expected,
      currentStreak: habit.currentStreak || 0,
      bestStreak: habit.bestStreak || 0,
    });

    totalLogs += completed;
    totalExpected += expected;
  }

  // Top 3 categorías por número de hábitos
  const topCategories = Object.entries(categoryCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([cat]) => cat);

  const completionRate = totalExpected > 0 ? totalLogs / totalExpected : 0;

  return {
    habits: habitStats,
    totalLogs,
    activeHabits: habits.length,
    completionRate,
    topCategories,
    longestStreak,
  };
}

// Lógica compartida: genera la proyección de efecto mariposa para un usuario
async function runButterflyProjection(uid, now, { currentMonth = false } = {}) {
  const { start, end } = currentMonth
    ? getCurrentMonthRange(now)
    : getPreviousMonthRange(now);
  const monthId = getMonthId(start);

  const context = await buildMonthlyContext(uid, start, end);

  // Mínimo 10 logs para que la historia tenga sentido
  if (context.totalLogs < 10) {
    return { skipped: true, reason: "insufficient_logs", monthId };
  }

  const userMessage = `Genera mi proyección "Efecto Mariposa" a 3 años.

Mis hábitos activos este mes (${start.toISOString().slice(0, 10)} a ${end.toISOString().slice(0, 10)}):
${context.habits
  .filter((h) => h.expected > 0)
  .map(
    (h) =>
      `- "${h.title}" (${h.category}) → ${h.completed}/${h.expected} días completados, racha actual: ${h.currentStreak} días`
  )
  .join("\n")}

Resumen del mes:
- Total check-ins: ${context.totalLogs}
- Hábitos activos: ${context.activeHabits}
- Tasa de completitud: ${(context.completionRate * 100).toFixed(0)}%
- Categorías principales: ${context.topCategories.join(", ")}
- Racha más larga activa: ${context.longestStreak} días`;

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-pro",
    systemInstruction: BUTTERFLY_PROMPT,
  });

  const result = await model.generateContent(userMessage);
  const text = result.response.text();

  let parsed;
  try {
    parsed = JSON.parse(extractJson(text));
  } catch (e) {
    console.error("No se pudo parsear la proyección mariposa:", text);
    throw new HttpsError("internal", "La IA devolvió un formato no válido.");
  }

  const stats = {
    totalLogs: context.totalLogs,
    activeHabits: context.activeHabits,
    completionRate: context.completionRate,
    topCategories: context.topCategories,
    longestStreak: context.longestStreak,
  };

  const projectionDoc = {
    monthId,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    monthStart: admin.firestore.Timestamp.fromDate(start),
    monthEnd: admin.firestore.Timestamp.fromDate(end),
    stats,
    titleKeep: parsed.titleKeep || "",
    storyKeep: parsed.storyKeep || "",
    titleAbandon: parsed.titleAbandon || "",
    storyAbandon: parsed.storyAbandon || "",
    keyMoments: parsed.keyMoments || [],
    closingMessage: parsed.closingMessage || "",
  };

  await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("butterfly_projections")
    .doc(monthId)
    .set(projectionDoc);

  return { skipped: false, monthId };
}

// Trigger manual desde la app — analiza el mes en curso
exports.generateButterflyProjection = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
     const allowed = await checkRateLimit(uid);
     if (!allowed) {
       throw new HttpsError(
         "resource-exhausted",
         "Has hecho demasiadas peticiones. Espera unos minutos."
       );
     }

    try {
      return await runButterflyProjection(uid, new Date(), { currentMonth: true });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error en generateButterflyProjection:", error);
      throw new HttpsError(
        "internal",
        "No se pudo generar la proyección. Inténtalo más tarde."
      );
    }
  }
);

// Job programado: día 1 de cada mes a las 09:00 Europa/Madrid
exports.butterflyProjectionJob = onSchedule(
  {
    schedule: "0 9 1 * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();

    const usersSnapshot = await db
      .collection("users")
      .where("onboardingCompleted", "==", true)
      .get();

    console.log(`butterflyProjectionJob: procesando ${usersSnapshot.size} usuarios`);

    let generated = 0;
    let skipped = 0;
    let errors = 0;

    for (const userDoc of usersSnapshot.docs) {
      try {
        const result = await runButterflyProjection(userDoc.id, now);
        if (result.skipped) {
          skipped += 1;
        } else {
          generated += 1;
        }
      } catch (e) {
        errors += 1;
        console.error(`Error procesando ${userDoc.id}:`, e.message);
      }
    }

    console.log(
      `butterflyProjectionJob terminado: ${generated} generadas, ${skipped} omitidas, ${errors} errores`
    );
  }
);

// ==================== RENEGOCIACION INTELIGENTE ====================

const RENEGOTIATION_PROMPT = `Eres un coach de hábitos empático.
El usuario ha fallado este hábito ≥3 días en su frecuencia objetivo.
Propón UN ajuste concreto y factible (no rendirse, adaptar).

Devuelve SOLO JSON válido:
{
  "diagnosis": "1 frase explicando por qué crees que falla",
  "strategy": "lower_intensity" | "change_time" | "split_micro" | "reduce_frequency",
  "suggestedTitle": "string",
  "suggestedDescription": "string",
  "suggestedReminderTime": "HH:mm" | null,
  "suggestedTargetDays": [1,2,3,4,5] | null,
  "encouragement": "1 frase motivacional, tuteando"
}`;

// Calcula si el hábito lleva ≥3 días objetivo consecutivos sin completar.
// Devuelve el contexto si es elegible, null si no.
async function buildRenegotiationContext(uid, habitId) {
  const db = admin.firestore();
  const habitDoc = await db
    .collection("users")
    .doc(uid)
    .collection("habits")
    .doc(habitId)
    .get();

  if (!habitDoc.exists) return null;
  const habit = { id: habitId, ...habitDoc.data() };
  const targetDays = habit.targetDays || [];
  if (targetDays.length === 0) return null;

  const since = new Date();
  since.setDate(since.getDate() - 14);
  since.setHours(0, 0, 0, 0);

  const logsSnap = await db
    .collection("users")
    .doc(uid)
    .collection("habits")
    .doc(habitId)
    .collection("logs")
    .where("date", ">=", admin.firestore.Timestamp.fromDate(since))
    .get();

  const doneDates = new Set();
  for (const doc of logsSnap.docs) {
    const d = doc.data();
    if (d.completed || d.shielded) {
      const ts = d.date.toDate();
      doneDates.add(`${ts.getFullYear()}-${ts.getMonth()}-${ts.getDate()}`);
    }
  }

  // recorrer los últimos 14 días buscando targetDays (más reciente primero)
  const now = new Date();
  const recentTargetDays = [];
  for (let i = 0; i < 14; i++) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const weekday = d.getDay() === 0 ? 7 : d.getDay();
    if (targetDays.includes(weekday)) {
      const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
      recentTargetDays.push({ date: d, done: doneDates.has(key) });
    }
  }

  if (recentTargetDays.length < 3) return null;
  const lastThree = recentTargetDays.slice(0, 3);
  if (!lastThree.every((d) => !d.done)) return null;

  return { habit, missedDays: lastThree.length };
}

// Genera (o saltea si ya hay una pendiente) la sugerencia para un hábito
async function runRenegotiation(uid, habitId) {
  const ctx = await buildRenegotiationContext(uid, habitId);
  if (!ctx) return { skipped: true, reason: "not_eligible", habitId };

  const db = admin.firestore();
  const existing = await db
    .collection("users")
    .doc(uid)
    .collection("renegotiations")
    .doc(habitId)
    .get();

  // si ya hay una pendiente (sin applied ni dismissed), no regenerar
  if (existing.exists) {
    const data = existing.data();
    if (!data.appliedAt && !data.dismissedAt) {
      return { skipped: true, reason: "already_pending", habitId };
    }
  }

  const { habit } = ctx;
  const userMessage = `Hábito: "${habit.title}" (${habit.category})
Descripción: ${habit.description || "sin descripción"}
Días objetivo: ${(habit.targetDays || []).join(",")}
Recordatorio actual: ${habit.reminderTime || "ninguno"}
Días fallados consecutivos: ${ctx.missedDays}

Propón un ajuste concreto para que pueda retomarlo.`;

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-pro",
    systemInstruction: RENEGOTIATION_PROMPT,
  });

  const result = await model.generateContent(userMessage);
  const text = result.response.text();

  let parsed;
  try {
    parsed = JSON.parse(extractJson(text));
  } catch (e) {
    console.error("No se pudo parsear la renegociación:", text);
    throw new HttpsError("internal", "La IA devolvió un formato no válido.");
  }

  const renoDoc = {
    habitId,
    habitTitle: habit.title,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    missedDays: ctx.missedDays,
    diagnosis: parsed.diagnosis || "",
    strategy: parsed.strategy || "lower_intensity",
    suggestedTitle: parsed.suggestedTitle || habit.title,
    suggestedDescription: parsed.suggestedDescription || null,
    suggestedReminderTime: parsed.suggestedReminderTime || null,
    suggestedTargetDays: parsed.suggestedTargetDays || null,
    encouragement: parsed.encouragement || "",
    appliedAt: null,
    dismissedAt: null,
  };

  await db
    .collection("users")
    .doc(uid)
    .collection("renegotiations")
    .doc(habitId)
    .set(renoDoc);

  return { skipped: false, habitId };
}

// Trigger manual desde la app (botón en HabitDetailScreen)
exports.generateRenegotiation = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    const { habitId } = request.data;

    if (!habitId || typeof habitId !== "string") {
      throw new HttpsError("invalid-argument", "habitId requerido.");
    }

    // rate limit propio: 5 renegociaciones/hora por usuario
    const ref = admin.firestore().collection("rate_limits").doc(uid);
    const doc = await ref.get();
    const nowTs = Date.now();
    const oneHourAgo = nowTs - 60 * 60 * 1000;

    if (doc.exists) {
      const requests = (doc.data().renoRequests || []).filter(
        (ts) => ts > oneHourAgo
      );
      if (requests.length >= 5) {
        throw new HttpsError(
          "resource-exhausted",
          "Has hecho demasiadas peticiones de renegociación. Espera unos minutos."
        );
      }
      requests.push(nowTs);
      await ref.update({ renoRequests: requests });
    } else {
      await ref.set({ renoRequests: [nowTs] });
    }

    try {
      return await runRenegotiation(uid, habitId);
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error en generateRenegotiation:", error);
      throw new HttpsError(
        "internal",
        "No se pudo generar la renegociación. Inténtalo más tarde."
      );
    }
  }
);

// Job diario a las 07:00 Europa/Madrid — analiza todos los hábitos activos
exports.renegotiationJob = onSchedule(
  {
    schedule: "0 7 * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    secrets: [geminiApiKey],
  },
  async () => {
    const db = admin.firestore();

    const usersSnapshot = await db
      .collection("users")
      .where("onboardingCompleted", "==", true)
      .get();

    console.log(`renegotiationJob: procesando ${usersSnapshot.size} usuarios`);

    let generated = 0;
    let skipped = 0;
    let errors = 0;

    for (const userDoc of usersSnapshot.docs) {
      try {
        const habitsSnap = await db
          .collection("users")
          .doc(userDoc.id)
          .collection("habits")
          .where("isActive", "==", true)
          .get();

        for (const habitDoc of habitsSnap.docs) {
          try {
            const result = await runRenegotiation(userDoc.id, habitDoc.id);
            result.skipped ? (skipped += 1) : (generated += 1);
          } catch (e) {
            errors += 1;
            console.error(
              `Error procesando ${userDoc.id}/${habitDoc.id}:`,
              e.message
            );
          }
        }
      } catch (e) {
        errors += 1;
        console.error(`Error listando hábitos de ${userDoc.id}:`, e.message);
      }
    }

    console.log(
      `renegotiationJob terminado: ${generated} generadas, ${skipped} omitidas, ${errors} errores`
    );
  }
);

// ==================== DETECCION DE PATRONES ====================

// Prompt para detectar correlaciones y patrones entre hábitos
const PATTERN_INSIGHTS_PROMPT = `
Eres un analista de datos de hábitos personales. Analiza estadísticas de completado
y genera insights accionables basados en patrones reales.

TIPOS DE INSIGHT:
- day_effect: el día de la semana influye significativamente en el completado
- cross_habit: completar A predice (o impide) completar B
- time_cluster: los hábitos de mañana y tarde tienen tasas muy distintas
- category_synergy: una categoría de hábitos arrastra a otra
- streak_predictor: patrón que predice cuándo se va a romper una racha
- vulnerability: punto de debilidad recurrente (día, hábito o franja)

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con un objeto JSON válido. Sin texto fuera del JSON.
2. Genera entre 2 y 6 insights, solo los estadísticamente relevantes.
3. Omite insights con datos insuficientes o correlaciones débiles.
4. Tono de descubrimiento: "¿Sabías que...?", "Patrón detectado:", "Tendencia clara:"
5. Confianza: "high" (≥75%), "medium" (50–74%), "low" (<50%)
6. El campo "actionable" debe ser un consejo concreto, implementable mañana mismo.
7. No inventes patrones: si los datos no muestran correlación clara, no la reportes.

FORMATO DE RESPUESTA (JSON):
{
  "insights": [
    {
      "type": "cross_habit|day_effect|time_cluster|category_synergy|streak_predictor|vulnerability",
      "title": "Título corto y evocador del hallazgo",
      "description": "Descripción del patrón en 1-2 frases concretas con datos",
      "relatedHabits": ["nombre del hábito implicado"],
      "confidence": "high|medium|low",
      "actionable": "Consejo concreto implementable mañana"
    }
  ],
  "summary": "Resumen de 1-2 frases con el hallazgo más importante",
  "dataQuality": "good|limited"
}
`;

// Construye la matriz cruzada de patrones para el rango de fechas dado
async function buildPatternContext(uid, start, end) {
  const db = admin.firestore();

  const habitsSnapshot = await db
    .collection("users").doc(uid).collection("habits")
    .where("isActive", "==", true).get();

  const habits = habitsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  if (habits.length === 0) {
    return { habits: [], totalLogs: 0, analyzedDays: 0 };
  }

  // Cargar logs completados por hábito dentro del rango
  const habitCompletedDates = {};
  let totalLogs = 0;

  for (const habit of habits) {
    const logsSnapshot = await db
      .collection("users").doc(uid).collection("habits").doc(habit.id)
      .collection("logs")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(end))
      .get();

    const completedDates = new Set();
    for (const doc of logsSnapshot.docs) {
      const d = doc.data();
      if (d.completed === true) {
        const ts = d.date.toDate();
        completedDates.add(`${ts.getFullYear()}-${ts.getMonth()}-${ts.getDate()}`);
        totalLogs++;
      }
    }
    habitCompletedDates[habit.id] = completedDates;
  }

  // Construir días analizados: fechas donde hay al menos un hábito programado
  const analyzedDays = [];
  const cursor = new Date(start);
  while (cursor <= end) {
    const weekday = cursor.getDay() === 0 ? 7 : cursor.getDay();
    const dateKey = `${cursor.getFullYear()}-${cursor.getMonth()}-${cursor.getDate()}`;
    const scheduled = [];
    const completed = [];

    for (const habit of habits) {
      if ((habit.targetDays || []).includes(weekday)) {
        scheduled.push(habit.id);
        if (habitCompletedDates[habit.id]?.has(dateKey)) {
          completed.push(habit.id);
        }
      }
    }

    if (scheduled.length > 0) {
      analyzedDays.push({ weekday, dateKey, scheduled, completed });
    }
    cursor.setDate(cursor.getDate() + 1);
  }

  // dayOfWeekStats: tasa media de completado por día de semana (1=lunes … 7=domingo)
  const dayOfWeekStats = {};
  for (let d = 1; d <= 7; d++) {
    const daysForWeekday = analyzedDays.filter((day) => day.weekday === d);
    if (daysForWeekday.length === 0) continue;
    const totalRate = daysForWeekday.reduce(
      (sum, day) => sum + (day.scheduled.length > 0 ? day.completed.length / day.scheduled.length : 0),
      0
    );
    dayOfWeekStats[d] = {
      sampleDays: daysForWeekday.length,
      completionRate: Math.round((totalRate / daysForWeekday.length) * 100) / 100,
    };
  }

  // crossHabitPairs: P(B completado | A completado) para pares con ≥5 días co-programados
  const crossHabitPairs = [];
  for (let i = 0; i < habits.length; i++) {
    for (let j = 0; j < habits.length; j++) {
      if (i === j) continue;
      const hA = habits[i].id;
      const hB = habits[j].id;
      const coScheduled = analyzedDays.filter(
        (day) => day.scheduled.includes(hA) && day.scheduled.includes(hB)
      );
      if (coScheduled.length < 5) continue;
      const aCompleted = coScheduled.filter((day) => day.completed.includes(hA));
      if (aCompleted.length === 0) continue;
      const bothCompleted = aCompleted.filter((day) => day.completed.includes(hB));
      const pBgivenA = bothCompleted.length / aCompleted.length;
      if (pBgivenA > 0.6 || pBgivenA < 0.3) {
        crossHabitPairs.push({
          habitA: habits[i].title,
          habitB: habits[j].title,
          pBgivenA: Math.round(pBgivenA * 100) / 100,
          coScheduledDays: coScheduled.length,
        });
      }
    }
  }
  // Top 10 por fuerza de correlación (más alejada del 50%)
  crossHabitPairs.sort(
    (a, b) => Math.abs(b.pBgivenA - 0.5) - Math.abs(a.pBgivenA - 0.5)
  );
  const topCrossPairs = crossHabitPairs.slice(0, 10);

  // streakBreakPatterns: día de semana donde empiezan más rupturas de racha
  const streakBreaks = {};
  for (const habit of habits) {
    let prevCompleted = true;
    for (const day of analyzedDays) {
      if (!day.scheduled.includes(habit.id)) continue;
      const done = day.completed.includes(habit.id);
      if (!done && prevCompleted) {
        streakBreaks[day.weekday] = (streakBreaks[day.weekday] || 0) + 1;
      }
      prevCompleted = done;
    }
  }

  // timeCluster: tasas de completado por franja horaria (mañana <12:00 vs tarde ≥12:00)
  const calcClusterStats = (clusterHabits) => {
    if (clusterHabits.length === 0) return null;
    let totalSch = 0, totalComp = 0;
    for (const habit of clusterHabits) {
      for (const day of analyzedDays) {
        if (day.scheduled.includes(habit.id)) {
          totalSch++;
          if (day.completed.includes(habit.id)) totalComp++;
        }
      }
    }
    return {
      count: clusterHabits.length,
      completionRate: totalSch > 0 ? Math.round((totalComp / totalSch) * 100) / 100 : null,
    };
  };

  const morningHabits = habits.filter((h) => {
    const hour = h.reminderTime ? parseInt(h.reminderTime.split(":")[0], 10) : NaN;
    return !isNaN(hour) && hour < 12;
  });
  const afternoonHabits = habits.filter((h) => {
    const hour = h.reminderTime ? parseInt(h.reminderTime.split(":")[0], 10) : NaN;
    return !isNaN(hour) && hour >= 12;
  });

  return {
    habits: habits.map((h) => ({
      id: h.id,
      title: h.title,
      category: h.category || "otro",
      reminderTime: h.reminderTime || null,
    })),
    totalLogs,
    analyzedDays: analyzedDays.length,
    dayOfWeekStats,
    crossHabitPairs: topCrossPairs,
    streakBreakPatterns: streakBreaks,
    timeCluster: {
      morning: calcClusterStats(morningHabits),
      afternoon: calcClusterStats(afternoonHabits),
    },
  };
}

// Lógica compartida: genera los insights de patrones para un usuario en un período
async function runPatternInsights(uid, now, { manual = false } = {}) {
  const { start, end } = manual ? getCurrentMonthRange(now) : getPreviousMonthRange(now);
  const periodId = getMonthId(start);

  const context = await buildPatternContext(uid, start, end);

  console.log(`[patterns] uid=${uid} analyzedDays=${context.analyzedDays} habits=${context.habits.length} totalLogs=${context.totalLogs}`);

  // Threshold: mínimo 14 días con datos y ≥3 hábitos activos
  if (context.analyzedDays < 14 || context.habits.length < 3) {
    console.log(`[patterns] skipped — analyzedDays=${context.analyzedDays} (need 14), habits=${context.habits.length} (need 3)`);
    return { skipped: true, reason: "insufficient_data", periodId };
  }

  const dayNames = { 1: "lunes", 2: "martes", 3: "miércoles", 4: "jueves", 5: "viernes", 6: "sábado", 7: "domingo" };

  const dowLines = Object.entries(context.dayOfWeekStats)
    .map(([d, s]) => `  ${dayNames[d] || d}: ${(s.completionRate * 100).toFixed(0)}% (${s.sampleDays} días de muestra)`)
    .join("\n");

  const crossLines =
    context.crossHabitPairs.length > 0
      ? context.crossHabitPairs
          .map((p) => `  "${p.habitA}" → "${p.habitB}": P=${(p.pBgivenA * 100).toFixed(0)}% cuando A se completa (${p.coScheduledDays} días juntos)`)
          .join("\n")
      : "  Sin pares con suficientes días co-programados";

  const breakLines =
    Object.keys(context.streakBreakPatterns).length > 0
      ? Object.entries(context.streakBreakPatterns)
          .sort((a, b) => b[1] - a[1])
          .map(([d, count]) => `  ${dayNames[d] || d}: ${count} rupturas de racha`)
          .join("\n")
      : "  Sin datos de rupturas";

  const clusterLines = [
    context.timeCluster.morning
      ? `  Mañana (<12:00) — ${context.timeCluster.morning.count} hábitos: ${context.timeCluster.morning.completionRate !== null ? (context.timeCluster.morning.completionRate * 100).toFixed(0) + "%" : "sin datos"}`
      : "  Sin hábitos de mañana",
    context.timeCluster.afternoon
      ? `  Tarde (≥12:00) — ${context.timeCluster.afternoon.count} hábitos: ${context.timeCluster.afternoon.completionRate !== null ? (context.timeCluster.afternoon.completionRate * 100).toFixed(0) + "%" : "sin datos"}`
      : "  Sin hábitos de tarde",
  ].join("\n");

  const userMessage = `Analiza los patrones de mis hábitos del período ${start.toISOString().slice(0, 10)} al ${end.toISOString().slice(0, 10)}.

Hábitos activos (${context.habits.length}):
${context.habits.map((h) => `- "${h.title}" (${h.category})${h.reminderTime ? ` a las ${h.reminderTime}` : ""}`).join("\n")}

Días analizados con hábitos programados: ${context.analyzedDays}
Total check-ins completados en el período: ${context.totalLogs}

Tasa de completado por día de la semana:
${dowLines}

Correlaciones entre hábitos (P(B | A completado)):
${crossLines}

Días donde más se inician rupturas de racha:
${breakLines}

Completado por franja horaria:
${clusterLines}

Genera entre 2 y 6 insights relevantes basándote exclusivamente en los datos anteriores.`;

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-pro",
    systemInstruction: PATTERN_INSIGHTS_PROMPT,
  });

  console.log(`[patterns] llamando a Gemini con ${context.habits.length} hábitos y ${context.crossHabitPairs.length} pares cruzados`);
  const result = await model.generateContent(userMessage);
  console.log(`[patterns] Gemini respondió`);
  const text = result.response.text();

  let parsed;
  try {
    const raw = extractJson(text);
    console.log(`[patterns] JSON extraído (${raw.length} chars)`);
    parsed = JSON.parse(raw);
    console.log(`[patterns] parse OK — ${parsed.insights?.length ?? 0} insights, quality=${parsed.dataQuality}`);
  } catch (e) {
    console.error("[patterns] No se pudo parsear:", e.message, "| texto:", text.substring(0, 200));
    throw new HttpsError("internal", "La IA devolvió un formato no válido.");
  }

  const insightDoc = {
    periodId,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    periodStart: admin.firestore.Timestamp.fromDate(start),
    periodEnd: admin.firestore.Timestamp.fromDate(end),
    stats: {
      totalHabits: context.habits.length,
      totalLogs: context.totalLogs,
      analyzedDays: context.analyzedDays,
    },
    insights: parsed.insights || [],
    summary: parsed.summary || "",
    dataQuality: parsed.dataQuality || "limited",
  };

  console.log(`[patterns] escribiendo en Firestore: users/${uid}/pattern_insights/${periodId}`);
  await admin.firestore()
    .collection("users").doc(uid)
    .collection("pattern_insights").doc(periodId)
    .set(insightDoc);
  console.log(`[patterns] guardado OK`);

  return { skipped: false, periodId };
}

// Trigger manual desde la app — analiza el mes en curso
exports.generatePatternInsights = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
    timeoutSeconds: 300,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    const allowed = await checkRateLimit(uid);
    if (!allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "Has hecho demasiadas peticiones. Espera unos minutos."
      );
    }

    try {
      return await runPatternInsights(uid, new Date(), { manual: true });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error en generatePatternInsights:", error);
      throw new HttpsError(
        "internal",
        "No se pudo generar los insights. Inténtalo más tarde."
      );
    }
  }
);

// Job programado: martes a las 10:00 Europa/Madrid (un día después de la revisión semanal)
exports.patternInsightsJob = onSchedule(
  {
    schedule: "0 10 * * 2",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    secrets: [geminiApiKey],
    timeoutSeconds: 540,
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();

    const usersSnapshot = await db
      .collection("users")
      .where("onboardingCompleted", "==", true)
      .get();

    console.log(`patternInsightsJob: procesando ${usersSnapshot.size} usuarios`);

    let generated = 0;
    let skipped = 0;
    let errors = 0;

    for (const userDoc of usersSnapshot.docs) {
      try {
        const result = await runPatternInsights(userDoc.id, now);
        if (result.skipped) {
          skipped += 1;
        } else {
          generated += 1;
        }
      } catch (e) {
        errors += 1;
        console.error(`Error procesando ${userDoc.id}:`, e.message);
      }
    }

    console.log(
      `patternInsightsJob terminado: ${generated} generados, ${skipped} omitidos, ${errors} errores`
    );
  }
);

// Extrae JSON limpio de la respuesta de Gemini (Blindado)
function extractJson(text) {
  const jsonStartIndex = text.indexOf('{');
  const jsonEndIndex = text.lastIndexOf('}');

  if (jsonStartIndex !== -1 && jsonEndIndex !== -1) {
    // Recorta exactamente desde la primera '{' hasta la última '}'
    return text.substring(jsonStartIndex, jsonEndIndex + 1);
  }

  // Si no hay llaves, devolvemos el texto original para que el try-catch de arriba lo maneje
  return text;
}