// scripts/seed_inventory.mjs
//
// One-time setup script: creates the 4 starting inventory items shown on the
// Owner/Staff Inventory screen, using fixed doc IDs (inv_water_round,
// inv_water_slim, inv_pkg_caps, inv_pkg_seals) — the last two IDs are the
// same ones FirestoreService.fulfillDelivery() decrements automatically.
//
// Signs in as the owner@aquaops.com demo account (created by seed_users.mjs)
// since Firestore rules only allow owner/staff to write to `inventory`.
// Run with: node scripts/seed_inventory.mjs

const API_KEY = process.env.FIREBASE_API_KEY;
if (!API_KEY) {
  console.error('Set FIREBASE_API_KEY first (the Web API key from the Firebase console).');
  process.exit(1);
}
const PROJECT_ID = 'aquaops-e8dd1';
const OWNER_EMAIL = 'owner@aquaops.com';
const OWNER_PASSWORD = 'password123';

const INVENTORY_ITEMS = [
  { id: 'inv_water_round', sku: 'WTR-RND-001', name: '5-Gal Round Purified Water', category: 'water', currentStock: 145, maxCapacity: 200, unit: 'Gal', minimumThreshold: 30, costPerUnit: 25 },
  { id: 'inv_water_slim', sku: 'WTR-SLM-002', name: '5-Gal Slim Alkaline Water', category: 'water', currentStock: 82, maxCapacity: 150, unit: 'Gal', minimumThreshold: 20, costPerUnit: 35 },
  { id: 'inv_pkg_caps', sku: 'PKG-CAP-001', name: 'Non-Spill Blue Gallon Caps', category: 'packaging', currentStock: 24, maxCapacity: 500, unit: 'pcs', minimumThreshold: 50, costPerUnit: 2 },
  { id: 'inv_pkg_seals', sku: 'PKG-SEL-002', name: 'Tamper-Proof Shrink Seals', category: 'packaging', currentStock: 190, maxCapacity: 300, unit: 'pcs', minimumThreshold: 50, costPerUnit: 1.5 },
];

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

async function writeInventoryDoc(idToken, id, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/inventory/${id}`;
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

async function main() {
  const { idToken } = await signIn(OWNER_EMAIL, OWNER_PASSWORD);

  for (const { id, ...data } of INVENTORY_ITEMS) {
    try {
      await writeInventoryDoc(idToken, id, data);
      console.log(`Seeded: ${id} (${data.name})`);
    } catch (err) {
      console.error(`Failed to seed ${id}:`, err.message);
    }
  }
  console.log('\nDone.');
}

main();
