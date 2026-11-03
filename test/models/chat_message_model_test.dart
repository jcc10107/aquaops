import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ops/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel Unit Tests', () {
    test('Standard text message parses correctly', () {
      final map = {
        'conversationId': 'conv_123',
        'senderId': 'user_01',
        'senderName': 'Taylor Swift',
        'senderRole': 'customer',
        'text': 'I am at the gate.',
        'type': 'text',
        'createdAt': '2026-11-03T02:30:00.000Z',
      };

      final msg = ChatMessageModel.fromMap(map, 'msg_01');
      expect(msg.id, 'msg_01');
      expect(msg.isSystem, false);
      expect(msg.isInternalNote, false);
      expect(msg.text, 'I am at the gate.');
    });

    test('Internal staff note is identified and flagged', () {
      final map = {
        'conversationId': 'conv_123',
        'senderId': 'staff_01',
        'senderName': 'Dispatch Agent',
        'senderRole': 'staff',
        'text': 'Customer called, request delivery before noon.',
        'type': 'internalNote',
        'createdAt': '2026-11-03T02:31:00.000Z',
      };

      final msg = ChatMessageModel.fromMap(map, 'msg_02');
      expect(msg.isInternalNote, true);
      expect(msg.isSystem, false);
    });

    test('System notification message is identified', () {
      final map = {
        'conversationId': 'conv_123',
        'senderId': 'system',
        'senderName': 'System',
        'senderRole': 'system',
        'text': 'Delivery conversation closed.',
        'type': 'system',
        'createdAt': '2026-11-03T02:32:00.000Z',
      };

      final msg = ChatMessageModel.fromMap(map, 'msg_03');
      expect(msg.isSystem, true);
      expect(msg.isInternalNote, false);
    });
  });
}