const { onCall, HttpsError } = require("firebase-functions/v2/https");
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
  "planTitle": "Título descriptivo del plan",
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

// Extrae JSON limpio de la respuesta de Gemini
function extractJson(text) {
  const match = text.match(/```json?\s*([\s\S]*?)```/);
  if (match) return match[1].trim();

  const trimmed = text.trim();
  if (trimmed.startsWith("{")) return trimmed;

  return text;
}
