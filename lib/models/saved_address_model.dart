import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddressModel {
  final String id;
  final String label;
  final String addressText;
  final String? note;
  final DateTime? createdAt;

  SavedAddressModel({
    required this.id,
    required this.label,
    required this.addressText,
    this.note,
    this.createdAt,
  });

  factory SavedAddressModel.fromMap(Map<String, dynamic> data, String id) {
    return SavedAddressModel(
      id: id,
      label: data['label'] ?? 'Address',
      addressText: data['addressText'] ?? '',
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'addressText': addressText,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
