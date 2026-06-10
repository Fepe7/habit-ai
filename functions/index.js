const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

admin.initializeApp();

// Fusible de coste: techo duro de instancias para toda la app.
// Evita que un bug en bucle o un abuso disparen la factura.
// concurrency alto porque las funciones esperan a Gemini (I/O), no calculan.
setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
  concurrency: 40,
});

// Modelos Gemini: pro para chat interactivo (calidad), flash para jobs
// automáticos en background (10-20x más barato, sobra para resúmenes).
const MODEL_PRO = "gemini-2.5-pro";
const MODEL_FLASH = "gemini-2.5-flash";

// La API key se guarda como secret en Firebase, nunca en el codigo
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Prompts por idioma — se seleccionan en runtime según request.data.locale
const promptsByLocale = {
  es: require("./prompts/es"),
  en: require("./prompts/en"),
};

// Devuelve los prompts del idioma solicitado; fallback a español
function getPrompts(locale) {
  return promptsByLocale[locale] || promptsByLocale["es"];
}

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

    if (requests.length >= 10) {
      return false;
    }

    requests.push(now);
    await ref.update({ requests });
  } else {
    await ref.set({ requests: [now] });
  }

  return true;
}

// Lanza HttpsError si la IA está pausada por presupuesto o manualmente.
// Consultar antes de cada llamada a Gemini para evitar coste innecesario.
async function assertAiAvailable() {
  const doc = await admin.firestore().doc("system/ai_state").get();
  if (doc.exists && doc.data().paused === true) {
    throw new HttpsError(
      "unavailable",
      "El asistente de IA está en pausa temporal. El resto de la app funciona con normalidad."
    );
  }
}



// Cloud Function callable desde Flutter
exports.generateHabitPlan = onCall(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
    maxInstances: 3,
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
    const { message, history, locale } = request.data;
    const prompts = getPrompts(locale);

    if (!message || typeof message !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "El mensaje no puede estar vacío."
      );
    }

    await assertAiAvailable();
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
        model: MODEL_PRO,
        systemInstruction: prompts.SYSTEM_PROMPT,
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

  // Lee registros de ánimo de la semana (opcional — si no hay, moodData = null)
  let moodData = null;
  try {
    const moodSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("mood_entries")
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("timestamp", "<=", admin.firestore.Timestamp.fromDate(end))
      .get();

    if (!moodSnapshot.empty) {
      const moodEntries = moodSnapshot.docs.map((d) => d.data());
      const totalRating = moodEntries.reduce((acc, e) => acc + (e.rating || 0), 0);
      const avgRating = totalRating / moodEntries.length;

      // etiquetas más frecuentes
      const labelCount = {};
      for (const e of moodEntries) {
        for (const label of (e.labels || [])) {
          labelCount[label] = (labelCount[label] || 0) + 1;
        }
      }
      const topLabels = Object.entries(labelCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 4)
        .map(([l]) => l);

      // media por día de la semana
      const dayNames = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
      const byDay = {};
      for (const e of moodEntries) {
        const d = e.timestamp.toDate();
        const dayIdx = d.getDay() === 0 ? 6 : d.getDay() - 1; // 0=lun
        if (!byDay[dayIdx]) byDay[dayIdx] = [];
        byDay[dayIdx].push(e.rating || 3);
      }
      const dailyPattern = Object.entries(byDay)
        .map(([idx, ratings]) => {
          const avg = ratings.reduce((a, b) => a + b, 0) / ratings.length;
          return `${dayNames[parseInt(idx)]}=${avg.toFixed(1)}`;
        })
        .join(", ");

      // correlación sencilla: hábitos con snapshot vs media general
      const correlations = [];
      for (const habit of habitStats) {
        const withHabit = moodEntries.filter((e) =>
          (e.habitsCompletedSnapshot || []).includes(habit.id)
        );
        const withoutHabit = moodEntries.filter(
          (e) => !(e.habitsCompletedSnapshot || []).includes(habit.id)
        );
        if (withHabit.length >= 2 && withoutHabit.length >= 1) {
          const avgWith =
            withHabit.reduce((a, e) => a + (e.rating || 3), 0) / withHabit.length;
          const avgWithout =
            withoutHabit.reduce((a, e) => a + (e.rating || 3), 0) / withoutHabit.length;
          const diff = avgWith - avgWithout;
          if (Math.abs(diff) >= 0.3) {
            correlations.push(
              `"${habit.title}" → ánimo ${avgWith.toFixed(1)} con vs ${avgWithout.toFixed(1)} sin (${diff >= 0 ? "+" : ""}${diff.toFixed(1)})`
            );
          }
        }
      }

      moodData = {
        count: moodEntries.length,
        avgRating: Math.round(avgRating * 10) / 10,
        topLabels,
        dailyPattern,
        correlations: correlations.slice(0, 3),
      };
    }
  } catch (err) {
    // no bloquear la revisión si falla la lectura de mood
    console.warn("No se pudieron leer mood_entries:", err.message);
  }

  return { habits: habitStats, totalLogs, moodData };
}

