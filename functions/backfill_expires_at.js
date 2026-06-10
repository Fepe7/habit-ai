/**
 * Backfill del campo TTL `expiresAt` en documentos existentes.
 *
 * Las políticas TTL de Firestore solo purgan documentos que tengan el campo;
 * todo lo escrito antes de implementar la retención necesita este backfill
 * una única vez. Plazos por colección → docs/retencion-datos.md
 *
 * Uso:
 *   node functions/backfill_expires_at.js --keyfile=/ruta/a/key.json [--dry-run]
 *
 * Cómo obtener el keyfile:
 *   Firebase Console → Project Settings → Service accounts → Generate new private key
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
      return eq === -1 ? [a.slice(2), true] : [a.slice(2, eq), a.slice(eq + 1)];
    })
);

const dryRun = args['dry-run'] === true;

// --- Init Firebase Admin ---
let appConfig;
if (args.keyfile) {
  const keyPath = path.resolve(args.keyfile);
  if (!fs.existsSync(keyPath)) {
    console.error(`❌  No encuentro el keyfile: ${keyPath}`);
    process.exit(1);
  }
  appConfig = { credential: admin.credential.cert(require(keyPath)) };
}
admin.initializeApp(appConfig);
const db = admin.firestore();

// Retención por collection group: días de vida desde el campo base.
// baseField = timestamp existente desde el que se calcula la expiración.
const POLICIES = [
  { group: 'ai_conversations', baseField: 'createdAt', days: 30 },
  { group: 'weekly_reviews', baseField: 'generatedAt', days: 56 },
  { group: 'butterfly_projections', baseField: 'generatedAt', days: 90 },
  { group: 'pattern_insights', baseField: 'generatedAt', days: 60 },
  { group: 'renegotiations', baseField: 'generatedAt', days: 30 },
  // Resueltas caducan a los 7 días de la respuesta; pendientes, 90 desde su creación
  { group: 'follow_requests', baseField: 'respondedAt', days: 7, fallbackField: 'createdAt', fallbackDays: 90 },
  // Tokens FCM: 120 días desde la última vez que el dispositivo abrió la app
  { group: 'fcm_tokens', baseField: 'updatedAt', days: 120 },
  { group: 'rate_limits', baseField: null, days: 7 },
];

function addDays(ts, days) {
  return admin.firestore.Timestamp.fromMillis(
    ts.toMillis() + days * 24 * 60 * 60 * 1000
  );
}

async function backfillGroup(policy) {
  const snap = await db.collectionGroup(policy.group).get();
  let updated = 0;
  let skipped = 0;
  const writer = db.bulkWriter();

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.expiresAt) {
      skipped++;
      continue;
    }

    let expiresAt;
    const base = policy.baseField ? data[policy.baseField] : null;
    if (base && base.toMillis) {
      expiresAt = addDays(base, policy.days);
    } else if (policy.fallbackField && data[policy.fallbackField]?.toMillis) {
      expiresAt = addDays(data[policy.fallbackField], policy.fallbackDays);
    } else {
      // Sin timestamp de referencia: cuenta desde hoy para no borrar de golpe
      expiresAt = addDays(admin.firestore.Timestamp.now(), policy.days);
    }

    updated++;
    if (!dryRun) {
      writer.update(doc.ref, { expiresAt });
    }
  }

  await writer.close();
  console.log(
    `${policy.group}: ${snap.size} docs — ${updated} ${dryRun ? 'a actualizar (dry-run)' : 'actualizados'}, ${skipped} ya tenían expiresAt`
  );
}

async function main() {
  console.log(dryRun ? '🔍 DRY RUN — no se escribe nada\n' : '✏️  Backfill en marcha\n');
  for (const policy of POLICIES) {
    await backfillGroup(policy);
  }
  console.log('\n✅ Backfill completado');
}

main().catch((e) => {
  console.error('❌ ', e);
  process.exit(1);
});
