import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, refilling, outForDelivery, delivered, cancelled }
enum PaymentMethod { cash, gcash }

class OrderItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final bool requiresPackaging;
  // Maps this line item straight to its Firestore inventory doc id (e.g.
  // 'inv_water_round'), so stock deduction doesn't have to guess from the
  // item's display name. Null for legacy/customer-app items, which fall
  // back to name-matching at deduction time.
  final String? productKey;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.requiresPackaging = true,
    this.productKey,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      requiresPackaging: map['requiresPackaging'] ?? true,
      productKey: map['productKey'],
    );
  }

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'requiresPackaging': requiresPackaging,
    'productKey': productKey,
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
  final String? barangayDisplayName;
  final List<OrderItem> items;
  final double totalAmount;
  // Tracked separately from totalAmount purely for display/reporting
  // transparency — totalAmount already includes this, it's not added on top.
  final double deliveryFee;
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
  // The rider's live GPS position while this order is out for delivery,
  // broadcast periodically by RiderLocationService. Null until the assigned
  // rider's device has sent at least one update (e.g. order not yet out for
  // delivery, or the rider hasn't granted location permission).
  final double? riderLat;
  final double? riderLng;
  final String? lastTransferReason;
  // Who actually collected payment: 'counter' (settled at the register
  // before dispatch) or 'rider' (collected COD at the doorstep). Null for
  // legacy orders — read as 'counter' if the order number starts with
  // 'POS-', otherwise 'rider' (see paymentCollectedByOrDefault).
  final String? paymentCollectedBy;
  // When payment was actually realized — distinct from deliveredAt, since a
  // counter-paid order is settled before the delivery even happens.
  final DateTime? paidAt;
  // Where this order was created: 'customer_app' or 'pos'. Null for legacy
  // orders predating this field.
  final String? orderSource;
  // Set once fulfillDelivery's stock-deduction transaction has actually run
  // for this order — guards against a double-tap deducting inventory twice.
  final DateTime? stockDeductedAt;
  // True if fulfillDelivery had to clamp an inventory decrement at 0
  // because there wasn't enough stock. A dispatcher-facing warning flag —
  // never blocks the rider from completing the delivery.
  final bool stockShortfall;
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
    this.barangayDisplayName,
    required this.items,
    required this.totalAmount,
    this.deliveryFee = 0,
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
    this.riderLat,
    this.riderLng,
    this.lastTransferReason,
    this.paymentCollectedBy,
    this.paidAt,
    this.orderSource,
    this.stockDeductedAt,
    this.stockShortfall = false,
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    final itemsData = (data['items'] as List<dynamic>?) ?? [];
    final createdAtRaw = data['createdAt'];
    final deliveredAtRaw = data['deliveredAt'];

    return OrderModel(
      id: id,
      orderNumber: data['orderNumber'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'],
      areaZone: data['areaZone'] ?? '',
      barangayDisplayName: data['barangayDisplayName'],
      items: itemsData
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
            (s) => s.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
            (p) => p.name == data['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      isPaid: data['isPaid'] ?? false,
      gcashReference: data['gcashReference'],
      assignedRiderId: data['assignedRiderId'],
      assignedRiderName: data['assignedRiderName'],
      gallonsDelivered: (data['gallonsDelivered'] ?? 0).toInt(),
      emptyGallonsReturned: (data['emptyGallonsReturned'] ?? 0).toInt(),
      unreturnedDiff: (data['unreturnedDiff'] ?? 0).toInt(),
      proofOfDeliveryUrl: data['proofOfDeliveryUrl'],
      recipientName: data['recipientName'],
      gcashScreenshotUrl: data['gcashScreenshotUrl'],
      deliveryLat: (data['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (data['deliveryLng'] as num?)?.toDouble(),
      riderLat: (data['riderLat'] as num?)?.toDouble(),
      riderLng: (data['riderLng'] as num?)?.toDouble(),
      lastTransferReason: data['lastTransferReason'],
      paymentCollectedBy: data['paymentCollectedBy'],
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      orderSource: data['orderSource'],
      stockDeductedAt: (data['stockDeductedAt'] as Timestamp?)?.toDate(),
      stockShortfall: data['stockShortfall'] ?? false,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now(),
      deliveredAt: deliveredAtRaw is Timestamp ? deliveredAtRaw.toDate() : null,
    );
  }

  // The moment this order's payment was actually realized: when it was
  // dropped off for deliveries, or immediately at creation for walk-in sales.
  DateTime get revenueDate => deliveredAt ?? createdAt;

  // paidAt if we have it, else the legacy fallback (createdAt) — used by
  // closeShift so a counter-paid order counts in the shift it was actually
  // paid in, not the one it happens to be delivered in.
  DateTime get paidDate => paidAt ?? createdAt;

  // Legacy orders (predating paymentCollectedBy) are read as: a 'POS-'
  // order number means it was settled at the counter, anything else means
  // a rider collected it.
  String get paymentCollectedByOrDefault =>
      paymentCollectedBy ?? (orderNumber.startsWith('POS-') ? 'counter' : 'rider');

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': areaZone,
      'barangayDisplayName': barangayDisplayName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
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
      'paymentCollectedBy': paymentCollectedBy,
      'orderSource': orderSource,
      'stockShortfall': stockShortfall,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Summary numbers for a rider's cash-out, computed the same way whether
// it's a live UI preview (rider_cash_out_modal.dart) or the real close
// (FirestoreService.closeRiderCashOut) — kept as one shared function so the
// two can never drift out of sync again.
class RiderCashOutSummary {
  final int stopsCompleted;
  final int gallonsDelivered;
  final int emptiesReturned;
  final double cashCollected;
  final double gcashCollected;

  const RiderCashOutSummary({
    required this.stopsCompleted,
    required this.gallonsDelivered,
    required this.emptiesReturned,
    required this.cashCollected,
    required this.gcashCollected,
  });
}

RiderCashOutSummary summarizeRiderCashOut(List<OrderModel> orders) {
  // Stops/gallons/empties count every delivery this rider physically made,
  // including counter-paid ones. Cash/GCash totals only count money the
  // RIDER actually collected at the door — a counter-paid order was already
  // settled at the register, so it must not inflate what the rider owes.
  final riderCollected = orders.where((o) => o.paymentCollectedByOrDefault != 'counter');
  return RiderCashOutSummary(
    stopsCompleted: orders.length,
    gallonsDelivered: orders.fold<int>(0, (s, o) => s + o.gallonsDelivered),
    emptiesReturned: orders.fold<int>(0, (s, o) => s + o.emptyGallonsReturned),
    cashCollected: riderCollected
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (s, o) => s + o.totalAmount),
    gcashCollected: riderCollected
        .where((o) => o.paymentMethod == PaymentMethod.gcash)
        .fold<double>(0, (s, o) => s + o.totalAmount),
  );
}