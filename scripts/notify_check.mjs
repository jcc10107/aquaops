// scripts/notify_check.mjs
//
// Scheduled notification check, run every 15 min by
// .github/workflows/notify.yml (this project has no Cloud Functions, so
// GitHub Actions stands in for a server-side trigger). Looks for:
//   - pending orders with no assigned rider, created 10+ min ago
//   - inventory items at/below their minimumThreshold
// and sends a push (via FCM) to every owner/staff account with a saved
// fcmToken, once per item — tracked with a notified flag on the document so
// the same thing isn't re-sent every run. The low-stock flag is cleared by
// restockItem() in firestore_service.dart so a future dip notifies again.
//
// Needs these env vars (see .github/workflows/notify.yml):
//   FIREBASE_API_KEY        - Web API key (same as firebase_options.dart)
//   BACKUP_ACCOUNT_EMAIL    - an owner account, used to read/patch Firestore
//   BACKUP_ACCOUNT_PASSWORD
//   FCM_SERVICE_ACCOUNT_KEY - full JSON of a Firebase service account key,
//                             used only to authenticate FCM sends
//
// Run manually with: node scripts/notify_check.mjs

import { createSign } from 'node:crypto';

const PROJECT_ID = 'aquaops-e8dd1';
const API_KEY = process.env.FIREBASE_API_KEY;
const EMAIL = process.env.BACKUP_ACCOUNT_EMAIL;
const PASSWORD = process.env.BACKUP_ACCOUNT_PASSWORD;
const SERVICE_ACCOUNT = JSON.parse(process.env.FCM_SERVICE_ACCOUNT_KEY ?? '{}');

if (!API_KEY || !EMAIL || !PASSWORD || !SERVICE_ACCOUNT.private_key) {
  console.error('Set FIREBASE_API_KEY, BACKUP_ACCOUNT_EMAIL, BACKUP_ACCOUNT_PASSWORD, and FCM_SERVICE_ACCOUNT_KEY first.');
  process.exit(1);
}

function base64url(input) {
  const buf = typeof input === 'string' ? Buffer.from(input) : input;
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// Google's service-account JWT bearer flow: sign a short-lived claim set
// with the service account's private key, trade it for an OAuth access
// token scoped to Firebase Cloud Messaging.
async function getFcmAccessToken() {
  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: SERVICE_ACCOUNT.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = createSign('RSA-SHA256').update(unsigned).sign(SERVICE_ACCOUNT.private_key);
  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`OAuth token request failed: ${JSON.stringify(data)}`);
  return data.access_token;
}

async function signInIdToken() {
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD, returnSecureToken: true }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`Sign-in failed: ${JSON.stringify(data)}`);
  return data.idToken;
}

function firestoreUrl(path) {
  return `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`;
}

async function listDocuments(idToken, path) {
  const docs = [];
  let pageToken;
  do {
    const url = new URL(firestoreUrl(path));
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const res = await fetch(url, { headers: { Authorization: `Bearer ${idToken}` } });
    const data = await res.json();
    if (!res.ok) throw new Error(`Failed to list ${path}: ${JSON.stringify(data)}`);
    for (const doc of data.documents ?? []) docs.push(doc);
    pageToken = data.nextPageToken;
  } while (pageToken);
  return docs;
}

function field(doc, name) {
  const f = doc.fields?.[name];
  if (!f) return undefined;
  if ('stringValue' in f) return f.stringValue;
  if ('integerValue' in f) return parseInt(f.integerValue, 10);
  if ('doubleValue' in f) return f.doubleValue;
  if ('booleanValue' in f) return f.booleanValue;
  if ('timestampValue' in f) return new Date(f.timestampValue);
  if ('nullValue' in f) return null;
  return undefined;
}

function docId(doc) {
  return doc.name.split('/').pop();
}

async function markNotified(idToken, path, fieldName) {
  const res = await fetch(`${firestoreUrl(path)}?updateMask.fieldPaths=${fieldName}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: { [fieldName]: { booleanValue: true } } }),
  });
  if (!res.ok) throw new Error(`Failed to patch ${path}: ${JSON.stringify(await res.json())}`);
}

async function sendPush(accessToken, token, title, body) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: { token, notification: { title, body } } }),
  });
  if (!res.ok) {
    console.error(`Push to ${token.slice(0, 12)}... failed: ${JSON.stringify(await res.json())}`);
  }
}

async function main() {
  const [idToken, accessToken] = await Promise.all([signInIdToken(), getFcmAccessToken()]);

  const [users, orders, inventory] = await Promise.all([
    listDocuments(idToken, 'users'),
    listDocuments(idToken, 'orders'),
    listDocuments(idToken, 'inventory'),
  ]);

  const recipients = users
    .filter((u) => ['owner', 'staff'].includes(field(u, 'role')) && field(u, 'fcmToken'))
    .map((u) => field(u, 'fcmToken'));

  if (recipients.length === 0) {
    console.log('No owner/staff devices registered for push yet. Nothing to do.');
    return;
  }

  const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000);
  const unassigned = orders.filter((o) => {
    const createdAt = field(o, 'createdAt');
    return field(o, 'status') === 'pending'
      && !field(o, 'assignedRiderId')
      && !field(o, 'notifiedUnassigned')
      && createdAt instanceof Date
      && createdAt < tenMinAgo;
  });

  for (const order of unassigned) {
    const title = 'Order needs a rider';
    const body = `${field(order, 'orderNumber')} (${field(order, 'customerName')}) has been waiting 10+ min.`;
    await Promise.all(recipients.map((token) => sendPush(accessToken, token, title, body)));
    await markNotified(idToken, `orders/${docId(order)}`, 'notifiedUnassigned');
    console.log(`Notified: ${title} - ${field(order, 'orderNumber')}`);
  }

  const lowStock = inventory.filter((i) =>
    field(i, 'currentStock') <= field(i, 'minimumThreshold') && !field(i, 'notifiedLowStock')
  );

  for (const item of lowStock) {
    const title = 'Low stock alert';
    const body = `${field(item, 'name')} is at ${field(item, 'currentStock')} ${field(item, 'unit')} (min ${field(item, 'minimumThreshold')}).`;
    await Promise.all(recipients.map((token) => sendPush(accessToken, token, title, body)));
    await markNotified(idToken, `inventory/${docId(item)}`, 'notifiedLowStock');
    console.log(`Notified: ${title} - ${field(item, 'name')}`);
  }

  if (unassigned.length === 0 && lowStock.length === 0) {
    console.log('Nothing to notify.');
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
