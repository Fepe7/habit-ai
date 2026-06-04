/**
 * Datos de prueba para el mood tracker — múltiples franjas por día.
 *
 * Uso:
 *   node functions/seed_mood.js --uid=TU_UID [--keyfile=/ruta/a/key.json] [--days=30]
 *
 * Flags:
 *   --uid=UID        (obligatorio) UID de Firebase Auth
 *   --keyfile=PATH   (opcional) service account key; si no, usa ADC
 *   --days=N         (opcional, default 30) cuántos días hacia atrás generar
 *   --clear          (opcional) borra los mood_entries existentes antes de sembrar
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ── args ──────────────────────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => {
      const eq = a.indexOf('=');
      return eq === -1 ? [a.slice(2), true] : [a.slice(2, eq), a.slice(eq + 1)];
    })
);

const uid = args.uid;
if (!uid) {
  console.error('❌  Falta --uid=TU_UID');
  process.exit(1);
}

const DAYS_BACK = parseInt(args.days ?? '30', 10);
const CLEAR     = !!args.clear;

// ── Firebase Admin ────────────────────────────────────────────────────────────
if (args.keyfile) {
  const keyPath = path.resolve(args.keyfile);
  if (!fs.existsSync(keyPath)) { console.error(`❌  No encuentro: ${keyPath}`); process.exit(1); }
  admin.initializeApp({ credential: admin.credential.cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
  console.log('🔑 Usando service account key');
} else {
  admin.initializeApp({ projectId: 'habit-ai-184ad' });
  console.log('🔑 Usando Application Default Credentials');
}

const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

// ── Helpers ───────────────────────────────────────────────────────────────────
const todayMidnight = new Date();
todayMidnight.setHours(0, 0, 0, 0);

function daysAgo(n) {
  const d = new Date(todayMidnight);
  d.setDate(d.getDate() - n);
  return d;
}

function ts(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

// pseudo-random reproducible
function prng(seed) {
  return ((seed * 1664525 + 1013904223) & 0xffffffff) / 0xffffffff;
}

// rating base por día — patrón cíclico con todos los niveles representados
const _basePattern = [
  4, 3, 5, 2, 4, 3, 1, 4, 5, 3,
  2, 4, 3, 5, 2, 3, 4, 1, 5, 4,
  3, 2, 5, 4, 3, 1, 4, 5, 2, 3,
  4, 5, 3, 2, 4, 1, 3, 5, 4, 2,
];
function baseRating(dayIdx) {
  return _basePattern[dayIdx % _basePattern.length];
}

// cada franja varía ±1 respecto al rating base del día (40% chance)
function blockRating(base, blockSeed) {
  const r = prng(blockSeed);
  if (r < 0.20 && base > 1) return base - 1;
  if (r < 0.30 && base > 2) return base - 2;
  if (r > 0.80 && base < 5) return base + 1;
  if (r > 0.90 && base < 4) return base + 2;
  return base;
}

// labels correlacionados con el rating
const negLabels = ['anxiety', 'tiredness', 'stress', 'sadness', 'anger'];
const posLabels = ['motivation', 'calm', 'energy', 'gratitude', 'focus'];

function labelsFor(rating, seed) {
  const pool = rating <= 2 ? negLabels : rating >= 4 ? posLabels : [];
  if (pool.length === 0) return [];
  const count = prng(seed) < 0.4 ? 2 : 1;
  const shuffled = [...pool].sort((_, __) => prng(seed * 3 + pool.indexOf(_)) - 0.5);
  return shuffled.slice(0, count);
}

const sampleNotes = [
  'Empezando el día con energía.',
  'Un poco cansado pero bien.',
  'Reunión intensa, necesito descansar.',
  'Buen día, todo fluye.',
  'Estrés acumulado de la semana.',
  'Me siento tranquilo y enfocado.',
  'Tarde productiva, contento con el avance.',
  'Noche relajada, leyendo antes de dormir.',
  'Muchas cosas en la cabeza hoy.',
  'Muy bien, superé mis metas del día.',
];

function maybeNote(seed) {
  if (prng(seed) > 0.28) return null; // solo 28% tienen nota
  return sampleNotes[Math.floor(prng(seed * 11) * sampleNotes.length)];
}

// horarios realistas por franja
const blockHours = {
  morning:   { min: 7,  max: 11 },
  midday:    { min: 12, max: 14 },
  afternoon: { min: 16, max: 20 },
  night:     { min: 21, max: 23 },
};

function blockTimestamp(dayDate, block, seed) {
  const { min, max } = blockHours[block];
  const hour   = min + Math.floor(prng(seed)         * (max - min + 1));
  const minute = Math.floor(prng(seed * 17 + 5)      * 60);
  const d = new Date(dayDate);
  d.setHours(hour, minute, 0, 0);
  return d;
}

// qué franjas registrar cada día (siempre mañana y tarde, a veces más)
function blocksForDay(dayIdx) {
  const r = prng(dayIdx * 13 + 7);
  if (r < 0.15)  return ['morning'];
  if (r < 0.40)  return ['morning', 'afternoon'];
  if (r < 0.65)  return ['morning', 'afternoon', 'night'];
  if (r < 0.80)  return ['morning', 'midday', 'afternoon'];
  return ['morning', 'midday', 'afternoon', 'night'];
}

// ── Generación de entradas ────────────────────────────────────────────────────
function generateEntries() {
  const entries = [];

  for (let i = DAYS_BACK; i >= 0; i--) {
    const dayDate = daysAgo(i);
    // no generar entradas para el futuro ni para hoy (el usuario las mete a mano)
    if (i === 0) continue;

    const base = baseRating(i);
    const blocks = blocksForDay(i);

    blocks.forEach((block, bi) => {
      const seed = i * 100 + bi * 10;
      const rating = blockRating(base, seed + 1);
      entries.push({
        id: `mood_${dayDate.toISOString().slice(0, 10)}_${block}`,
        data: {
          rating,
          labels: labelsFor(rating, seed + 2),
          note: maybeNote(seed + 3),
          timeBlock: block,
          timestamp: ts(blockTimestamp(dayDate, block, seed + 4)),
          habitsCompletedSnapshot: [],
        },
      });
    });
  }

  return entries;
}

// ── Escritura ─────────────────────────────────────────────────────────────────
async function seedMood() {
  console.log(`\n😊 Sembrando mood entries para UID: ${uid}`);
  console.log(`   Días: ${DAYS_BACK} | Borrar previos: ${CLEAR}\n`);

  const moodRef = db.collection('users').doc(uid).collection('mood_entries');

  if (CLEAR) {
    console.log('🗑️  Borrando entradas existentes...');
    const existing = await moodRef.get();
    const deleteBatch = db.batch();
    existing.docs.forEach(doc => deleteBatch.delete(doc.ref));
    await deleteBatch.commit();
    console.log(`   Borradas ${existing.size} entradas ✓`);
  }

  const entries = generateEntries();
  console.log(`📝 Generando ${entries.length} entradas (${DAYS_BACK} días, varias franjas por día)...`);

  // Firestore: máx 500 ops por batch
  const chunks = [];
  for (let i = 0; i < entries.length; i += 490) {
    chunks.push(entries.slice(i, i + 490));
  }

  for (const chunk of chunks) {
    const batch = db.batch();
    for (const entry of chunk) {
      batch.set(moodRef.doc(entry.id), entry.data);
    }
    await batch.commit();
  }

  // resumen por rating
  const dist = [0, 0, 0, 0, 0];
  entries.forEach(e => dist[e.data.rating - 1]++);
  console.log('\n📊 Distribución de ratings:');
  ['😞','😕','😐','🙂','😄'].forEach((e, i) =>
    console.log(`   ${e} ${i + 1}: ${dist[i]} entradas`)
  );

  console.log(`\n✨ ¡Listo! ${entries.length} mood entries creadas.\n`);
}

seedMood().catch(err => {
  console.error('\n❌ Error:', err.message);
  if (err.code === 7 || err.message?.includes('permission')) {
    console.error('💡  Prueba: gcloud auth application-default login');
  }
  process.exit(1);
});
