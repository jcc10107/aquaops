import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus { pending, approved, rejected, processed }

class RefundModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String reason;
  final String description;
  final String gcashName;
  final String gcashNumber;
  final double amount;
  final String itemsSummary;
  final RefundStatus status;
  final DateTime requestedAt;
  final String? processedByName;
  final DateTime? processedAt;
  final String? rejectionReason;
  // 'refund' | 'redelivery' — which owner resolution an approved claim took.
  final String? resolutionType;
  final String? gcashRefNumber;
  final String? photoUrl;
  final DateTime? redeliveryScheduledAt;

  RefundModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.reason,
    required this.description,
    required this.gcashName,
    required this.gcashNumber,
    this.amount = 0,
    this.itemsSummary = '',
    this.status = RefundStatus.pending,
    required this.requestedAt,
    this.processedByName,
    this.processedAt,
    this.rejectionReason,
    this.resolutionType,
    this.gcashRefNumber,
    this.photoUrl,
    this.redeliveryScheduledAt,
  });

  factory RefundModel.fromMap(Map<String, dynamic> data, String id) {
    return RefundModel(
      id: id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      gcashName: data['gcashName'] ?? '',
      gcashNumber: data['gcashNumber'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      itemsSummary: data['itemsSummary'] ?? '',
      status: RefundStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => RefundStatus.pending,
      ),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedByName: data['processedByName'],
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      resolutionType: data['resolutionType'],
      gcashRefNumber: data['gcashRefNumber'],
      photoUrl: data['photoUrl'],
      redeliveryScheduledAt: (data['redeliveryScheduledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'reason': reason,
      'description': description,
      'gcashName': gcashName,
      'gcashNumber': gcashNumber,
      'amount': amount,
      'itemsSummary': itemsSummary,
      'status': status.name,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }
}
