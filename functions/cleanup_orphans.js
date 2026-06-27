/**
 * Limpieza única de datos huérfanos dejados por cuentas borradas ANTES de que
 * `deleteAccount` limpiara el espejo público y los retos (fix 2026-06-27).
 *
 * Un dato es huérfano si su usuario (users/{uid}) ya no existe:
 *   - public_profiles/{uid} + subcolecciones (habits, challenges, reactions)
 *     → se BORRAN (datos exclusivos del usuario, liberan espacio).
 *   - challenges con status pending/active donde algún participante ya no existe
 *     → se marcan ABANDONED (son duales, no se borran; el compañero lo ve cerrado).
 *
 * Uso:
 *   node functions/cleanup_orphans.js --keyfile=/ruta/a/key.json --dry-run   # ver qué haría
 *   node functions/cleanup_orphans.js --keyfile=/ruta/a/key.json             # ejecutar
 *
 * Keyfile: Firebase Console → Project Settings → Service accounts → Generate new private key
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const args = Object.fromEntries(
  process.argv.slice(2)
    .filter((a) => a.startsWith('--'))
    .map((a) => {
      const eq = a.indexOf('=');
      return eq === -1 ? [a.slice(2), true] : [a.slice(2, eq), a.slice(eq + 1)];
    })
);

const dryRun = args['dry-run'] === true;

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

// Cache de existencia de usuarios para no repetir lecturas del mismo uid.
const _userCache = new Map();
async function userExists(uid) {
  if (_userCache.has(uid)) return _userCache.get(uid);
  const doc = await db.collection('users').doc(uid).get();
  _userCache.set(uid, doc.exists);
  return doc.exists;
}

async function cleanupPublicProfiles() {
  const profiles = await db.collection('public_profiles').get();
  let orphans = 0;
  let deletedDocs = 0;
  for (const p of profiles.docs) {
    if (await userExists(p.id)) continue;
    orphans++;
    if (!dryRun) {
      for (const sub of ['habits', 'challenges', 'reactions']) {
        const docs = await p.ref.collection(sub).get();
        for (const d of docs.docs) {
          await d.ref.delete();
          deletedDocs++;
        }
      }
      await p.ref.delete();
      deletedDocs++;
    }
  }
  console.log(
    `public_profiles: ${profiles.size} total — ${orphans} huérfanos ` +
    `${dryRun ? 'a borrar (dry-run)' : `borrados (${deletedDocs} docs eliminados)`}`
  );
}

async function cleanupChallenges() {
  const snap = await db
    .collection('challenges')
    .where('status', 'in', ['pending', 'active'])
    .get();
  let toAbandon = 0;
  for (const c of snap.docs) {
    const uids = c.data().participantUids || [];
    let anyDeleted = false;
    for (const u of uids) {
      if (!(await userExists(u))) {
        anyDeleted = true;
        break;
      }
    }
    if (anyDeleted) {
      toAbandon++;
      if (!dryRun) await c.ref.update({ status: 'abandoned' });
    }
  }
  console.log(
    `challenges vivos con participante borrado: ${toAbandon} ` +
    `${dryRun ? 'a marcar abandoned (dry-run)' : 'marcados abandoned'}`
  );
}

async function main() {
  console.log(dryRun ? '🔍 DRY RUN — no se escribe nada\n' : '✏️  Limpieza en marcha\n');
  await cleanupPublicProfiles();
  await cleanupChallenges();
  console.log('\n✅ Limpieza completada');
}

main().catch((e) => {
  console.error('❌ ', e);
  process.exit(1);
});
