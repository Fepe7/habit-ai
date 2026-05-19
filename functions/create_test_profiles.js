/**
 * Crea perfiles de prueba en Firebase Auth + Firestore.
 *
 * Uso:
 *   node functions/create_test_profiles.js [--keyfile=/ruta/a/key.json]
 *
 * Sin --keyfile usa Application Default Credentials:
 *   gcloud auth application-default login
 *
 * Crea 3 usuarios:
 *   alice@test.com   (pública)   — para probar follow directo
 *   bob@test.com     (privada)   — para probar solicitud de seguimiento
 *   carol@test.com   (privada)   — tercera cuenta para más escenarios
 *
 * Contraseña de todos: Test1234!
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- Args ---
const args = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => {
      const eq = a.indexOf('=');
      return [a.slice(2, eq), a.slice(eq + 1)];
    })
);

if (args.keyfile) {
  const keyPath = path.resolve(args.keyfile);
  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  console.log('🔑 Usando service account key');
} else {
  admin.initializeApp({ projectId: 'habit-ai-184ad' });
  console.log('🔑 Usando Application Default Credentials');
}

const auth = admin.auth();
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

const TEST_PASSWORD = 'Test1234!';

const profiles = [
  {
    email: 'alice@test.com',
    displayName: 'Alice Test',
    username: 'alice_test',
    bio: 'Cuenta pública de prueba',
    isProfilePublic: true,   // follow directo
    habitVisibility: 'public',
  },
  {
    email: 'bob@test.com',
    displayName: 'Bob Test',
    username: 'bob_test',
    bio: 'Cuenta privada de prueba',
    isProfilePublic: false,  // requiere solicitud
    habitVisibility: 'followers',
  },
  {
    email: 'carol@test.com',
    displayName: 'Carol Test',
    username: 'carol_test',
    bio: 'Otra cuenta privada',
    isProfilePublic: false,
    habitVisibility: 'followers',
  },
];

async function upsertAuthUser(profile) {
  try {
    const existing = await auth.getUserByEmail(profile.email);
    console.log(`   ♻️  ${profile.email} ya existe (uid: ${existing.uid})`);
    return existing.uid;
  } catch (_) {
    const user = await auth.createUser({
      email: profile.email,
      password: TEST_PASSWORD,
      displayName: profile.displayName,
    });
    console.log(`   ✅ ${profile.email} creado (uid: ${user.uid})`);
    return user.uid;
  }
}

async function writeFirestoreDocs(uid, profile) {
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();

  // /users/{uid}
  batch.set(db.collection('users').doc(uid), {
    email: profile.email,
    displayName: profile.displayName,
    username: profile.username,
    bio: profile.bio,
    photoURL: null,
    createdAt: now,
    onboardingCompleted: true,
    goals: ['Mejorar productividad', 'Estar más sano'],
    preferences: {},
    isProfilePublic: profile.isProfilePublic,
    followersCount: 0,
    followingCount: 0,
    habitVisibility: profile.habitVisibility,
  }, { merge: true });

  // /user_directory/{uid}
  batch.set(db.collection('user_directory').doc(uid), {
    username: profile.username,
    displayName: profile.displayName,
    photoUrl: null,
    challengePrivacy: 'everyone',
    profileVisibility: 'everyone',
    createdAt: now,
    isProfilePublic: profile.isProfilePublic,
    showStats: true,
    showHabits: true,
    showAchievements: true,
    showFollowerCount: true,
  }, { merge: true });

  // /usernames/{username}
  batch.set(db.collection('usernames').doc(profile.username), { uid });

  await batch.commit();
  console.log(`      Firestore docs escritos ✓`);
}

async function run() {
  console.log('\n👤 Creando perfiles de prueba...\n');

  for (const profile of profiles) {
    console.log(`→ ${profile.displayName} (${profile.isProfilePublic ? 'pública' : 'privada'})`);
    const uid = await upsertAuthUser(profile);
    await writeFirestoreDocs(uid, profile);
  }

  console.log('\n📋 Resumen:');
  console.log('   Email              | Contraseña  | Tipo');
  console.log('   -------------------|-------------|----------');
  for (const p of profiles) {
    const tipo = p.isProfilePublic ? 'pública   ' : 'privada   ';
    console.log(`   ${p.email.padEnd(19)}| ${TEST_PASSWORD}  | ${tipo} (@${p.username})`);
  }
  console.log('\n✨ Listo. Inicia sesión con cualquiera de estas cuentas en la app.\n');
}

run().catch(err => {
  console.error('\n❌ Error:', err.message);
  if (err.code === 7 || err.message?.includes('permission')) {
    console.error('\n💡 Prueba:  gcloud auth application-default login');
  }
  process.exit(1);
});
