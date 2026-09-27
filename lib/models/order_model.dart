enum OrderStatus { pending, refilling, outForDelivery, delivered, cancelled }
enum PaymentMethod { cash, gcash }

class OrderItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final bool requiresPackaging;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.requiresPackaging = true,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'requiresPackaging': requiresPackaging,
  };
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final String areaZone;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final int gallonsDelivered;
  final int emptyGallonsReturned;
  final int unreturnedDiff;
  final String? proofOfDeliveryUrl;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    required this.areaZone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    this.assignedRiderId,
    this.assignedRiderName,
    this.gallonsDelivered = 0,
    this.emptyGallonsReturned = 0,
    this.unreturnedDiff = 0,
    this.proofOfDeliveryUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': areaZone,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'assignedRiderId': assignedRiderId,
      'assignedRiderName': assignedRiderName,
      'gallonsDelivered': gallonsDelivered,
      'emptyGallonsReturned': emptyGallonsReturned,
      'unreturnedDiff': unreturnedDiff,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
