enum UserRole {
  owner,
  staff,
  rider,
  customer;

  /// Helper to safely parse a string into a UserRole.
  /// Defaults to [UserRole.customer] if the string is unrecognized or null.
  static UserRole fromString(String? role) {
    return UserRole.values.firstWhere(
          (r) => r.name == role,
      orElse: () => UserRole.customer,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final String? address;
  final String? assignedArea;
  final int unreturnedContainers;
  final double activeDepositAmount;
  final bool notificationsEnabled;
  final bool? hasOwnContainers;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.address,
    this.assignedArea,
    this.unreturnedContainers = 0,
    this.activeDepositAmount = 0.0,
    this.notificationsEnabled = true,
    this.hasOwnContainers,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      // TASK 5.3: Centralized role parsing using the new helper
      role: UserRole.fromString(data['role'] as String?),
      phone: data['phone'] ?? '',
      address: data['address'],
      assignedArea: data['assignedArea'],
      unreturnedContainers: (data['unreturnedContainers'] as num?)?.toInt() ?? 0,
      activeDepositAmount: (data['activeDepositAmount'] as num?)?.toDouble() ?? 0.0,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      hasOwnContainers: data['hasOwnContainers'],
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'address': address,
      'assignedArea': assignedArea,
      'unreturnedContainers': unreturnedContainers,
      'activeDepositAmount': activeDepositAmount,
      'notificationsEnabled': notificationsEnabled,
      'hasOwnContainers': hasOwnContainers,
      'fcmToken': fcmToken,
    };
  }
}