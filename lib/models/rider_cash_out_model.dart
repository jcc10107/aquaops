import 'package:cloud_firestore/cloud_firestore.dart';

class RiderCashOutModel {
  final String id;
  final String riderId;
  final String riderName;
  final int stopsCompleted;
  final int gallonsDelivered;
  final int emptiesReturned;
  final double cashCollected;
  final double gcashCollected;
  final double cashHandedOver;
  final double discrepancy;
  final String verifiedByName;
  final DateTime closedAt;

  RiderCashOutModel({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.stopsCompleted,
    required this.gallonsDelivered,
    required this.emptiesReturned,
    required this.cashCollected,
    required this.gcashCollected,
    required this.cashHandedOver,
    required this.discrepancy,
    required this.verifiedByName,
    required this.closedAt,
  });

  factory RiderCashOutModel.fromMap(Map<String, dynamic> data, String id) {
    final closedAtRaw = data['closedAt'];
    return RiderCashOutModel(
      id: id,
      riderId: data['riderId'] ?? '',
      riderName: data['riderName'] ?? '',
      stopsCompleted: (data['stopsCompleted'] ?? 0).toInt(),
      gallonsDelivered: (data['gallonsDelivered'] ?? 0).toInt(),
      emptiesReturned: (data['emptiesReturned'] ?? 0).toInt(),
      cashCollected: (data['cashCollected'] ?? 0).toDouble(),
      gcashCollected: (data['gcashCollected'] ?? 0).toDouble(),
      cashHandedOver: (data['cashHandedOver'] ?? 0).toDouble(),
      discrepancy: (data['discrepancy'] ?? 0).toDouble(),
      verifiedByName: data['verifiedByName'] ?? '',
      closedAt: closedAtRaw is Timestamp ? closedAtRaw.toDate() : DateTime.now(),
    );
  }
}
