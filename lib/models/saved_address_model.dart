import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddressModel {
  final String id;
  final String label;
  final String addressText;
  final String? note;
  final String? contactName;
  final String? phone;
  final bool isPrimary;
  final DateTime? createdAt;

  SavedAddressModel({
    required this.id,
    required this.label,
    required this.addressText,
    this.note,
    this.contactName,
    this.phone,
    this.isPrimary = false,
    this.createdAt,
  });

  factory SavedAddressModel.fromMap(Map<String, dynamic> data, String id) {
    return SavedAddressModel(
      id: id,
      label: data['label'] ?? 'Address',
      addressText: data['addressText'] ?? '',
      note: data['note'],
      contactName: data['contactName'],
      phone: data['phone'],
      isPrimary: data['isPrimary'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'addressText': addressText,
      'note': note,
      'contactName': contactName,
      'phone': phone,
      'isPrimary': isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}