// scripts/seed_users.mjs
//
// One-time setup script: creates the 4 demo accounts (owner/staff/rider/customer)
// used by the login screen's "DEMO ROLES" pills, both in Firebase Auth and as
// matching role documents in Firestore's `users` collection.
//
// Uses the public Identity Toolkit REST API (keyed by the app's own Web API key,
// same key that ships inside firebase_options.dart) so no service-account file
// is needed. Run with: node scripts/seed_users.mjs

const API_KEY = process.env.FIREBASE_API_KEY;
if (!API_KEY) {
  console.error('Set FIREBASE_API_KEY first (the Web API key from the Firebase console).');
  process.exit(1);
}
const PROJECT_ID = 'aquaops-e8dd1';
const PASSWORD = 'password123';

const DEMO_USERS = [
  { role: 'owner', name: 'Juan Dela Cruz', phone: '+63 917 000 0001' },
  { role: 'staff', name: 'Arnel Bautista', phone: '+63 917 000 0002' },
  { role: 'rider', name: 'Jun Soriano', phone: '+63 917 000 0003', assignedArea: 'Zone A' },
  { role: 'customer', name: 'Elena Gomez', phone: '+63 917 000 0004', address: 'Barangay San Isidro, San Pablo City' },
];

async function signUp(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'signUp failed');
  return data; // { idToken, localId, ... }
}

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'signIn failed');
  return data;
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === undefined || value === null) continue;
    if (typeof value === 'number') fields[key] = { doubleValue: value };
    else fields[key] = { stringValue: String(value) };
  }
  return fields;
}

async function writeUserDoc(idToken, uid, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields: toFirestoreFields(data) }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body.error?.message || 'Firestore write failed');
}

// Firestore rules only let a signed-in user create their own doc as a
// customer; staff/rider docs must be written by an existing owner, so
// `writerToken` (the owner's token) is used for those. The owner doc itself
// must already exist (create it once by hand in the console on a fresh project).
async function seedOne(demo, writerToken) {
  const email = `${demo.role}@aquaops.com`;
  let idToken, uid, created;

  try {
    const signUpResult = await signUp(email, PASSWORD);
    idToken = signUpResult.idToken;
    uid = signUpResult.localId;
    created = true;
  } catch (err) {
    if (String(err.message).includes('EMAIL_EXISTS')) {
      const signInResult = await signIn(email, PASSWORD);
      idToken = signInResult.idToken;
      uid = signInResult.localId;
      created = false;
    } else {
      throw err;
    }
  }

  const useOwner = (demo.role === 'staff' || demo.role === 'rider') && writerToken;
  await writeUserDoc(useOwner ? writerToken : idToken, uid, {
    name: demo.name,
    email,
    role: demo.role,
    phone: demo.phone,
    address: demo.address,
    assignedArea: demo.assignedArea,
    unreturnedContainers: 0,
    activeDepositAmount: 0,
  });

  console.log(`${created ? 'Created' : 'Updated'}: ${email} (uid: ${uid}, role: ${demo.role})`);
  return idToken;
}

async function main() {
  let ownerToken;
  for (const demo of DEMO_USERS) {
    try {
      const token = await seedOne(demo, ownerToken);
      if (demo.role === 'owner') ownerToken = token;
    } catch (err) {
      console.error(`Failed to seed ${demo.role}@aquaops.com:`, err.message);
    }
  }
  console.log('\nDone. All demo accounts use password: ' + PASSWORD);
}

main();
