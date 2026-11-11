import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// FCM's own codes for "this token will never work again" — distinct from a
// transient failure (network blip, quota, etc.), which should just be
// logged and retried on the next event rather than wiping the user's token.
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

type PushPayload = {
  notification: { title: string; body: string };
  data?: Record<string, string>;
};

// Shared by every trigger in this file: sends to one user's saved FCM
// token, and — only on a dead-token error, never a transient one — clears
// it so a future trigger doesn't keep failing against the same dead token
// forever. Logs just enough to diagnose (eventId, recipient uid, error
// code), never the token itself or notification body text.
async function sendPushToUser(uid: string, payload: PushPayload, eventId: string) {
  const userRef = admin.firestore().collection('users').doc(uid);
  const userDoc = await userRef.get();
  const token = userDoc.data()?.fcmToken;
  if (!token) return;
  try {
    await admin.messaging().send({ token, ...payload });
  } catch (error) {
    const code = (error as { code?: string }).code ?? 'unknown';
    console.error(`[${eventId}] push to uid ${uid} failed: ${code}`);
    if (DEAD_TOKEN_CODES.has(code)) {
      await userRef.update({ fcmToken: admin.firestore.FieldValue.delete() });
    }
  }
}

// Shared by every trigger that needs to reach "whoever is working the
// counter right now" rather than one specific person (new orders,
// unassigned support tickets, cash-out/emergency requests).
async function sendPushToDispatchQueue(payload: PushPayload, eventId: string) {
  const staffSnap = await admin
    .firestore()
    .collection('users')
    .where('role', 'in', ['staff', 'owner'])
    .get();
  await Promise.all(staffSnap.docs.map((doc) => sendPushToUser(doc.id, payload, eventId)));
}

export const onNewChatMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    if (!message) return null;

    // Do NOT send push notifications for internal staff notes or system logs
    if (message.type === 'internalNote' || message.type === 'system') {
      return null;
    }

    const { conversationId } = context.params;
    const convDoc = await admin.firestore().collection('conversations').doc(conversationId).get();
    const convData = convDoc.data();
    if (!convData) return null;

    const senderId = message.senderId;
    let recipientId: string | null = null;
    // Unassigned support tickets have no single recipient yet — the whole
    // dispatch queue gets notified instead (see below). Everything else
    // (delivery chats, and support chats that already have an assigned
    // agent) notifies exactly one recipient.
    let notifyDispatchQueue = false;

    if (convData.type === 'delivery') {
      // In delivery chats: sender customer -> notifies assigned rider; sender rider -> notifies customer
      recipientId = senderId === convData.customerId ? convData.assignedRiderId : convData.customerId;
    } else if (senderId === convData.customerId && !convData.assignedStaffId) {
      // A customer's message on a brand-new, unassigned support ticket —
      // nobody is responsible for it yet, so notify every staff/owner
      // account instead of silently dropping the notification.
      notifyDispatchQueue = true;
    } else {
      // In support chats: sender customer -> notifies assigned staff; sender staff -> notifies customer
      recipientId = senderId === convData.customerId ? convData.assignedStaffId : convData.customerId;
    }

    const payload: PushPayload = {
      notification: {
        title: message.senderName || 'Aqua Ops Message',
        body: message.text,
      },
      data: {
        conversationId: conversationId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };
    const eventId = `chat:${context.params.messageId}`;

    if (notifyDispatchQueue) {
      await sendPushToDispatchQueue(payload, eventId);
      return null;
    }

    if (!recipientId || recipientId === senderId) return null;
    await sendPushToUser(recipientId, payload, eventId);
    return null;
  });

export const onNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    if (!order) return null;
    // POS/walk-in sales are rung up by staff themselves — no one to notify.
    if (order.orderSource === 'pos') return null;

    await sendPushToDispatchQueue(
      {
        notification: {
          title: 'New order placed',
          body: `${order.orderNumber ?? 'An order'} from ${order.customerName ?? 'a customer'} needs processing.`,
        },
        data: { orderId: context.params.orderId, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      },
      `order-new:${context.params.orderId}`,
    );
    return null;
  });

// Status values worth telling the customer about, and the message for each.
// 'pending' and 'refilling' are internal prep states the customer doesn't
// need a push for; 'cancelled' is covered here too since whoever cancelled
// it (staff or the customer themselves) isn't necessarily the one reading
// the app on another device — Firestore triggers can't tell us who made
// the write, so this may occasionally notify the person who cancelled
// their own order. Accepted trade-off noted here rather than hidden.
const CUSTOMER_STATUS_MESSAGES: Record<string, string> = {
  outForDelivery: 'is out for delivery!',
  delivered: 'has been delivered. Thank you for choosing Aqua Ops!',
  cancelled: 'has been cancelled.',
};

export const onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after || before.status === after.status) return null;

    const message = CUSTOMER_STATUS_MESSAGES[after.status];
    if (!message || !after.customerId) return null;

    await sendPushToUser(
      after.customerId,
      {
        notification: {
          title: 'Order update',
          body: `Your order ${after.orderNumber ?? ''} ${message}`,
        },
        data: { orderId: context.params.orderId, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      },
      `order-status:${context.params.orderId}:${after.status}`,
    );
    return null;
  });