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
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final String areaZone;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final String? gcashReference;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final int gallonsDelivered;
  final int emptyGallonsReturned;
  final int unreturnedDiff;
  final String? proofOfDeliveryUrl;
  final String? recipientName;
  final String? gcashScreenshotUrl;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? lastTransferReason;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    required this.areaZone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    this.gcashReference,
    this.assignedRiderId,
    this.assignedRiderName,
    this.gallonsDelivered = 0,
    this.emptyGallonsReturned = 0,
    this.unreturnedDiff = 0,
    this.proofOfDeliveryUrl,
    this.recipientName,
    this.gcashScreenshotUrl,
    this.deliveryLat,
    this.deliveryLng,
    this.lastTransferReason,
    required this.createdAt,
    this.deliveredAt,
  });

  // The moment this order's payment was actually realized: when it was
  // dropped off for deliveries, or immediately at creation for walk-in sales.
  DateTime get revenueDate => deliveredAt ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': areaZone,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'gcashReference': gcashReference,
      'assignedRiderId': assignedRiderId,
      'assignedRiderName': assignedRiderName,
      'gallonsDelivered': gallonsDelivered,
      'emptyGallonsReturned': emptyGallonsReturned,
      'unreturnedDiff': unreturnedDiff,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'recipientName': recipientName,
      'gcashScreenshotUrl': gcashScreenshotUrl,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'lastTransferReason': lastTransferReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
