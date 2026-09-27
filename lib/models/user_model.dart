enum UserRole { owner, staff, rider, customer }

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
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name == (data['role'] ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
      phone: data['phone'] ?? '',
      address: data['address'],
      assignedArea: data['assignedArea'],
      unreturnedContainers: data['unreturnedContainers'] ?? 0,
      activeDepositAmount: (data['activeDepositAmount'] ?? 0).toDouble(),
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
    };
  }
}
