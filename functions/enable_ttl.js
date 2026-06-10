/**
 * Activa las políticas TTL de Firestore sobre el campo `expiresAt`.
 *
 * Equivale a `gcloud firestore fields ttls update ...` pero vía API REST,
 * para no depender de tener gcloud instalado. Idempotente: re-ejecutarlo
 * sobre políticas ya activas no hace nada.
 *
 * Uso:
 *   node functions/enable_ttl.js --keyfile=/ruta/a/key.json
 *
 * Cómo obtener el keyfile:
 *   Firebase Console → Project Settings → Service accounts → Generate new private key
 */

const { GoogleAuth } = require('google-auth-library');
const fs = require('fs');
const path = require('path');

const args = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => {
      const eq = a.indexOf('=');
      return eq === -1 ? [a.slice(2), true] : [a.slice(2, eq), a.slice(eq + 1)];
    })
);

if (!args.keyfile) {
  console.error('❌  Falta --keyfile=/ruta/a/key.json');
  process.exit(1);
}
const keyPath = path.resolve(args.keyfile);
if (!fs.existsSync(keyPath)) {
  console.error(`❌  No encuentro el keyfile: ${keyPath}`);
  process.exit(1);
}

const key = require(keyPath);
const projectId = key.project_id;

// Collection groups con retención automática (plazos → docs/retencion-datos.md)
const COLLECTION_GROUPS = [
  'ai_conversations',
  'weekly_reviews',
  'butterfly_projections',
  'pattern_insights',
  'renegotiations',
  'follow_requests',
  'fcm_tokens',
  'rate_limits',
];

async function main() {
  const auth = new GoogleAuth({
    keyFile: keyPath,
    scopes: ['https://www.googleapis.com/auth/datastore'],
  });
  const client = await auth.getClient();

  console.log(`Proyecto: ${projectId}\n`);

  for (const cg of COLLECTION_GROUPS) {
    const url =
      `https://firestore.googleapis.com/v1/projects/${projectId}` +
      `/databases/(default)/collectionGroups/${cg}/fields/expiresAt` +
      `?updateMask=ttlConfig`;

    try {
      await client.request({
        url,
        method: 'PATCH',
        data: { ttlConfig: {} },
      });
      console.log(`✅ ${cg}: política TTL solicitada (tarda unos minutos en activarse)`);
    } catch (e) {
      console.error(`❌ ${cg}: ${e.response?.data?.error?.message || e.message}`);
    }
  }

  console.log(
    '\nVerificar estado: Firebase Console → Firestore → pestaña TTL,' +
    '\no Cloud Console → Firestore → Time-to-live.'
  );
}

main().catch((e) => {
  console.error('❌ ', e);
  process.exit(1);
});
