import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType {
  delivery,
  support;

  static ConversationType fromString(String? val) {
    return val?.toLowerCase() == 'support'
        ? ConversationType.support
        : ConversationType.delivery;
  }
}

enum ConversationStatus {
  active,
  completed,
  open,
  waitingCustomer,
  resolved;

  static ConversationStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'completed':
        return ConversationStatus.completed;
      case 'open':
        return ConversationStatus.open;
      case 'waitingcustomer':
        return ConversationStatus.waitingCustomer;
      case 'resolved':
        return ConversationStatus.resolved;
      case 'active':
      default:
        return ConversationStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case ConversationStatus.active:
        return 'Active Delivery';
      case ConversationStatus.completed:
        return 'Delivered (Read-Only)';
      case ConversationStatus.open:
        return 'Open Support';
      case ConversationStatus.waitingCustomer:
        return 'Waiting on Customer';
      case ConversationStatus.resolved:
        return 'Resolved';
    }
  }
}

class ChatConversationModel {
  final String id;
  final ConversationType type;
  final String? orderId;
  final String customerId;
  final String customerName;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final ConversationStatus status;
  final String? supportTopic;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int customerUnreadCount;
  final int staffOrRiderUnreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatConversationModel({
    required this.id,
    required this.type,
    this.orderId,
    required this.customerId,
    required this.customerName,
    this.assignedRiderId,
    this.assignedRiderName,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.status,
    this.supportTopic,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.customerUnreadCount = 0,
    this.staffOrRiderUnreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isDelivery => type == ConversationType.delivery;
  bool get isSupport => type == ConversationType.support;
  bool get isReadOnly => isDelivery && status == ConversationStatus.completed;

  factory ChatConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatConversationModel.fromMap(data, doc.id);
  }

  factory ChatConversationModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatConversationModel(
      id: id,
      type: ConversationType.fromString(data['type'] as String?),
      orderId: data['orderId'] as String?,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      assignedRiderId: data['assignedRiderId'] as String?,
      assignedRiderName: data['assignedRiderName'] as String?,
      assignedStaffId: data['assignedStaffId'] as String?,
      assignedStaffName: data['assignedStaffName'] as String?,
      status: ConversationStatus.fromString(data['status'] as String?),
      supportTopic: data['supportTopic'] as String?,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageAt: data['lastMessageAt'] != null
          ? parseTimestamp(data['lastMessageAt'])
          : null,
      customerUnreadCount: (data['customerUnreadCount'] as num?)?.toInt() ?? 0,
      staffOrRiderUnreadCount:
      (data['staffOrRiderUnreadCount'] as num?)?.toInt() ?? 0,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? parseTimestamp(data['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      if (orderId != null) 'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      if (assignedRiderId != null) 'assignedRiderId': assignedRiderId,
      if (assignedRiderName != null) 'assignedRiderName': assignedRiderName,
      if (assignedStaffId != null) 'assignedStaffId': assignedStaffId,
      if (assignedStaffName != null) 'assignedStaffName': assignedStaffName,
      'status': status.name,
      if (supportTopic != null) 'supportTopic': supportTopic,
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSenderId != null)
        'lastMessageSenderId': lastMessageSenderId,
      if (lastMessageAt != null)
        'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      'customerUnreadCount': customerUnreadCount,
      'staffOrRiderUnreadCount': staffOrRiderUnreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}