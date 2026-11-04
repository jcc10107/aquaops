// scripts/notify_check.mjs
//
// Scheduled notification check, run every 15 min by
// .github/workflows/notify.yml (this project has no deployed Cloud
// Functions — Blaze plan billing wasn't worth it for a student project —
// so GitHub Actions stands in as the server-side trigger instead). Looks
// for:
//   - pending orders with no assigned rider, created 10+ min ago
//   - inventory items at/below their minimumThreshold
//   - brand-new orders that haven't been announced to staff/owner yet
//   - meaningful order status changes (out for delivery / delivered /
//     cancelled) the customer hasn't been told about yet
//   - new chat messages (conversations/*/messages) that haven't been
//     pushed to their recipient yet
// and sends a push (via FCM) to the right recipient(s), once per event —
// tracked with a notified flag on the relevant document so the same thing
// isn't re-sent every run. The low-stock flag is cleared by
// restockItem() in firestore_service.dart so a future dip notifies again.
//
// This is a polling stand-in for functions/src/index.ts's real-time
// triggers (onNewChatMessage, onNewOrder, onOrderStatusChange) — same
// recipient logic, but checked every 15 min instead of instantly. If this
// project ever upgrades to Blaze and deploys those functions, this
// script's chat/order sections become redundant (harmless to run both —
// each marks its own notified flags — but there's no reason to keep this
// paying for the same notifications twice).
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

// Collection-group query — every 'messages' subcollection doc across every
// conversation, in one call, instead of listing conversations first and
// then fetching each one's messages separately.
async function listCollectionGroup(idToken, collectionId) {
  const docs = [];
  let res = await fetch(`${firestoreUrl('')}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId, allDescendants: true }],
      },
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`Failed to query ${collectionId}: ${JSON.stringify(data)}`);
  for (const row of data) {
    if (row.document) docs.push(row.document);
  }
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

// The id of the conversation a 'messages' collection-group doc belongs to
// — parsed out of its full resource path
// (.../documents/conversations/{conversationId}/messages/{messageId}).
function parentConversationId(messageDoc) {
  const parts = messageDoc.name.split('/');
  const idx = parts.indexOf('conversations');
  return idx >= 0 ? parts[idx + 1] : undefined;
}

function toFirestoreValue(value) {
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'string') return { stringValue: value };
  throw new Error(`Unsupported value type for Firestore patch: ${typeof value}`);
}

async function patchField(idToken, path, fieldName, value) {
  const res = await fetch(`${firestoreUrl(path)}?updateMask.fieldPaths=${fieldName}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: { [fieldName]: toFirestoreValue(value) } }),
  });
  if (!res.ok) throw new Error(`Failed to patch ${path}: ${JSON.stringify(await res.json())}`);
}

async function sendPush(accessToken, token, title, body, data) {
  const message = { token, notification: { title, body } };
  if (data) message.data = data;
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message }),
  });
  if (!res.ok) {
    console.error(`Push to ${token.slice(0, 12)}... failed: ${JSON.stringify(await res.json())}`);
    return false;
  }
  return true;
}

