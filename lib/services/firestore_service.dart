import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/inventory_model.dart';
import '../models/shift_model.dart';
import '../models/rider_cash_out_model.dart';
import '../models/saved_address_model.dart';
import '../models/refund_model.dart';
import '../models/branch_model.dart';
import '../core/constants/zones.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection Constants
  static const String _colInventory = 'inventory';
  static const String _colMaintenanceAlerts = 'maintenance_alerts';
  static const String _colOrders = 'orders';
  static const String _colUsers = 'users';
  static const String _colAddresses = 'addresses';
  static const String _colShifts = 'shifts';
  static const String _colRiderCashouts = 'rider_cashouts';
  static const String _colRefundRequests = 'refund_requests';
  static const String _colSettings = 'settings';
  static const String _colBranches = 'branches';

  // Inventory Document ID Constants
  static const String _invWaterRound = 'inv_water_round';
  static const String _invWaterSlim = 'inv_water_slim';
  static const String _invPkgCaps = 'inv_pkg_caps';
  static const String _invPkgSeals = 'inv_pkg_seals';

  // Settings Document ID Constants
  static const String _docTermsPrivacy = 'terms_privacy';
  static const String _docServiceArea = 'service_area';
  static const String _docDeliveryFee = 'delivery_fee';
  static const String _docGcashAccount = 'gcash_account';

  // Path Helpers
  CollectionReference<Map<String, dynamic>> _userAddressRef(String uid) {
    return _db.collection(_colUsers).doc(uid).collection(_colAddresses);
  }

  // Helper for Order ID Generation
  String _generateOrderNumber(String prefix) {
    final docId = _db.collection(_colOrders).doc().id;
    return '$prefix-${docId.substring(0, 6).toUpperCase()}';
  }

  // Pure Helper for Stock Clamping & Shortfall Calculation
  ({int actualDeduction, bool shortfall}) _calculateStockAdjustment(
      int currentStock,
      int requestedQuantity,
      ) {
    if (requestedQuantity <= 0) {
      return (actualDeduction: 0, shortfall: false);
    }
    final actual = requestedQuantity > currentStock ? currentStock : requestedQuantity;
    final shortfall = actual < requestedQuantity;
    return (actualDeduction: actual, shortfall: shortfall);
  }

  // Stream of all inventory items, ordered by category then name
  Stream<List<InventoryModel>> getInventoryStream() {
    return _db.collection(_colInventory).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => InventoryModel.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        return categoryCompare != 0 ? categoryCompare : a.name.compareTo(b.name);
      });
      return items;
    });
  }

  Future<void> restockItem(String itemId, int quantityToAdd) async {
    await _db.collection(_colInventory).doc(itemId).update({
      'currentStock': FieldValue.increment(quantityToAdd),
      // Clears the low-stock push-notification flag so a future dip below
      // threshold notifies again instead of staying silently suppressed.
      'notifiedLowStock': false,
    });
  }

  // Stream of maintenance/machinery alerts, most urgent & soonest due first.
  Stream<List<MaintenanceAlertModel>> getMaintenanceAlertsStream() {
    return _db.collection(_colMaintenanceAlerts).snapshots().map((snapshot) {
      final alerts = snapshot.docs
          .map((doc) => MaintenanceAlertModel.fromMap(doc.data(), doc.id))
          .toList();
      const urgencyRank = {'critical': 0, 'warning': 1, 'routine': 2};
      alerts.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final urgencyCompare = (urgencyRank[a.urgency] ?? 3).compareTo(urgencyRank[b.urgency] ?? 3);
        return urgencyCompare != 0 ? urgencyCompare : a.dueDate.compareTo(b.dueDate);
      });
      return alerts;
    });
  }

  Future<void> addMaintenanceAlert(MaintenanceAlertModel alert) async {
    await _db.collection(_colMaintenanceAlerts).add(alert.toMap());
  }

  Future<void> setMaintenanceAlertCompleted(String alertId, bool isCompleted) async {
    await _db.collection(_colMaintenanceAlerts).doc(alertId).update({'isCompleted': isCompleted});
  }

  // Records a walk-in POS sale and atomically deducts the water/packaging it consumed.
  Future<String> recordWalkInSale({
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentMethod,
    String? gcashReference,
    int roundGallons = 0,
    int slimGallons = 0,
    int packagingUnits = 0,
  }) async {
    final batch = _db.batch();
    final orderRef = _db.collection(_colOrders).doc();
    final orderNumber = _generateOrderNumber('POS');

    batch.set(orderRef, {
      'orderNumber': orderNumber,
      'customerName': 'Walk-in Customer',
      'customerPhone': '',
      'deliveryAddress': null,
      'areaZone': 'Walk-in / Station 01',
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': 'delivered',
      'paymentMethod': paymentMethod,
      'gcashReference': gcashReference,
      'isPaid': true,
      'orderSource': 'pos',
      'paymentCollectedBy': 'counter',
      'paidAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (roundGallons > 0) {
      batch.update(_db.collection(_colInventory).doc(_invWaterRound), {
        'currentStock': FieldValue.increment(-roundGallons),
      });
    }
    if (slimGallons > 0) {
      batch.update(_db.collection(_colInventory).doc(_invWaterSlim), {
        'currentStock': FieldValue.increment(-slimGallons),
      });
    }
    if (packagingUnits > 0) {
      batch.update(_db.collection(_colInventory).doc(_invPkgCaps), {
        'currentStock': FieldValue.increment(-packagingUnits),
      });
      batch.update(_db.collection(_colInventory).doc(_invPkgSeals), {
        'currentStock': FieldValue.increment(-packagingUnits),
      });
    }

    await batch.commit();
    return orderNumber;
  }

  OrderModel _orderFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _orderFromData(doc.data(), doc.id);
  }

  OrderModel _orderFromData(Map<String, dynamic> data, String id) {
    return OrderModel.fromMap(data, id);
  }

  // Stream of active (not yet delivered/cancelled) orders, newest first.
  Stream<List<OrderModel>> getActiveOrdersStream() {
    return _db.collection(_colOrders).snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map(_orderFromDoc)
          .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Stream of every order, regardless of status — used for revenue/reporting.
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _db.collection(_colOrders).snapshots().map(
          (snapshot) => snapshot.docs.map(_orderFromDoc).toList(),
    );
  }

  // Stream of a single customer's own orders, newest first.
  Stream<List<OrderModel>> getOrdersForCustomerStream(String customerId) {
    return _db
        .collection(_colOrders)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(_orderFromDoc).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Places a customer-initiated delivery order.
  Future<String> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String areaZone,
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentMethod,
    String? gcashReference,
    String? notes,
    String? gcashScreenshotUrl,
    double? deliveryLat,
    double? deliveryLng,
    double deliveryFee = 0,
  }) async {
    final orderRef = _db.collection(_colOrders).doc();
    final orderNumber = _generateOrderNumber('ORD');

    await orderRef.set({
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': areaZone,
      'barangayDisplayName': zoneLabel(areaZone),
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'gcashReference': gcashReference,
      'gcashScreenshotUrl': gcashScreenshotUrl,
      'isPaid': false,
      'notes': notes,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'orderSource': 'customer_app',
      'paymentCollectedBy': 'rider',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderNumber;
  }

  // Places a staff-initiated delivery order from the POS counter — a
  // walk-in customer (possibly a guest with no account) who wants their
  // order delivered instead of handed over on the spot.
  Future<String> placeCounterDeliveryOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String zone,
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentChoice, // 'counter' or 'rider'
    String? paymentMethod, // cash/gcash, only meaningful when paymentChoice == 'counter'
    String? gcashReference,
    double deliveryFee = 0,
  }) async {
    final orderRef = _db.collection(_colOrders).doc();
    final orderNumber = _generateOrderNumber('ORD');
    final bool isCounterPaid = paymentChoice == 'counter';

    await orderRef.set({
      'orderNumber': orderNumber,
      'customerId': '',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': zone,
      'barangayDisplayName': zoneLabel(zone),
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': 'pending',
      'paymentMethod': isCounterPaid ? (paymentMethod ?? 'cash') : 'cash',
      'gcashReference': isCounterPaid ? gcashReference : null,
      'isPaid': isCounterPaid,
      'orderSource': 'pos',
      'paymentCollectedBy': isCounterPaid ? 'counter' : 'rider',
      'paidAt': isCounterPaid ? FieldValue.serverTimestamp() : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderNumber;
  }

  // Cancelling is status-guarded: a delivered order can never be cancelled.
  Future<void> cancelOrder(String orderId) async {
    final orderRef = _db.collection(_colOrders).doc(orderId);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(orderRef);
      if (!snap.exists) return;
      if (snap.data()?['status'] == 'delivered') {
        throw Exception('Delivered orders cannot be cancelled.');
      }
      transaction.update(orderRef, {'status': 'cancelled'});
    });
  }

  // Resolves which inventory doc (if any) an order item's quantity should
  // be deducted from.
  String? _waterInventoryKeyFor(OrderItem item) {
    if (item.productKey != null) {
      return (item.productKey == _invWaterRound || item.productKey == _invWaterSlim)
          ? item.productKey
          : null;
    }
    final name = item.name.toLowerCase();
    if (name.contains('slim') || name.contains('alkaline')) return _invWaterSlim;
    if (name.contains('round') || name.contains('gallon') || name.contains('jug')) {
      return _invWaterRound;
    }
    return null;
  }

  // Fulfill drop-off: deducts water/caps/seals exactly once in a transaction.
  Future<void> fulfillDelivery({
    required String orderId,
    required String customerId,
    required int gallonsDelivered,
    required int emptyReturned,
    required String paymentMethod,
    String? proofOfDeliveryUrl,
    String? recipientName,
  }) async {
    final orderRef = _db.collection(_colOrders).doc(orderId);

    await _db.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Order not found.');
      }
      final data = orderSnap.data()!;
      final currentStatus = data['status'] as String?;
      if (currentStatus == 'delivered' || currentStatus == 'cancelled' || data['stockDeductedAt'] != null) {
        throw Exception('This delivery was already processed.');
      }

      final itemsData = (data['items'] as List<dynamic>?) ?? [];
      final items = itemsData
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList();

      final Map<String, int> waterNeeded = {};
      int packagingNeeded = 0;
      for (final item in items) {
        final key = _waterInventoryKeyFor(item);
        if (key != null) {
          waterNeeded[key] = (waterNeeded[key] ?? 0) + item.quantity;
        }
        if (item.requiresPackaging) {
          packagingNeeded += item.quantity;
        }
      }

      // 1. READ STEP: Gather every inventory doc's current stock first.
      final Map<String, int> waterCurrentStock = {};
      for (final entry in waterNeeded.entries) {
        if (entry.value <= 0) continue;
        final invSnap = await transaction.get(_db.collection(_colInventory).doc(entry.key));
        waterCurrentStock[entry.key] = ((invSnap.data()?['currentStock'] ?? 0) as num).toInt();
      }

      final Map<String, int> pkgCurrentStock = {};
      if (packagingNeeded > 0) {
        for (final key in [_invPkgCaps, _invPkgSeals]) {
          final invSnap = await transaction.get(_db.collection(_colInventory).doc(key));
          pkgCurrentStock[key] = ((invSnap.data()?['currentStock'] ?? 0) as num).toInt();
        }
      }

      // 2. CALCULATION STEP: Calculate decrements and shortfall using pure helper.
      final Map<String, int> decrements = {};
      bool shortfall = false;

      for (final entry in waterNeeded.entries) {
        if (entry.value <= 0) continue;
        final current = waterCurrentStock[entry.key] ?? 0;
        final adj = _calculateStockAdjustment(current, entry.value);
        if (adj.shortfall) shortfall = true;
        decrements[entry.key] = adj.actualDeduction;
      }

      if (packagingNeeded > 0) {
        for (final key in [_invPkgCaps, _invPkgSeals]) {
          final current = pkgCurrentStock[key] ?? 0;
          final adj = _calculateStockAdjustment(current, packagingNeeded);
          if (adj.shortfall) shortfall = true;
          decrements[key] = adj.actualDeduction;
        }
      }

      // 3. WRITE STEP: Execute all updates after reads are complete.
      for (final entry in decrements.entries) {
        if (entry.value <= 0) continue;
        transaction.update(_db.collection(_colInventory).doc(entry.key), {
          'currentStock': FieldValue.increment(-entry.value),
        });
      }

      final unreturnedDiff = gallonsDelivered - emptyReturned;
      final orderUpdate = <String, dynamic>{
        'status': 'delivered',
        'gallonsDelivered': gallonsDelivered,
        'emptyGallonsReturned': emptyReturned,
        'unreturnedDiff': unreturnedDiff,
        'proofOfDeliveryUrl': proofOfDeliveryUrl,
        'recipientName': recipientName,
        'stockDeductedAt': FieldValue.serverTimestamp(),
        'stockShortfall': shortfall,
        'deliveredAt': FieldValue.serverTimestamp(),
      };

      if (data['paymentCollectedBy'] != 'counter') {
        orderUpdate['isPaid'] = true;
        orderUpdate['paymentMethod'] = paymentMethod;
        orderUpdate['paymentCollectedBy'] = 'rider';
        orderUpdate['paidAt'] = FieldValue.serverTimestamp();
      }
      transaction.update(orderRef, orderUpdate);

      if (customerId.isNotEmpty) {
        transaction.update(_db.collection(_colUsers).doc(customerId), {
          'unreturnedContainers': FieldValue.increment(unreturnedDiff),
        });
      }
    });
  }

  // Stream of Staff and Rider accounts.
  Stream<List<UserModel>> getTeamMembersStream() {
    return _db.collection(_colUsers).where('role', whereIn: ['staff', 'rider']).snapshots().map((snapshot) {
      final members = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    });
  }

  // Stream of all rider accounts.
  Stream<List<UserModel>> getRidersStream() {
    return _db.collection(_colUsers).where('role', isEqualTo: 'rider').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
  }) async {
    await _db.collection(_colOrders).doc(orderId).update({
      'assignedRiderId': riderId,
      'assignedRiderName': riderName,
      'status': 'outForDelivery',
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(_colUsers).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection(_colUsers).doc(uid).snapshots().map(
          (doc) => (doc.exists && doc.data() != null) ? UserModel.fromMap(doc.data()!, doc.id) : null,
    );
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection(_colUsers).doc(user.id).set(user.toMap());
  }

  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection(_colUsers).doc(uid).update({'fcmToken': token});
  }

  Future<void> deleteUserProfile(String uid) async {
    await _db.collection(_colUsers).doc(uid).delete();
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    String? address,
  }) async {
    await _db.collection(_colUsers).doc(uid).update({
      'name': name,
      'phone': phone,
      if (address != null) 'address': address,
    });
  }

  Future<void> setNotificationsEnabled(String uid, bool enabled) async {
    await _db.collection(_colUsers).doc(uid).update({'notificationsEnabled': enabled});
  }

  // Helper mapping for Shift snapshots
  ShiftModel? _mapShiftSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.isEmpty
        ? null
        : ShiftModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Stream<ShiftModel?> getOpenShiftStream() {
    return _db
        .collection(_colShifts)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map(_mapShiftSnapshot);
  }

  Stream<ShiftModel?> getLatestShiftStream() {
    return _db
        .collection(_colShifts)
        .orderBy('openedAt', descending: true)
        .limit(1)
        .snapshots()
        .map(_mapShiftSnapshot);
  }

  Future<void> openShift({required String openedByName, required double openingCash}) async {
    await _db.collection(_colShifts).add({
      'openedByName': openedByName,
      'openingCash': openingCash,
      'openedAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  Future<double> closeShift({
    required String shiftId,
    required DateTime openedAt,
    required double openingCash,
    required double closingCash,
    required String closedByName,
  }) async {
    final snapshot = await _db
        .collection(_colOrders)
        .where('paymentMethod', isEqualTo: 'cash')
        .where('isPaid', isEqualTo: true)
        .get();

    final cashCollected = snapshot.docs
        .map(_orderFromDoc)
        .where((o) => o.status != OrderStatus.cancelled && !o.paidDate.isBefore(openedAt))
        .fold<double>(0, (total, o) => total + o.totalAmount);

    final expectedCash = openingCash + cashCollected;
    final discrepancy = closingCash - expectedCash;

    await _db.collection(_colShifts).doc(shiftId).update({
      'status': 'closed',
      'closedByName': closedByName,
      'closingCash': closingCash,
      'expectedCash': expectedCash,
      'discrepancy': discrepancy,
      'closedAt': FieldValue.serverTimestamp(),
    });

    return discrepancy;
  }

  Stream<RiderCashOutModel?> getLatestRiderCashOutStream(String riderId) {
    return _db
        .collection(_colRiderCashouts)
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final cashOuts = snapshot.docs.map((d) => RiderCashOutModel.fromMap(d.data(), d.id)).toList();
      cashOuts.sort((a, b) => b.closedAt.compareTo(a.closedAt));
      return cashOuts.first;
    });
  }

  Future<double> closeRiderCashOut({
    required String riderId,
    required String riderName,
    required DateTime since,
    required double cashHandedOver,
    required String verifiedByName,
  }) async {
    final snapshot = await _db
        .collection(_colOrders)
        .where('assignedRiderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'delivered')
        .get();

    final orders = snapshot.docs.map(_orderFromDoc).where((o) => o.revenueDate.isAfter(since)).toList();
    final summary = summarizeRiderCashOut(orders);
    final discrepancy = cashHandedOver - summary.cashCollected;

    await _db.collection(_colRiderCashouts).add({
      'riderId': riderId,
      'riderName': riderName,
      'stopsCompleted': summary.stopsCompleted,
      'gallonsDelivered': summary.gallonsDelivered,
      'emptiesReturned': summary.emptiesReturned,
      'cashCollected': summary.cashCollected,
      'gcashCollected': summary.gcashCollected,
      'cashHandedOver': cashHandedOver,
      'discrepancy': discrepancy,
      'verifiedByName': verifiedByName,
      'closedAt': FieldValue.serverTimestamp(),
    });

    return discrepancy;
  }

  Future<int> transferRiderOrders({
    required String fromRiderId,
    required String toRiderId,
    required String toRiderName,
    required String reason,
  }) async {
    final snapshot = await _db
        .collection(_colOrders)
        .where('assignedRiderId', isEqualTo: fromRiderId)
        .where('status', isEqualTo: 'outForDelivery')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'assignedRiderId': toRiderId,
        'assignedRiderName': toRiderName,
        'lastTransferReason': reason,
        'lastTransferredAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Stream<List<SavedAddressModel>> getSavedAddressesStream(String uid) {
    return _userAddressRef(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SavedAddressModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addSavedAddress({
    required String uid,
    required String label,
    required String addressText,
    String? note,
    String? contactName,
    String? phone,
    bool isPrimary = false,
  }) async {
    final addressesRef = _userAddressRef(uid);
    final newAddress = SavedAddressModel(
      id: '',
      label: label,
      addressText: addressText,
      note: note,
      contactName: contactName,
      phone: phone,
      isPrimary: isPrimary,
    ).toMap();

    if (!isPrimary) {
      await addressesRef.add(newAddress);
      return;
    }

    final currentPrimary = await addressesRef.where('isPrimary', isEqualTo: true).get();
    final batch = _db.batch();
    for (final doc in currentPrimary.docs) {
      batch.update(doc.reference, {'isPrimary': false});
    }
    batch.set(addressesRef.doc(), newAddress);
    await batch.commit();
  }

  Future<void> updateSavedAddressLabel({
    required String uid,
    required String addressId,
    required String label,
  }) async {
    await _userAddressRef(uid).doc(addressId).update({'label': label});
  }

  Future<void> deleteSavedAddress({required String uid, required String addressId}) async {
    await _userAddressRef(uid).doc(addressId).delete();
  }

  // Helper mapping for Refund Request snapshots
  List<RefundModel> _mapRefundRequestsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final refunds = snapshot.docs.map((doc) => RefundModel.fromMap(doc.data(), doc.id)).toList();
    refunds.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return refunds;
  }

  Stream<List<RefundModel>> getRefundRequestsStream() {
    return _db
        .collection(_colRefundRequests)
        .snapshots()
        .map(_mapRefundRequestsSnapshot);
  }

  Stream<List<RefundModel>> getRefundRequestsForCustomerStream(String customerId) {
    return _db
        .collection(_colRefundRequests)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(_mapRefundRequestsSnapshot);
  }

  Future<void> submitRefundRequest({
    required String orderId,
    required String orderNumber,
    required String customerId,
    required String customerName,
    required String reason,
    required String description,
    required String gcashName,
    required String gcashNumber,
    double amount = 0,
    String itemsSummary = '',
    String? photoUrl,
  }) async {
    await _db.collection(_colRefundRequests).add({
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'reason': reason,
      'description': description,
      'gcashName': gcashName,
      'gcashNumber': gcashNumber,
      'amount': amount,
      'itemsSummary': itemsSummary,
      'photoUrl': photoUrl,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> processRefundRequest({
    required String refundId,
    required String status,
    required String processedByName,
    String? rejectionReason,
    String? resolutionType,
    String? gcashRefNumber,
    DateTime? redeliveryScheduledAt,
  }) async {
    await _db.collection(_colRefundRequests).doc(refundId).update({
      'status': status,
      'processedByName': processedByName,
      if (resolutionType != null) 'resolutionType': resolutionType,
      if (gcashRefNumber != null) 'gcashRefNumber': gcashRefNumber,
      if (redeliveryScheduledAt != null) 'redeliveryScheduledAt': Timestamp.fromDate(redeliveryScheduledAt),
      'processedAt': FieldValue.serverTimestamp(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  Stream<Map<String, dynamic>?> getTermsPrivacyStream() {
    return _db.collection(_colSettings).doc(_docTermsPrivacy).snapshots().map((doc) => doc.data());
  }

  Future<Map<String, dynamic>?> getTermsPrivacyOnce() async {
    final doc = await _db.collection(_colSettings).doc(_docTermsPrivacy).get();
    return doc.data();
  }

  Future<void> updateTermsPrivacy(Map<String, dynamic> data) async {
    await _db.collection(_colSettings).doc(_docTermsPrivacy).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> getServiceAreaRestrictedStream() {
    return _db.collection(_colSettings).doc(_docServiceArea).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['sanPabloOnly'] == null) return true;
      return data['sanPabloOnly'] as bool;
    });
  }

  Future<void> setServiceAreaRestricted(bool sanPabloOnly) async {
    await _db.collection(_colSettings).doc(_docServiceArea).set({
      'sanPabloOnly': sanPabloOnly,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<({double baseFee, double ratePerKm})> getDeliveryFeeConfigStream() {
    return _db.collection(_colSettings).doc(_docDeliveryFee).snapshots().map((doc) {
      final data = doc.data();
      final base = (data?['baseFee'] as num?)?.toDouble() ?? 0.0;
      final rate = (data?['ratePerKm'] as num?)?.toDouble() ?? 0.0;
      return (baseFee: base, ratePerKm: rate);
    });
  }

  Future<void> setDeliveryFeeConfig({required double baseFee, required double ratePerKm}) async {
    await _db.collection(_colSettings).doc(_docDeliveryFee).set({
      'baseFee': baseFee,
      'ratePerKm': ratePerKm,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<({String accountName, String accountNumber, String? qrImageUrl})> getGcashAccountStream() {
    return _db.collection(_colSettings).doc(_docGcashAccount).snapshots().map((doc) {
      final data = doc.data();
      final name = (data?['accountName'] as String?) ?? 'Station Owner (Aquaflow)';
      final number = (data?['accountNumber'] as String?) ?? '09171234567';
      final qrImageUrl = data?['qrImageUrl'] as String?;
      return (accountName: name, accountNumber: number, qrImageUrl: qrImageUrl);
    });
  }

  Future<void> setGcashAccount({required String accountName, required String accountNumber, String? qrImageUrl}) async {
    await _db.collection(_colSettings).doc(_docGcashAccount).set({
      'accountName': accountName,
      'accountNumber': accountNumber,
      'qrImageUrl': qrImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BranchModel>> getBranchesStream() {
    return _db.collection(_colBranches).orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => BranchModel.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  Future<void> addBranch({required String name, required String address, String? phone}) async {
    await _db.collection(_colBranches).add(
      BranchModel(id: '', name: name, address: address, phone: phone).toMap(),
    );
  }

  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String address,
    String? phone,
  }) async {
    await _db.collection(_colBranches).doc(branchId).update({
      'name': name,
      'address': address,
      'phone': phone,
    });
  }

  Future<void> deleteBranch(String branchId) async {
    await _db.collection(_colBranches).doc(branchId).delete();
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _db.collection(_colOrders).doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return _orderFromData(data, doc.id);
    });
  }

  Future<void> updateRiderLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    await _db.collection(_colOrders).doc(orderId).update({
      'riderLat': lat,
      'riderLng': lng,
    });
  }
}