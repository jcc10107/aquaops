import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ops/models/chat_conversation_model.dart';

void main() {
  group('ChatConversationModel Unit Tests', () {
    test('Correctly deserializes from Firestore map', () {
      final map = {
        'type': 'delivery',
        'orderId': 'ORD-987654',
        'customerId': 'cust_abc',
        'customerName': 'Juan Santos',
        'assignedRiderId': 'rider_xyz',
        'assignedRiderName': 'Carlos Rider',
        'status': 'active',
        'customerUnreadCount': 3,
        'staffOrRiderUnreadCount': 0,
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final convo = ChatConversationModel.fromMap(map, 'order_ORD-987654');

      expect(convo.id, 'order_ORD-987654');
      expect(convo.isDelivery, true);
      expect(convo.isSupport, false);
      expect(convo.isReadOnly, false);
      expect(convo.customerUnreadCount, 3);
      expect(convo.assignedRiderName, 'Carlos Rider');
    });

    test('Completed delivery conversation evaluates to read-only', () {
      final map = {
        'type': 'delivery',
        'status': 'completed',
        'customerId': 'cust_abc',
        'customerName': 'Juan Santos',
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final convo = ChatConversationModel.fromMap(map, 'order_ORD-987654');
      expect(convo.isReadOnly, true);
    });

    test('Support ticket evaluates to not read-only regardless of completed', () {
      final map = {
        'type': 'support',
        'status': 'resolved',
        'customerId': 'cust_abc',
        'customerName': 'Juan Santos',
        'createdAt': '2026-11-03T02:00:00.000Z',
      };

      final convo = ChatConversationModel.fromMap(map, 'supp_001');
      expect(convo.isSupport, true);
      expect(convo.isReadOnly, false); // Support conversations can be reopened
    });
  });
}