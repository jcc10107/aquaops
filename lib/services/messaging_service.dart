import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _colConversations = 'conversations';
  static const String _subColMessages = 'messages';

  // ── Conversation Streams ──────────────────────────────────────────

  /// Stream conversations visible to the authenticated user based on role
  Stream<List<ChatConversationModel>> watchConversations({
    required String userId,
    required UserRole role,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(_colConversations);

    switch (role) {
      case UserRole.customer:
        query = query.where('customerId', isEqualTo: userId);
        break;
      case UserRole.rider:
        query = query
            .where('type', isEqualTo: ConversationType.delivery.name)
            .where('assignedRiderId', isEqualTo: userId);
        break;
      case UserRole.staff:
      case UserRole.owner:
      // Staff and Owners can view all conversations or support queue
        break;
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatConversationModel.fromFirestore(doc))
          .toList();
      // Sort in-memory to prevent missing composite index exceptions
      list.sort((a, b) {
        final timeA = a.lastMessageAt ?? a.createdAt;
        final timeB = b.lastMessageAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });
      return list;
    });
  }

  /// Stream total unread conversations count for the header badge
  Stream<int> watchUnreadConversationsCount({
    required String userId,
    required UserRole role,
  }) {
    return watchConversations(userId: userId, role: role).map((convos) {
      if (role == UserRole.customer) {
        return convos.where((c) => c.customerUnreadCount > 0).length;
      } else {
        return convos.where((c) => c.staffOrRiderUnreadCount > 0).length;
      }
    });
  }

  /// Stream real-time messages for a specific conversation
  Stream<List<ChatMessageModel>> watchMessages(
      String conversationId, {
        int limit = 100,
      }) {
    return _db
        .collection(_colConversations)
        .doc(conversationId)
        .collection(_subColMessages)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList());
  }

  // ── Delivery Conversations ────────────────────────────────────────

  /// Get or create a delivery conversation linked directly to an Order
  Future<ChatConversationModel> getOrCreateDeliveryConversation({
    required OrderModel order,
  }) async {
    final convId = 'order_${order.id}';
    final docRef = _db.collection(_colConversations).doc(convId);
    final snap = await docRef.get();

    final isDelivered = order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;

    if (snap.exists) {
      final existing = ChatConversationModel.fromFirestore(snap);
      // If delivery completed in the background, sync read-only status
      if (isDelivered && existing.status != ConversationStatus.completed) {
        await docRef.update({'status': ConversationStatus.completed.name});
        return existing;
      }
      // If rider assignment changed, update it
      if (order.assignedRiderId != null &&
          existing.assignedRiderId != order.assignedRiderId) {
        await docRef.update({
          'assignedRiderId': order.assignedRiderId,
          'assignedRiderName': order.assignedRiderName,
        });
      }
      return existing;
    }

    final newConvo = ChatConversationModel(
      id: convId,
      type: ConversationType.delivery,
      orderId: order.id,
      customerId: order.customerId ?? '',
      customerName: order.customerName,
      assignedRiderId: order.assignedRiderId,
      assignedRiderName: order.assignedRiderName,
      status: isDelivered
          ? ConversationStatus.completed
          : ConversationStatus.active,
      createdAt: DateTime.now(),
    );

    await docRef.set(newConvo.toMap());

    // Post initial system message
    await _postSystemMessage(
      convId,
      'Delivery chat opened for order #${order.orderNumber}.',
    );

    return newConvo;
  }

  /// Lock delivery chat when order is fulfilled
  Future<void> lockDeliveryConversationAsCompleted(String orderId) async {
    final convId = 'order_$orderId';
    final docRef = _db.collection(_colConversations).doc(convId);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.update({'status': ConversationStatus.completed.name});
      await _postSystemMessage(
        convId,
        'This delivery has been completed. This conversation is now read-only history.',
      );
    }
  }

  // ── Support Conversations ─────────────────────────────────────────

  /// Create or reopen a customer support conversation
  Future<ChatConversationModel> createOrReopenSupportConversation({
    required String customerId,
    required String customerName,
    String? topic,
    String? orderId,
  }) async {
    // Check if an open support ticket already exists for this customer
    final existingSnap = await _db
        .collection(_colConversations)
        .where('customerId', isEqualTo: customerId)
        .where('type', isEqualTo: ConversationType.support.name)
        .where('status', whereIn: [
      ConversationStatus.open.name,
      ConversationStatus.waitingCustomer.name,
    ])
        .limit(1)
        .get();

    if (existingSnap.docs.isNotEmpty) {
      return ChatConversationModel.fromFirestore(existingSnap.docs.first);
    }

    final docRef = _db.collection(_colConversations).doc();
    final newConvo = ChatConversationModel(
      id: docRef.id,
      type: ConversationType.support,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      status: ConversationStatus.open,
      supportTopic: topic ?? 'General Inquiries',
      createdAt: DateTime.now(),
    );

    await docRef.set(newConvo.toMap());

    await _postSystemMessage(
      docRef.id,
      'Support request opened: "${topic ?? 'General Inquiries'}". A dispatch agent will be with you shortly.',
    );

    return newConvo;
  }

  /// Reopen an existing resolved support conversation
  Future<void> reopenSupportConversation(String conversationId) async {
    final docRef = _db.collection(_colConversations).doc(conversationId);
    await docRef.update({
      'status': ConversationStatus.open.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _postSystemMessage(
      conversationId,
      'This support conversation was reopened by the customer.',
    );
  }

  /// Assign support agent (Staff/Owner only)
  Future<void> assignSupportAgent({
    required String conversationId,
    required String staffId,
    required String staffName,
  }) async {
    await _db.collection(_colConversations).doc(conversationId).update({
      'assignedStaffId': staffId,
      'assignedStaffName': staffName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update support status (e.g. resolve or waiting on customer)
  Future<void> updateSupportStatus({
    required String conversationId,
    required ConversationStatus newStatus,
  }) async {
    await _db.collection(_colConversations).doc(conversationId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus == ConversationStatus.resolved) {
      await _postSystemMessage(
        conversationId,
        'This support ticket has been resolved by dispatch.',
      );
    }
  }

  // ── Send & Read Operations ────────────────────────────────────────

  /// Send a chat message
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String senderId,
    required String senderName,
    required String senderRole, // 'customer' | 'rider' | 'staff' | 'owner'
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final convRef = _db.collection(_colConversations).doc(conversationId);
    final convSnap = await convRef.get();
    if (!convSnap.exists) throw StateError('Conversation not found.');

    final convData = convSnap.data()!;
    final type = ConversationType.fromString(convData['type'] as String?);
    final status = ConversationStatus.fromString(convData['status'] as String?);

    // Rule: Delivery chat locked to read-only once order is completed
    if (type == ConversationType.delivery &&
        status == ConversationStatus.completed) {
      throw StateError(
        'This delivery is completed. New messages cannot be sent. Please contact support.',
      );
    }

    final batch = _db.batch();

    // 1. Add message document to subcollection
    final msgRef = convRef.collection(_subColMessages).doc();
    final message = ChatMessageModel(
      id: msgRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: cleanText,
      type: ChatMessageType.text,
      createdAt: DateTime.now(),
    );

    batch.set(msgRef, message.toMap());

    // 2. Update conversation parent document atomically
    final isCustomer = senderRole == 'customer';
    final updates = <String, dynamic>{
      'lastMessageText': cleanText,
      'lastMessageSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (isCustomer)
        'staffOrRiderUnreadCount': FieldValue.increment(1)
      else
        'customerUnreadCount': FieldValue.increment(1),
    };

    // If customer replies to a waiting support ticket, move to open
    if (type == ConversationType.support &&
        status == ConversationStatus.waitingCustomer &&
        isCustomer) {
      updates['status'] = ConversationStatus.open.name;
    }

    batch.update(convRef, updates);

    await batch.commit();
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required bool isCustomer,
  }) async {
    final convRef = _db.collection(_colConversations).doc(conversationId);
    if (isCustomer) {
      await convRef.update({'customerUnreadCount': 0});
    } else {
      await convRef.update({'staffOrRiderUnreadCount': 0});
    }
  }

  // ── Helper ────────────────────────────────────────────────────────

  Future<void> _postSystemMessage(String convId, String text) async {
    final msgRef = _db
        .collection(_colConversations)
        .doc(convId)
        .collection(_subColMessages)
        .doc();

    final sysMsg = ChatMessageModel(
      id: msgRef.id,
      conversationId: convId,
      senderId: 'system',
      senderName: 'System',
      senderRole: 'system',
      text: text,
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    );

    await msgRef.set(sysMsg.toMap());
  }
}