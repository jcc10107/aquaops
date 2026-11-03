import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ops/models/chat_conversation_model.dart';
import 'package:aqua_ops/models/chat_message_model.dart';

void main() {
  group('Messaging Models Round-trip Tests', () {
    test('ChatConversationModel parses correctly from map', () {
      final map = {
        'type': 'delivery',
        'orderId': 'ORD-1234',
        'customerId': 'cust_01',
        'customerName': 'Juan Santos',
        'status': 'active',
        'customerUnreadCount': 2,
        'staffOrRiderUnreadCount': 0,
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final convo = ChatConversationModel.fromMap(map, 'conv_01');

      expect(convo.id, 'conv_01');
      expect(convo.isDelivery, true);
      expect(convo.isReadOnly, false);
      expect(convo.customerUnreadCount, 2);
    });

    test('Completed delivery conversation evaluates to read-only', () {
      final map = {
        'type': 'delivery',
        'status': 'completed',
        'customerId': 'cust_01',
        'customerName': 'Juan Santos',
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final convo = ChatConversationModel.fromMap(map, 'conv_02');
      expect(convo.isReadOnly, true);
    });

    test('ChatMessageModel identifies internal notes', () {
      final map = {
        'conversationId': 'conv_03',
        'senderId': 'staff_01',
        'senderName': 'Agent Mark',
        'senderRole': 'staff',
        'text': 'Internal: check container inventory',
        'type': 'internalNote',
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final msg = ChatMessageModel.fromMap(map, 'msg_01');
      expect(msg.isInternalNote, true);
      expect(msg.isSystem, false);
    });
  });
}