// Lógica compartida: genera la revisión de una semana para un usuario.
// Si currentWeek=true analiza la semana en curso (lun hasta 'now').
// Si no, analiza la semana anterior completa (uso del job automatico).
async function runWeeklyReview(uid, now, { currentWeek = false, locale = "es" } = {}) {
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

Total de check-ins de la semana: ${context.totalLogs}${
    context.moodData
      ? `

Datos de ánimo de la semana:
- Registros: ${context.moodData.count}
- Media: ${context.moodData.avgRating}/5
- Sentimientos frecuentes: ${context.moodData.topLabels.join(", ") || "ninguno"}
- Patrón diario: ${context.moodData.dailyPattern || "sin datos"}${
          context.moodData.correlations.length > 0
            ? `\n- Correlaciones hábito-ánimo:\n${context.moodData.correlations.map((c) => `  · ${c}`).join("\n")}`
            : ""
        }`
      : ""
  }`;

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: MODEL_FLASH,
    systemInstruction: getPrompts(locale).WEEKLY_REVIEW_PROMPT,
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
    moodInsights: parsed.moodInsights || null,
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
    maxInstances: 3,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    const locale = request.data?.locale || "es";
    await assertAiAvailable();
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
      return await runWeeklyReview(uid, new Date(), { currentWeek: true, locale });
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

    const aiState = await db.doc("system/ai_state").get();
    if (aiState.exists && aiState.data().paused === true) {
      console.log("[billing] IA pausada — saltando weeklyReviewJob");
      return;
    }

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
          // avisar al usuario de que su revisión ya está disponible
          await sendPushToUser(userDoc.id, {
            title: "Tu revisión semanal está lista",
            body: "Descubre cómo te fue la semana y tus recomendaciones.",
            route: `/dashboard/weekly-review/${result.weekId}`,
          });
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
async function runButterflyProjection(uid, now, { currentMonth = false, locale = "es" } = {}) {
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
    model: MODEL_FLASH,
    systemInstruction: getPrompts(locale).BUTTERFLY_PROMPT,
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
    maxInstances: 3,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    const locale = request.data?.locale || "es";
    await assertAiAvailable();
     const allowed = await checkRateLimit(uid);
     if (!allowed) {
       throw new HttpsError(
         "resource-exhausted",
         "Has hecho demasiadas peticiones. Espera unos minutos."
       );
     }

    try {
      return await runButterflyProjection(uid, new Date(), { currentMonth: true, locale });
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

    const aiState = await db.doc("system/ai_state").get();
    if (aiState.exists && aiState.data().paused === true) {
      console.log("[billing] IA pausada — saltando butterflyProjectionJob");
      return;
    }

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
          // avisar de que la proyección mensual ya puede verse
          await sendPushToUser(userDoc.id, {
            title: "🦋 Tu proyección mensual está lista",
            body: "Mira cómo tus pequeños hábitos de hoy cambian tu futuro.",
            route: `/dashboard/butterfly/${result.monthId}`,
          });
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
async function runRenegotiation(uid, habitId, locale = "es") {
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
    model: MODEL_FLASH,
    systemInstruction: getPrompts(locale).RENEGOTIATION_PROMPT,
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
    maxInstances: 3,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    await assertAiAvailable();
    const { habitId, locale } = request.data;

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
      return await runRenegotiation(uid, habitId, locale || "es");
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

    const aiState = await db.doc("system/ai_state").get();
    if (aiState.exists && aiState.data().paused === true) {
      console.log("[billing] IA pausada — saltando renegotiationJob");
      return;
    }

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

        // máximo un push de renegociación por usuario y día, aunque la IA
        // genere propuestas para varios hábitos a la vez
        let pushedThisUser = false;
        for (const habitDoc of habitsSnap.docs) {
          try {
            const result = await runRenegotiation(userDoc.id, habitDoc.id);
            result.skipped ? (skipped += 1) : (generated += 1);
            if (!result.skipped && !pushedThisUser) {
              pushedThisUser = true;
              const habitTitle = habitDoc.data().title || "un hábito";
              await sendPushToUser(userDoc.id, {
                title: "🤝 La IA tiene una propuesta para ti",
                body: `«${habitTitle}» se te está atascando. Mira la versión más fácil que te sugiere.`,
                route: `/habit/${habitDoc.id}`,
              });
            }
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
async function runPatternInsights(uid, now, { manual = false, locale = "es" } = {}) {
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
    model: MODEL_FLASH,
    systemInstruction: getPrompts(locale).PATTERN_INSIGHTS_PROMPT,
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
    maxInstances: 3,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para usar el asistente."
      );
    }

    const uid = request.auth.uid;
    await assertAiAvailable();
    const locale = request.data?.locale || "es";
    const allowed = await checkRateLimit(uid);
    if (!allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "Has hecho demasiadas peticiones. Espera unos minutos."
      );
    }

    try {
      return await runPatternInsights(uid, new Date(), { manual: true, locale });
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

    const aiState = await db.doc("system/ai_state").get();
    if (aiState.exists && aiState.data().paused === true) {
      console.log("[billing] IA pausada — saltando patternInsightsJob");
      return;
    }

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
          // avisar de que hay insights nuevos de patrones
          await sendPushToUser(userDoc.id, {
            title: "💡 Hemos detectado tus patrones",
            body: "Descubre qué días y horas te funcionan mejor.",
            route: `/dashboard/patterns/${result.periodId}`,
          });
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

// Pausa selectiva de IA cuando el presupuesto de Cloud Billing lo supera.
// Escribe el flag en system/ai_state; los callables y los jobs lo consultan
// antes de llamar a Gemini. Auto-recuperación: cuando cost <= budget el flag
// vuelve a false solo con el siguiente mensaje del presupuesto.
exports.pauseAiOnBudgetExceeded = onMessagePublished(
  { topic: "billing-alerts", region: "europe-west1", maxInstances: 1 },
  async (event) => {
    const data = event.data.message.json;
    const cost = data?.costAmount ?? 0;
    const budget = data?.budgetAmount ?? 0;

    const paused = cost > budget;
    await admin.firestore().doc("system/ai_state").set(
      {
        paused,
        cost,
        budget,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(
      `[billing] IA ${paused ? "pausada" : "reanudada"} — coste: ${cost}, presupuesto: ${budget}`
    );
  }
);

// ==================== PUSH NOTIFICATIONS (FCM) ====================

// Envía una notificación push a todos los dispositivos registrados de un
// usuario. Lee los tokens de users/{uid}/fcm_tokens y limpia los inválidos
// para no acumular basura ni gastar envíos en tokens muertos.
async function sendPushToUser(uid, { title, body, route, data }) {
  if (!uid) return;
  const db = admin.firestore();
  const tokensSnap = await db
    .collection("users")
    .doc(uid)
    .collection("fcm_tokens")
    .get();
  if (tokensSnap.empty) return;

  const tokens = tokensSnap.docs.map((d) => d.id);

  const message = {
    notification: { title, body },
    // data debe ser plano de strings; el cliente lee `route` para el deep link
    // y flags opcionales como `skipForeground` (extras en `data`)
    data: { ...(route ? { route } : {}), ...(data || {}) },
    android: {
      priority: "high",
      notification: { channelId: "push_default" },
    },
    apns: {
      payload: { aps: { sound: "default" } },
    },
    tokens,
  };

  let resp;
  try {
    resp = await admin.messaging().sendEachForMulticast(message);
  } catch (e) {
    console.error(`[fcm] error enviando a ${uid}:`, e.message);
    return;
  }

  // Borrar tokens que FCM reporta como no registrados/ inválidos
  const cleanups = [];
  resp.responses.forEach((r, i) => {
    if (r.success) return;
    const code = r.error?.code || "";
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-registration-token") ||
      code.includes("invalid-argument")
    ) {
      cleanups.push(tokensSnap.docs[i].ref.delete());
    }
  });
  if (cleanups.length > 0) await Promise.all(cleanups);

  console.log(
    `[fcm] ${uid}: ${resp.successCount}/${tokens.length} enviados, ${cleanups.length} tokens limpiados`
  );
}

// Notifica al receptor cuando recibe una solicitud de seguimiento (perfil privado).
exports.onFollowRequestCreated = onDocumentCreated(
  { document: "follow_requests/{requestId}", region: "europe-west1" },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== "pending") return;
    const fromName = data.fromDisplayName || data.fromUsername || "Alguien";
    await sendPushToUser(data.toUid, {
      title: "Nueva solicitud de seguimiento",
      body: `${fromName} quiere seguirte`,
      route: "/followers?tab=2",
    });
  }
);

// Notifica al solicitante cuando su solicitud pasa a "accepted".
exports.onFollowRequestAccepted = onDocumentUpdated(
  { document: "follow_requests/{requestId}", region: "europe-west1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    // solo en la transición a accepted (evita reenvíos en otros updates)
    if (before.status === "accepted" || after.status !== "accepted") return;
    const toName = after.toDisplayName || after.toUsername || "Alguien";
    await sendPushToUser(after.fromUid, {
      title: "¡Solicitud aceptada!",
      body: `${toName} aceptó tu solicitud de seguimiento`,
      route: "/followers?tab=1",
    });
  }
);

// Notifica al usuario cuando alguien empieza a seguirle (follow directo a
// perfil público; también cubre el alta de follower al aceptar una solicitud).
exports.onNewFollower = onDocumentCreated(
  { document: "users/{userId}/followers/{followerId}", region: "europe-west1" },
  async (event) => {
    const { userId, followerId } = event.params;
    if (userId === followerId) return;
    const data = event.data?.data() || {};
    const name = data.displayName || data.username || "Alguien";
    await sendPushToUser(userId, {
      title: "Tienes un nuevo seguidor",
      body: `${name} empezó a seguirte`,
      route: "/followers?tab=0",
    });
  }
);

// ==================== PUSH: RETOS COMPARTIDOS ====================

// Lee el nombre visible de un participante del reto (subcolección participants)
// con fallback al directorio de usuarios y, en último término, a un genérico.
async function getDisplayNameForChallenge(challengeId, uid) {
  const db = admin.firestore();
  const participant = await db
    .collection("challenges")
    .doc(challengeId)
    .collection("participants")
    .doc(uid)
    .get();
  const pData = participant.data();
  if (pData?.displayName || pData?.username) {
    return pData.displayName || pData.username;
  }
  const dir = await db.collection("user_directory").doc(uid).get();
  const dData = dir.data();
  return dData?.displayName || dData?.username || "Alguien";
}

// Notifica al invitado cuando alguien le reta.
exports.onChallengeCreated = onDocumentCreated(
  { document: "challenges/{challengeId}", region: "europe-west1" },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== "pending" || !data.invitedUid) return;
    const name = await getDisplayNameForChallenge(
      event.params.challengeId,
      data.creatorUid
    );
    await sendPushToUser(data.invitedUid, {
      title: "⚔️ ¡Te han retado!",
      body: `${name} te reta: «${data.habitTitle}» durante ${data.durationDays} días`,
      route: `/challenges/${event.params.challengeId}`,
    });
  }
);

// Notifica los cambios de estado del reto: aceptado, rechazado y completado.
exports.onChallengeUpdated = onDocumentUpdated(
  { document: "challenges/{challengeId}", region: "europe-west1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    const challengeId = event.params.challengeId;
    const route = `/challenges/${challengeId}`;

    // pending → active: el invitado aceptó, avisamos al creador
    if (before.status === "pending" && after.status === "active") {
      const name = await getDisplayNameForChallenge(
        challengeId,
        after.invitedUid
      );
      await sendPushToUser(after.creatorUid, {
        title: "🤝 ¡Reto aceptado!",
        body: `${name} aceptó tu reto «${after.habitTitle}». ¡Empieza hoy!`,
        route,
      });
      return;
    }

    // pending → declined: aviso suave al creador, sin culpabilizar a nadie
    if (before.status === "pending" && after.status === "declined") {
      const name = await getDisplayNameForChallenge(
        challengeId,
        after.invitedUid
      );
      await sendPushToUser(after.creatorUid, {
        title: "Reto sin respuesta",
        body: `${name} no puede unirse a «${after.habitTitle}» ahora. ¡Prueba con otro reto!`,
        route: "/challenges",
      });
      return;
    }

    // active → completed: celebración para ambos participantes
    if (before.status === "active" && after.status === "completed") {
      const uids = after.participantUids || [];
      await Promise.all(
        uids.map((uid) =>
          sendPushToUser(uid, {
            title: "🏆 ¡Reto completado!",
            body: `Habéis terminado «${after.habitTitle}». ¡Enhorabuena a los dos!`,
            route,
          })
        )
      );
    }
  }
);

// Pique sano: cuando un participante completa un día del reto, se avisa al
// rival para incentivar que no se quede atrás. Como los retos son diarios,
// esto se autolimita a ~1 notificación al día por rival.
exports.onChallengeProgressUpdated = onDocumentUpdated(
  {
    document: "challenges/{challengeId}/progress/{uid}",
    region: "europe-west1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    // solo cuando suma un día completado (no en desmarcados ni otros updates)
    if ((after.completedCount || 0) <= (before.completedCount || 0)) return;

    const { challengeId, uid } = event.params;
    const db = admin.firestore();
    const challengeSnap = await db
      .collection("challenges")
      .doc(challengeId)
      .get();
    const challenge = challengeSnap.data();
    if (!challenge || challenge.status !== "active") return;

    const rivalUid = (challenge.participantUids || []).find((u) => u !== uid);
    if (!rivalUid) return;

    const name = await getDisplayNameForChallenge(challengeId, uid);
    await sendPushToUser(rivalUid, {
      title: `🔥 ${name} ya completó su día`,
      body: `Día ${after.completedCount} de «${challenge.habitTitle}» hecho. ¡No te quedes atrás!`,
      route: `/challenges/${challengeId}`,
    });
  }
);

// ==================== PUSH: REACCIONES Y ENGAGEMENT ====================

// Notifica al dueño del perfil cuando alguien reacciona con un emoji.
exports.onProfileReaction = onDocumentCreated(
  {
    document: "public_profiles/{ownerUid}/reactions/{reactorUid}",
    region: "europe-west1",
  },
  async (event) => {
    const { ownerUid, reactorUid } = event.params;
    if (ownerUid === reactorUid) return;
    const data = event.data?.data();
    if (!data) return;
    const name = data.reactorDisplayName || data.reactorUsername || "Alguien";
    await sendPushToUser(ownerUid, {
      title: "Nueva reacción en tu perfil",
      body: `${name} reaccionó ${data.emoji || "👏"} a tus logros`,
      route: "/profile",
    });
  }
);

// Rachas en riesgo: cada noche avisa a quien tiene una racha valiosa (>= 3
// días) y aún no ha completado ese hábito hoy. Solo se considera el hábito
// de mayor racha por usuario para no bombardear con varias notificaciones.
// Coste acotado: solo itera usuarios con tokens FCM registrados (cap 500).
exports.streakRiskJob = onSchedule(
  {
    schedule: "30 20 * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();

    // uids únicos con al menos un dispositivo registrado
    const tokensSnap = await db.collectionGroup("fcm_tokens").get();
    const uids = [
      ...new Set(
        tokensSnap.docs
          .map((d) => d.ref.parent.parent?.id)
          .filter((id) => Boolean(id))
      ),
    ].slice(0, 500);

    const now = new Date();
    const startOfToday = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate()
    );
    // weekday ISO 1-7 (lunes=1) como usa targetDays en el cliente
    const isoWeekday = now.getDay() === 0 ? 7 : now.getDay();

    let sent = 0;
    for (const uid of uids) {
      try {
        // usuarios en modo enfermedad no reciben presión por la racha
        const userSnap = await db.collection("users").doc(uid).get();
        const sickUntil = userSnap.data()?.sickModeUntil;
        if (sickUntil && sickUntil.toDate() > now) continue;

        const habitsSnap = await db
          .collection("users")
          .doc(uid)
          .collection("habits")
          .where("isActive", "==", true)
          .get();

        // hábito con mayor racha que toque hoy
        const candidate = habitsSnap.docs
          .map((d) => ({ id: d.id, ...d.data() }))
          .filter(
            (h) =>
              (h.currentStreak || 0) >= 3 &&
              (h.targetDays || []).includes(isoWeekday)
          )
          .sort((a, b) => (b.currentStreak || 0) - (a.currentStreak || 0))[0];
        if (!candidate) continue;

        // ¿ya tiene log de hoy? entonces la racha está a salvo
        const logSnap = await db
          .collection("users")
          .doc(uid)
          .collection("habits")
          .doc(candidate.id)
          .collection("logs")
          .where(
            "date",
            ">=",
            admin.firestore.Timestamp.fromDate(startOfToday)
          )
          .limit(1)
          .get();
        if (!logSnap.empty) continue;

        await sendPushToUser(uid, {
          title: `🔥 Racha de ${candidate.currentStreak} días en riesgo`,
          body: `Aún estás a tiempo: completa «${candidate.title}» antes de medianoche`,
          route: "/",
        });
        sent++;
      } catch (e) {
        console.error(`[streakRisk] error con ${uid}:`, e.message);
      }
    }
    console.log(`[streakRisk] ${sent}/${uids.length} avisos enviados`);
  }
);


// ==================== PUSH: ENGAGEMENT PROGRAMADO ====================

// Retos a punto de acabar: con 3 días restantes y en el último día se envía
// el marcador a ambos participantes para avivar el pique. Solo se notifica
// en esos dos hitos exactos para no repetir el aviso cada día.
exports.challengeEndingSoonJob = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const msPerDay = 24 * 60 * 60 * 1000;

    // pocos retos activos: filtrar endDate en código evita un índice compuesto
    const challengesSnap = await db
      .collection("challenges")
      .where("status", "==", "active")
      .get();

    let sent = 0;
    for (const doc of challengesSnap.docs) {
      try {
        const challenge = doc.data();
        const endDate = challenge.endDate?.toDate();
        if (!endDate) continue;
        const daysLeft = Math.ceil((endDate.getTime() - now.getTime()) / msPerDay);
        if (daysLeft !== 3 && daysLeft !== 1) continue;

        const uids = challenge.participantUids || [];
        if (uids.length !== 2) continue;

        // marcador de cada participante
        const progressDocs = await Promise.all(
          uids.map((uid) =>
            db
              .collection("challenges")
              .doc(doc.id)
              .collection("progress")
              .doc(uid)
              .get()
          )
        );
        const counts = {};
        uids.forEach((uid, i) => {
          counts[uid] = progressDocs[i].data()?.completedCount || 0;
        });

        const title =
          daysLeft === 1
            ? "🏁 ¡Último día de reto!"
            : "⏳ Quedan 3 días de reto";
        await Promise.all(
          uids.map((uid) => {
            const rival = uids.find((u) => u !== uid);
            return sendPushToUser(uid, {
              title,
              body: `«${challenge.habitTitle}»: llevas ${counts[uid]} días, tu rival ${counts[rival]}. ¡Está reñido!`,
              route: `/challenges/${doc.id}`,
            });
          })
        );
        sent += 2;
      } catch (e) {
        console.error(`[challengeEnding] error con ${doc.id}:`, e.message);
      }
    }
    console.log(`[challengeEnding] ${sent} avisos enviados`);
  }
);

// Fin del modo enfermedad: aviso de bienvenida sin culpa cuando expira.
// La ventana de 24h coincide con la frecuencia del job, así cada expiración
// se notifica exactamente una vez.
exports.sickModeEndedJob = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const usersSnap = await db
      .collection("users")
      .where("sickModeUntil", ">", admin.firestore.Timestamp.fromDate(dayAgo))
      .where("sickModeUntil", "<=", admin.firestore.Timestamp.fromDate(now))
      .get();

    for (const doc of usersSnap.docs) {
      await sendPushToUser(doc.id, {
        title: "💪 Modo enfermedad terminado",
        body: "Tus rachas te esperaron. Retómalas hoy, sin prisa.",
        route: "/",
      });
    }
    console.log(`[sickModeEnded] ${usersSnap.size} avisos enviados`);
  }
);

// Resumen dominical: teaser con los números de la semana que invita a abrir
// el dashboard. Distinto de la revisión semanal IA (esa llega el lunes con
// su propio push); este es el cierre de semana con datos crudos.
exports.weeklySummaryJob = onSchedule(
  {
    schedule: "0 19 * * 0",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    timeoutSeconds: 540,
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    // lunes de esta semana a las 00:00
    const isoWeekday = now.getDay() === 0 ? 7 : now.getDay();
    const monday = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() - (isoWeekday - 1)
    );
    const weekdayNames = [
      "lunes",
      "martes",
      "miércoles",
      "jueves",
      "viernes",
      "sábado",
      "domingo",
    ];

    // solo usuarios con dispositivo registrado (mismo criterio que streakRisk)
    const tokensSnap = await db.collectionGroup("fcm_tokens").get();
    const uids = [
      ...new Set(
        tokensSnap.docs
          .map((d) => d.ref.parent.parent?.id)
          .filter((id) => Boolean(id))
      ),
    ].slice(0, 500);

    let sent = 0;
    for (const uid of uids) {
      try {
        const habitsSnap = await db
          .collection("users")
          .doc(uid)
          .collection("habits")
          .where("isActive", "==", true)
          .get();
        if (habitsSnap.empty) continue;

        let totalLogs = 0;
        let scheduled = 0;
        const perWeekday = [0, 0, 0, 0, 0, 0, 0];

        for (const habitDoc of habitsSnap.docs) {
          scheduled += (habitDoc.data().targetDays || []).length;
          const logsSnap = await db
            .collection("users")
            .doc(uid)
            .collection("habits")
            .doc(habitDoc.id)
            .collection("logs")
            .where("date", ">=", admin.firestore.Timestamp.fromDate(monday))
            .get();
          for (const log of logsSnap.docs) {
            if (log.data().completed !== true) continue;
            totalLogs += 1;
            const d = log.data().date.toDate().getDay();
            perWeekday[d === 0 ? 6 : d - 1] += 1;
          }
        }

        // sin actividad no hay nada que celebrar (el rescate es otro flujo)
        if (totalLogs === 0) continue;

        const bestIndex = perWeekday.indexOf(Math.max(...perWeekday));
        const ratio = scheduled > 0 ? `${totalLogs}/${scheduled}` : `${totalLogs}`;
        await sendPushToUser(uid, {
          title: "📊 Tu semana en números",
          body: `${ratio} check-ins · mejor día: ${weekdayNames[bestIndex]}. Mira tu progreso completo.`,
          route: "/dashboard",
        });
        sent++;
      } catch (e) {
        console.error(`[weeklySummary] error con ${uid}:`, e.message);
      }
    }
    console.log(`[weeklySummary] ${sent}/${uids.length} resúmenes enviados`);
  }
);

// Logro desbloqueado: el doc lo crea el cliente con la app abierta (el
// overlay in-app ya celebra), así que `skipForeground` evita el banner
// duplicado; el push solo luce en los demás dispositivos del usuario.
exports.onAchievementUnlocked = onDocumentCreated(
  {
    document: "users/{userId}/achievements/{achievementId}",
    region: "europe-west1",
  },
  async (event) => {
    await sendPushToUser(event.params.userId, {
      title: "🏅 ¡Logro desbloqueado!",
      body: "Has conseguido un logro nuevo. Échale un vistazo a tu vitrina.",
      route: "/dashboard/achievements",
      data: { skipForeground: "1" },
    });
  }
);
