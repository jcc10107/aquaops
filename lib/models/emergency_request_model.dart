import 'package:cloud_firestore/cloud_firestore.dart';

enum EmergencyRequestStatus {
  pending,
  approved,
  declined,
  resolved,
  cancelled;

  static EmergencyRequestStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return EmergencyRequestStatus.approved;
      case 'declined':
        return EmergencyRequestStatus.declined;
      case 'resolved':
        return EmergencyRequestStatus.resolved;
      case 'cancelled':
        return EmergencyRequestStatus.cancelled;
      case 'pending':
      default:
        return EmergencyRequestStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case EmergencyRequestStatus.pending:
        return 'Pending Review';
      case EmergencyRequestStatus.approved:
        return 'Approved';
      case EmergencyRequestStatus.declined:
        return 'Declined';
      case EmergencyRequestStatus.resolved:
        return 'Resolved';
      case EmergencyRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class EmergencyRequestModel {
  final String id;
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final List<String> affectedOrderIds;
  final String reason;
  final String? description;
  final EmergencyRequestStatus status;
  final String? declineReason;
  final String? replacementRiderId;
  final String? replacementRiderName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const EmergencyRequestModel({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderPhone,
    required this.affectedOrderIds,
    required this.reason,
    this.description,
    this.status = EmergencyRequestStatus.pending,
    this.declineReason,
    this.replacementRiderId,
    this.replacementRiderName,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory EmergencyRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return EmergencyRequestModel(
      id: doc.id,
      riderId: data['riderId'] as String? ?? '',
      riderName: data['riderName'] as String? ?? 'Unknown Rider',
      riderPhone: data['riderPhone'] as String?,
      affectedOrderIds: (data['affectedOrderIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          const <String>[],
      reason: data['reason'] as String? ?? 'Emergency',
      description: data['description'] as String?,
      status: EmergencyRequestStatus.fromString(data['status'] as String?),
      declineReason: data['declineReason'] as String?,
      replacementRiderId: data['replacementRiderId'] as String?,
      replacementRiderName: data['replacementRiderName'] as String?,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseTimestamp(data['updatedAt']) : null,
      resolvedAt: data['resolvedAt'] != null ? parseTimestamp(data['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      if (riderPhone != null) 'riderPhone': riderPhone,
      'affectedOrderIds': affectedOrderIds,
      'reason': reason,
      if (description != null) 'description': description,
      'status': status.name,
      if (declineReason != null) 'declineReason': declineReason,
      if (replacementRiderId != null) 'replacementRiderId': replacementRiderId,
      if (replacementRiderName != null) 'replacementRiderName': replacementRiderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    };
  }

  EmergencyRequestModel copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? riderPhone,
    List<String>? affectedOrderIds,
    String? reason,
    String? description,
    EmergencyRequestStatus? status,
    String? declineReason,
    String? replacementRiderId,
    String? replacementRiderName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return EmergencyRequestModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      affectedOrderIds: affectedOrderIds ?? this.affectedOrderIds,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      replacementRiderId: replacementRiderId ?? this.replacementRiderId,
      replacementRiderName: replacementRiderName ?? this.replacementRiderName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}