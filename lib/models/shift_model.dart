import 'package:cloud_firestore/cloud_firestore.dart';

enum ShiftStatus { open, closed }

class ShiftModel {
  final String id;
  final String openedByName;
  final double openingCash;
  final DateTime openedAt;
  final ShiftStatus status;
  final String? closedByName;
  final double? closingCash;
  final double? expectedCash;
  final double? discrepancy;
  final DateTime? closedAt;

  ShiftModel({
    required this.id,
    required this.openedByName,
    required this.openingCash,
    required this.openedAt,
    required this.status,
    this.closedByName,
    this.closingCash,
    this.expectedCash,
    this.discrepancy,
    this.closedAt,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> data, String id) {
    final openedAtRaw = data['openedAt'];
    final closedAtRaw = data['closedAt'];
    return ShiftModel(
      id: id,
      openedByName: data['openedByName'] ?? '',
      openingCash: (data['openingCash'] ?? 0).toDouble(),
      openedAt: openedAtRaw is Timestamp ? openedAtRaw.toDate() : DateTime.now(),
      status: data['status'] == 'closed' ? ShiftStatus.closed : ShiftStatus.open,
      closedByName: data['closedByName'],
      closingCash: (data['closingCash'] as num?)?.toDouble(),
      expectedCash: (data['expectedCash'] as num?)?.toDouble(),
      discrepancy: (data['discrepancy'] as num?)?.toDouble(),
      closedAt: closedAtRaw is Timestamp ? closedAtRaw.toDate() : null,
    );
  }
}