async function main() {
  const [idToken, accessToken] = await Promise.all([signInIdToken(), getFcmAccessToken()]);

  const [users, orders, inventory, messages] = await Promise.all([
    listDocuments(idToken, 'users'),
    listDocuments(idToken, 'orders'),
    listDocuments(idToken, 'inventory'),
    listCollectionGroup(idToken, 'messages'),
  ]);
  // Needed to resolve each message's recipient — read once, reused below.
  const conversations = await listDocuments(idToken, 'conversations');
  const conversationById = new Map(conversations.map((c) => [docId(c), c]));
  const userById = new Map(users.map((u) => [docId(u), u]));

  const dispatchTokens = users
    .filter((u) => ['owner', 'staff'].includes(field(u, 'role')) && field(u, 'fcmToken'))
    .map((u) => field(u, 'fcmToken'));

  async function pushToDispatchQueue(title, body, data) {
    if (dispatchTokens.length === 0) return false;
    const results = await Promise.all(dispatchTokens.map((token) => sendPush(accessToken, token, title, body, data)));
    return results.some(Boolean);
  }

  async function pushToUid(uid, title, body, data) {
    const token = field(userById.get(uid), 'fcmToken');
    if (!token) return false;
    return sendPush(accessToken, token, title, body, data);
  }

  if (dispatchTokens.length === 0) {
    console.log('No owner/staff devices registered for push yet — order/inventory alerts will be skipped this run.');
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
    if (!(await pushToDispatchQueue(title, body))) {
      console.error(`Skipping markNotified for ${field(order, 'orderNumber')} - every push failed, will retry next run.`);
      continue;
    }
    await patchField(idToken, `orders/${docId(order)}`, 'notifiedUnassigned', true);
    console.log(`Notified: ${title} - ${field(order, 'orderNumber')}`);
  }

  const lowStock = inventory.filter((i) =>
    field(i, 'currentStock') <= field(i, 'minimumThreshold') && !field(i, 'notifiedLowStock')
  );

  for (const item of lowStock) {
    const title = 'Low stock alert';
    const body = `${field(item, 'name')} is at ${field(item, 'currentStock')} ${field(item, 'unit')} (min ${field(item, 'minimumThreshold')}).`;
    if (!(await pushToDispatchQueue(title, body))) {
      console.error(`Skipping markNotified for ${field(item, 'name')} - every push failed, will retry next run.`);
      continue;
    }
    await patchField(idToken, `inventory/${docId(item)}`, 'notifiedLowStock', true);
    console.log(`Notified: ${title} - ${field(item, 'name')}`);
  }

  // New orders — announce to the dispatch queue immediately (separate from
  // the 10-min "still unassigned" escalation above). POS/walk-in sales are
  // rung up by staff themselves, so there's no one to tell.
  const newOrders = orders.filter((o) =>
    !field(o, 'notifiedNewOrder') && field(o, 'orderSource') !== 'pos'
  );
  for (const order of newOrders) {
    const title = 'New order placed';
    const body = `${field(order, 'orderNumber') ?? 'An order'} from ${field(order, 'customerName') ?? 'a customer'} needs processing.`;
    if (!(await pushToDispatchQueue(title, body, { orderId: docId(order) }))) {
      console.error(`Skipping markNotified for new order ${field(order, 'orderNumber')} - every push failed, will retry next run.`);
      continue;
    }
    await patchField(idToken, `orders/${docId(order)}`, 'notifiedNewOrder', true);
    console.log(`Notified: ${title} - ${field(order, 'orderNumber')}`);
  }

  // Order status changes worth telling the customer about. notifiedStatus
  // tracks the last status value already pushed, so this fires again only
  // when the status actually moves to a new one of these.
  const CUSTOMER_STATUS_MESSAGES = {
    outForDelivery: 'is out for delivery!',
    delivered: 'has been delivered. Thank you for choosing Aqua Ops!',
    cancelled: 'has been cancelled.',
  };
  const statusChanges = orders.filter((o) => {
    const status = field(o, 'status');
    return CUSTOMER_STATUS_MESSAGES[status] && field(o, 'notifiedStatus') !== status && field(o, 'customerId');
  });
  for (const order of statusChanges) {
    const status = field(order, 'status');
    const title = 'Order update';
    const body = `Your order ${field(order, 'orderNumber') ?? ''} ${CUSTOMER_STATUS_MESSAGES[status]}`;
    const sent = await pushToUid(field(order, 'customerId'), title, body, { orderId: docId(order) });
    if (!sent) {
      console.error(`Skipping markNotified for order ${field(order, 'orderNumber')} status ${status} - push failed or no token, will retry next run.`);
      continue;
    }
    await patchField(idToken, `orders/${docId(order)}`, 'notifiedStatus', status);
    console.log(`Notified: ${title} - ${field(order, 'orderNumber')} -> ${status}`);
  }

  // New chat messages — same recipient logic as functions/src/index.ts's
  // onNewChatMessage, just polled instead of real-time.
  const newMessages = messages.filter((m) => {
    const type = field(m, 'type');
    return !field(m, 'notified') && type !== 'internalNote' && type !== 'system';
  });
  for (const message of newMessages) {
    const conversationId = parentConversationId(message);
    const conv = conversationById.get(conversationId);
    if (!conv) continue;

    const senderId = field(message, 'senderId');
    const convType = field(conv, 'type');
    const customerId = field(conv, 'customerId');
    const data = { conversationId, click_action: 'FLUTTER_NOTIFICATION_CLICK' };
    const title = field(message, 'senderName') || 'Aqua Ops Message';
    const body = field(message, 'text') || '';

    let sent = false;
    if (convType === 'delivery') {
      const recipientId = senderId === customerId ? field(conv, 'assignedRiderId') : customerId;
      if (recipientId && recipientId !== senderId) sent = await pushToUid(recipientId, title, body, data);
      else sent = true; // nothing to send is not a failure — still mark notified
    } else if (senderId === customerId && !field(conv, 'assignedStaffId')) {
      // Brand-new, unassigned support ticket — nobody owns it yet.
      sent = await pushToDispatchQueue(title, body, data);
    } else {
      const recipientId = senderId === customerId ? field(conv, 'assignedStaffId') : customerId;
      if (recipientId && recipientId !== senderId) sent = await pushToUid(recipientId, title, body, data);
      else sent = true;
    }

    if (!sent) {
      console.error(`Skipping markNotified for message ${docId(message)} in ${conversationId} - push failed, will retry next run.`);
      continue;
    }
    await patchField(idToken, `conversations/${conversationId}/messages/${docId(message)}`, 'notified', true);
    console.log(`Notified: chat message in ${conversationId}`);
  }

  if (
    unassigned.length === 0 && lowStock.length === 0 && newOrders.length === 0
    && statusChanges.length === 0 && newMessages.length === 0
  ) {
    console.log('Nothing to notify.');
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
