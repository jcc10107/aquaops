import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

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

    if (convData.type === 'delivery') {
      // In delivery chats: sender customer -> notifies assigned rider; sender rider -> notifies customer
      recipientId = senderId === convData.customerId ? convData.assignedRiderId : convData.customerId;
    } else {
      // In support chats: sender customer -> notifies assigned staff; sender staff -> notifies customer
      recipientId = senderId === convData.customerId ? convData.assignedStaffId : convData.customerId;
    }

    if (!recipientId || recipientId === senderId) return null;

    // Retrieve recipient's FCM token from users collection
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return null;

    const payload: admin.messaging.Message = {
      token: token,
      notification: {
        title: message.senderName || 'Aqua Ops Message',
        body: message.text,
      },
      data: {
        conversationId: conversationId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    try {
      await admin.messaging().send(payload);
    } catch (error) {
      console.error('Failed to send FCM chat notification:', error);
    }

    return null;
  });