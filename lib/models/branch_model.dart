import 'package:cloud_firestore/cloud_firestore.dart';

// A station location. Currently informational only — not yet wired into
// orders/inventory/staff, which still assume a single station. This is the
// groundwork for that future multi-branch expansion.
class BranchModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final DateTime? createdAt;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.createdAt,
  });

  factory BranchModel.fromMap(Map<String, dynamic> data, String id) {
    return BranchModel(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
