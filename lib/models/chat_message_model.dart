import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType {
  text,
  system,
  internalNote;

  static ChatMessageType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'system':
        return ChatMessageType.system;
      case 'internalnote':
      case 'internal_note':
        return ChatMessageType.internalNote;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' | 'rider' | 'staff' | 'owner' | 'system'
  final String text;
  final ChatMessageType type;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.type = ChatMessageType.text,
    required this.createdAt,
  });

  bool get isSystem => type == ChatMessageType.system;
  bool get isInternalNote => type == ChatMessageType.internalNote;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel.fromMap(data, doc.id);
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessageModel(
      id: id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'customer',
      text: data['text'] as String? ?? '',
      type: ChatMessageType.fromString(data['type'] as String?),
      createdAt: parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}