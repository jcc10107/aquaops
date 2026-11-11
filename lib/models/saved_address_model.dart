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
  // Precise pin-on-map coordinates, captured when the address was saved —
  // null only for addresses saved before this existed. When present, a
  // selected saved address can be routed exactly instead of relying on
  // geocoding the typed text, which can resolve to the wrong place for an
  // ambiguous or duplicate street/landmark name.
  final double? latitude;
  final double? longitude;

  SavedAddressModel({
    required this.id,
    required this.label,
    required this.addressText,
    this.note,
    this.contactName,
    this.phone,
    this.isPrimary = false,
    this.createdAt,
    this.latitude,
    this.longitude,
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
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
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
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}