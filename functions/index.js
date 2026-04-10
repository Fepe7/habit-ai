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

    // 2. Rate limiting
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

// Lógica compartida: genera la revisión de una semana para un usuario
async function runWeeklyReview(uid, now) {
  const { start, end } = getPreviousWeekRange(now);
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
      return await runWeeklyReview(uid, new Date());
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

// Extrae JSON limpio de la respuesta de Gemini
function extractJson(text) {
  const match = text.match(/```json?\s*([\s\S]*?)```/);
  if (match) return match[1].trim();

  const trimmed = text.trim();
  if (trimmed.startsWith("{")) return trimmed;

  return text;
}
