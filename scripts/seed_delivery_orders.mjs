// scripts/seed_delivery_orders.mjs
//
// One-time setup script: creates a few sample "out for delivery" orders so the
// Delivery Queue screen has real Firestore data to test against (area filter
// tabs, drop-off completion, etc). Walk-in POS sales don't produce these —
// only a real customer-ordering flow would — so until that screen exists,
// this script fills the gap the same way seed_inventory.mjs did for Inventory.
//
// Signs in as owner@aquaops.com (created by seed_users.mjs) since Firestore
// rules require an authenticated user to create an order.
// Run with: node scripts/seed_delivery_orders.mjs

const API_KEY = 'AIzaSyBIKVc-siDJBmseHauc9h1Bd43vxh2ZaZI'; // Web API key from lib/firebase_options.dart
const PROJECT_ID = 'aquaops-e8dd1';
const OWNER_EMAIL = 'owner@aquaops.com';
const OWNER_PASSWORD = 'password123';

const ORDERS = [
  {
    customerName: 'Juan dela Cruz',
    customerPhone: '+63 917 555 0101',
    deliveryAddress: 'Block 4 Lot 12, Dahlia St., Barangay San Antonio',
    areaZone: 'sa',
    items: [{ name: '5-Gal Round Refill', quantity: 2, unitPrice: 35, requiresPackaging: true }],
    totalAmount: 70,
    paymentMethod: 'cash',
  },
  {
    customerName: 'Rosario Mercado',
    customerPhone: '+63 917 555 0102',
    deliveryAddress: '15 Sampaguita Ave., Barangay San Antonio',
    areaZone: 'sa',
    items: [{ name: '5-Gal Slim Alkaline Refill', quantity: 3, unitPrice: 50, requiresPackaging: true }],
    totalAmount: 150,
    paymentMethod: 'gcash',
  },
  {
    customerName: 'Maria Santos',
    customerPhone: '+63 917 555 0103',
    deliveryAddress: 'Purok 3, Barangay San Isidro',
    areaZone: 'si',
    items: [{ name: 'New Bottle + Water (5-Gal)', quantity: 1, unitPrice: 250, requiresPackaging: true }],
    totalAmount: 250,
    paymentMethod: 'cash',
  },
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

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'number') return { doubleValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object') {
    return { mapValue: { fields: toFirestoreFields(value) } };
  }
  return { stringValue: String(value) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === undefined) continue;
    fields[key] = toFirestoreValue(value);
  }
  return fields;
}

async function createOrder(idToken, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/orders`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields: toFirestoreFields(data) }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body.error?.message || 'Firestore create failed');
  return body.name.split('/').pop(); // extract the generated doc id
}

async function setOrderNumber(idToken, docId, orderNumber) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/orders/${docId}?updateMask.fieldPaths=orderNumber`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields: { orderNumber: { stringValue: orderNumber } } }),
  });
  if (!res.ok) {
    const body = await res.json();
    throw new Error(body.error?.message || 'Firestore update failed');
  }
}

async function main() {
  const { idToken } = await signIn(OWNER_EMAIL, OWNER_PASSWORD);

  for (const order of ORDERS) {
    try {
      const docId = await createOrder(idToken, {
        ...order,
        status: 'outForDelivery',
        isPaid: false,
        createdAt: new Date().toISOString(),
      });
      const orderNumber = `DEL-${docId.substring(0, 6).toUpperCase()}`;
      await setOrderNumber(idToken, docId, orderNumber);
      console.log(`Seeded: ${orderNumber} (${order.customerName}, ${order.areaZone})`);
    } catch (err) {
      console.error(`Failed to seed order for ${order.customerName}:`, err.message);
    }
  }
  console.log('\nDone.');
}

main();
