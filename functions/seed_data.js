/**
 * Script de datos de demostración para capturas de pantalla.
 *
 * Uso:
 *   node functions/seed_data.js --uid=TU_UID --keyfile=/ruta/a/key.json
 *
 * Cómo obtener el keyfile:
 *   Firebase Console → Project Settings → Service accounts → Generate new private key
 *
 * Cómo obtener tu UID:
 *   Firebase Console → Authentication → busca tu email → copia el UID
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- Parse argumentos ---
const args = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => {
      const eq = a.indexOf('=');
      return [a.slice(2, eq), a.slice(eq + 1)];
    })
);

const uid = args.uid;
if (!uid) {
  console.error('❌  Falta --uid=TU_UID');
  console.error('   Encuéntralo en Firebase Console → Authentication');
  process.exit(1);
}

// --- Init Firebase Admin ---
let appConfig;
if (args.keyfile) {
  const keyPath = path.resolve(args.keyfile);
  if (!fs.existsSync(keyPath)) {
    console.error(`❌  No encuentro el keyfile: ${keyPath}`);
    process.exit(1);
  }
  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  appConfig = { credential: admin.credential.cert(serviceAccount) };
  console.log('🔑 Usando service account key');
} else {
  appConfig = { projectId: 'habit-ai-184ad' };
  console.log('🔑 Usando Application Default Credentials');
}

admin.initializeApp(appConfig);
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

// --- Helpers de fecha ---
const today = new Date();
today.setHours(0, 0, 0, 0);

function daysAgo(n) {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  return d;
}

// Devuelve 1-7 (lunes=1, domingo=7) igual que DateTime.weekday de Dart
function dartWeekday(date) {
  const day = date.getDay();
  return day === 0 ? 7 : day;
}

function adminTimestamp(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

// Genera logs para un hábito dado un patrón de completado
// targetDays: [1..7], daysBack: cuántos días hacia atrás generar
// completionFn: (daysAgo) => boolean — decide si ese día se completa
function buildLogs(targetDays, daysBack, completionFn) {
  const logs = [];
  for (let i = daysBack; i >= 1; i--) {
    const date = daysAgo(i);
    const weekday = dartWeekday(date);
    if (!targetDays.includes(weekday)) continue;
    if (completionFn(i)) {
      logs.push({ date, completed: true, shielded: false });
    }
  }
  return logs;
}

// Patrón realista: alta tasa con pequeños huecos aleatorios pero seed fijo
function realisticPattern(i, rate = 0.88) {
  // Pseudo-random con seed basado en día para que sea reproducible
  const seed = (i * 2654435761) % 100;
  return seed < rate * 100;
}

// --- Definición de los datos ---

const groups = [
  {
    id: 'group_bienestar',
    data: {
      title: 'Plan Bienestar',
      emoji: '🏋️',
      description: 'Hábitos de salud y bienestar generados por la IA para mejorar tu energía diaria.',
      createdAt: adminTimestamp(daysAgo(58)),
      habitCount: 3,
      isActive: true,
      publishedTemplateId: null,
      conversationId: null,
    },
  },
  {
    id: 'group_productividad',
    data: {
      title: 'Modo Productividad',
      emoji: '🧠',
      description: 'Plan enfocado en aprendizaje y rendimiento mental.',
      createdAt: adminTimestamp(daysAgo(45)),
      habitCount: 3,
      isActive: true,
      publishedTemplateId: null,
      conversationId: null,
    },
  },
];

// targetDays: 1=lun, 7=dom
const habitDefs = [
  {
    id: 'habit_agua',
    groupId: 'group_bienestar',
    title: 'Beber 2L de agua',
    description: 'Mantener una hidratación óptima durante todo el día.',
    category: 'salud',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5, 6, 7],
    reminderTime: '08:00',
    currentStreak: 14,
    bestStreak: 22,
    isAIGenerated: true,
    createdAt: daysAgo(58),
    // 92% completion últimos 60 días
    logsPattern: (i) => realisticPattern(i, 0.92),
    logsDaysBack: 60,
  },
  {
    id: 'habit_meditacion',
    groupId: 'group_bienestar',
    title: 'Meditación 10 min',
    description: 'Sesión de mindfulness para empezar el día con calma.',
    category: 'bienestar',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5, 6, 7],
    reminderTime: '07:30',
    currentStreak: 7,
    bestStreak: 18,
    isAIGenerated: true,
    createdAt: daysAgo(58),
    logsPattern: (i) => realisticPattern(i, 0.78),
    logsDaysBack: 60,
  },
  {
    id: 'habit_ejercicio',
    groupId: 'group_bienestar',
    title: 'Ejercicio 30 min',
    description: 'Rutina de entrenamiento funcional o cardio.',
    category: 'salud',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5],
    reminderTime: '07:00',
    currentStreak: 21,
    bestStreak: 21,
    isAIGenerated: true,
    createdAt: daysAgo(58),
    logsPattern: (i) => realisticPattern(i, 0.95),
    logsDaysBack: 60,
  },
  {
    id: 'habit_lectura',
    groupId: 'group_productividad',
    title: 'Leer 20 páginas',
    description: 'Hábito de lectura diaria para ampliar conocimiento.',
    category: 'aprendizaje',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5, 6, 7],
    reminderTime: '21:00',
    currentStreak: 12,
    bestStreak: 26,
    isAIGenerated: true,
    createdAt: daysAgo(45),
    logsPattern: (i) => realisticPattern(i, 0.85),
    logsDaysBack: 45,
  },
  {
    id: 'habit_codigo',
    groupId: 'group_productividad',
    title: 'Repasar código 30 min',
    description: 'Practicar algoritmos y repasar apuntes del ciclo.',
    category: 'productividad',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5],
    reminderTime: '19:00',
    currentStreak: 9,
    bestStreak: 15,
    isAIGenerated: true,
    createdAt: daysAgo(45),
    logsPattern: (i) => realisticPattern(i, 0.88),
    logsDaysBack: 45,
  },
  {
    id: 'habit_ingles',
    groupId: 'group_productividad',
    title: 'Duolingo 15 min',
    description: 'Práctica de inglés para mejorar el vocabulario técnico.',
    category: 'aprendizaje',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5, 6, 7],
    reminderTime: '20:30',
    currentStreak: 5,
    bestStreak: 11,
    isAIGenerated: false,
    createdAt: daysAgo(30),
    logsPattern: (i) => realisticPattern(i, 0.75),
    logsDaysBack: 30,
  },
  {
    id: 'habit_finanzas',
    title: 'Revisar gastos del día',
    description: 'Anotar en qué gasté dinero para mantener el presupuesto.',
    category: 'finanzas',
    frequency: 'daily',
    targetDays: [1, 2, 3, 4, 5, 6, 7],
    reminderTime: '22:00',
    currentStreak: 3,
    bestStreak: 9,
    isAIGenerated: false,
    createdAt: daysAgo(20),
    logsPattern: (i) => realisticPattern(i, 0.70),
    logsDaysBack: 20,
  },
  {
    id: 'habit_social',
    title: 'Llamar a un amigo o familiar',
    description: 'Mantener las relaciones personales con una llamada semanal.',
    category: 'social',
    frequency: 'weekly',
    targetDays: [5], // viernes
    reminderTime: '18:00',
    currentStreak: 4,
    bestStreak: 7,
    isAIGenerated: false,
    createdAt: daysAgo(55),
    logsPattern: (i) => realisticPattern(i, 0.90),
    logsDaysBack: 55,
  },
];

const achievements = [
  { type: 'first_habit',       daysAgo: 58, habitId: 'habit_agua' },
  { type: 'ai_plan',           daysAgo: 58, habitId: null },
  { type: 'streak_3',          daysAgo: 55, habitId: 'habit_ejercicio' },
  { type: 'streak_7',          daysAgo: 50, habitId: 'habit_ejercicio' },
  { type: 'streak_14',         daysAgo: 38, habitId: 'habit_ejercicio' },
  { type: 'habits_5',          daysAgo: 44, habitId: null },
  { type: 'total_50',          daysAgo: 35, habitId: null },
  { type: 'total_100',         daysAgo: 18, habitId: null },
  { type: 'all_completed_day', daysAgo: 10, habitId: null },
  { type: 'perfect_week',      daysAgo: 8,  habitId: 'habit_ejercicio' },
];

// --- Escritura en Firestore ---

async function seedData() {
  console.log(`\n🌱 Sembrando datos para UID: ${uid}\n`);
  const userRef = db.collection('users').doc(uid);
  const batch = db.batch();

  // Grupos
  console.log('📁 Creando grupos...');
  for (const group of groups) {
    const ref = userRef.collection('habit_groups').doc(group.id);
    batch.set(ref, group.data);
  }

  // Hábitos
  console.log('✅ Creando hábitos...');
  for (const h of habitDefs) {
    const habitData = {
      title: h.title,
      description: h.description,
      category: h.category,
      frequency: h.frequency,
      targetDays: h.targetDays,
      reminderTime: h.reminderTime,
      currentStreak: h.currentStreak,
      bestStreak: h.bestStreak,
      isAIGenerated: h.isAIGenerated,
      createdAt: adminTimestamp(h.createdAt),
      isActive: true,
      groupId: h.groupId ?? null,
    };
    const habitRef = userRef.collection('habits').doc(h.id);
    batch.set(habitRef, habitData);
  }

  await batch.commit();
  console.log('   Hábitos y grupos guardados ✓');

  // Logs (por lotes separados porque pueden ser muchos)
  console.log('📊 Generando logs...');
  let totalLogs = 0;

  for (const h of habitDefs) {
    const logs = buildLogs(h.targetDays, h.logsDaysBack, h.logsPattern);
    totalLogs += logs.length;

    // Firestore limita 500 ops por batch
    const chunks = [];
    for (let i = 0; i < logs.length; i += 490) {
      chunks.push(logs.slice(i, i + 490));
    }

    for (const chunk of chunks) {
      const logBatch = db.batch();
      for (const log of chunk) {
        const logId = `log_${log.date.toISOString().slice(0, 10)}`;
        const logRef = userRef.collection('habits').doc(h.id).collection('logs').doc(logId);
        logBatch.set(logRef, {
          date: adminTimestamp(log.date),
          completed: log.completed,
          shielded: log.shielded,
        });
      }
      await logBatch.commit();
    }
    console.log(`   ${h.title}: ${logs.length} logs`);
  }

  console.log(`   Total: ${totalLogs} logs ✓`);

  // Logros
  console.log('🏆 Desbloqueando logros...');
  const achievementBatch = db.batch();
  for (const a of achievements) {
    const ref = userRef.collection('achievements').doc(`ach_${a.type}`);
    achievementBatch.set(ref, {
      type: a.type,
      unlockedAt: adminTimestamp(daysAgo(a.daysAgo)),
      habitId: a.habitId,
    });
  }
  await achievementBatch.commit();
  console.log(`   ${achievements.length} logros desbloqueados ✓`);

  console.log('\n✨ ¡Listo! Abre la app y ya tienes datos reales para las capturas.\n');
}

seedData().catch(err => {
  console.error('\n❌ Error:', err.message);
  if (err.code === 7 || err.message.includes('permission')) {
    console.error('\n💡 Prueba ejecutar primero:');
    console.error('   gcloud auth application-default login');
  }
  process.exit(1);
});
