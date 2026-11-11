import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/products.dart';
import '../core/constants/zones.dart';
import '../models/branch_model.dart';
import '../models/emergency_request_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../models/rider_cash_out_model.dart';
import '../models/saved_address_model.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import 'push_notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PushNotificationService _push = PushNotificationService();

  // ── Collection names ──────────────────────────────────────────────
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
  static const String _colEmergencyRequests = 'emergency_requests';
  static const String _colCounters = 'counters';
  static const String _colProducts = 'products';

  // ── Inventory doc IDs ─────────────────────────────────────────────
  static const String _invWaterRound = 'inv_water_round';
  static const String _invWaterSlim = 'inv_water_slim';
  static const String _invPkgCaps = 'inv_pkg_caps';
  static const String _invPkgSeals = 'inv_pkg_seals';

  // ── Settings doc IDs ──────────────────────────────────────────────
  static const String _docTermsPrivacy = 'terms_privacy';
  static const String _docDeliveryFee = 'delivery_fee';
  static const String _docGcashAccount = 'gcash_account';
  static const String _docProductImages = 'product_images';

  // ── Helpers ───────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _userAddressRef(String uid) {
    return _db.collection(_colUsers).doc(uid).collection(_colAddresses);
  }

  // Atomically bumps a shared counter doc and returns the new value — one
  // sequence shared by every order-creation path (POS, customer delivery,
  // counter delivery), so numbers run 1, 2, 3... across all of them instead
  // of each getting their own series.
  Future<int> _nextOrderSequence() {
    final counterRef = _db.collection(_colCounters).doc('orders');
    return _db.runTransaction<int>((transaction) async {
      final snap = await transaction.get(counterRef);
      final next = ((snap.data()?['lastNumber'] as num?)?.toInt() ?? 0) + 1;
      transaction.set(counterRef, {'lastNumber': next}, SetOptions(merge: true));
      return next;
    });
  }

  // Prefix is kept (not just the number) because order_model.dart and
  // notification_feed.dart both key behavior off orderNumber.startsWith('POS-')
  // to tell a walk-in POS sale apart from a delivery order.
  Future<String> _generateOrderNumber(String prefix) async {
    final next = await _nextOrderSequence();
    return '$prefix-$next';
  }

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

  // ── Inventory ─────────────────────────────────────────────────────

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
      'notifiedLowStock': false,
    });
  }

  // ── Maintenance ───────────────────────────────────────────────────

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

  // ── Orders ────────────────────────────────────────────────────────

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
    final orderNumber = await _generateOrderNumber('POS');

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

  Future<OrderModel?> getOrderOnce(String orderId) async {
    final doc = await _db.collection(_colOrders).doc(orderId).get();
    final data = doc.data();
    if (data == null) return null;
    return _orderFromData(data, doc.id);
  }

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

  Stream<List<OrderModel>> getAllOrdersStream() {
    return _db.collection(_colOrders).snapshots().map(
          (snapshot) => snapshot.docs.map(_orderFromDoc).toList(),
    );
  }

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
    final orderNumber = await _generateOrderNumber('ORD');

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

    unawaited(_push.notifyDispatchQueue(
      title: 'New order placed',
      body: '$orderNumber from $customerName needs processing.',
      data: {'orderId': orderRef.id},
    ));

    return orderNumber;
  }

  Future<String> placeCounterDeliveryOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String zone,
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentChoice,
    String? paymentMethod,
    String? gcashReference,
    double deliveryFee = 0,
  }) async {
    final orderRef = _db.collection(_colOrders).doc();
    final orderNumber = await _generateOrderNumber('ORD');
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

  Future<void> cancelOrder(String orderId) async {
    final orderRef = _db.collection(_colOrders).doc(orderId);
    String? orderNumber;
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(orderRef);
      if (!snap.exists) return;
      if (snap.data()?['status'] == 'delivered') {
        throw Exception('Delivered orders cannot be cancelled.');
      }
      orderNumber = snap.data()?['orderNumber'] as String?;
      transaction.update(orderRef, {'status': 'cancelled'});
    });

    // The customer is the one cancelling here — no point telling them
    // about their own action — but dispatch needs to know so nobody
    // preps or sends a rider for it.
    unawaited(_push.notifyDispatchQueue(
      title: 'Order cancelled',
      body: '${orderNumber ?? 'An order'} was cancelled by the customer.',
      data: {'orderId': orderId},
    ));
  }

  Future<void> confirmOrderReceived({
    required String orderId,
    required String customerId,
  }) async {
    try {
      await _db.collection(_colOrders).doc(orderId).update({
        'customerConfirmedReceived': true,
        'customerReceivedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (customerId.isNotEmpty) {
          await _db.collection(_colUsers).doc(customerId).collection('confirmed_receipts').doc(orderId).set({
            'orderId': orderId,
            'customerConfirmedReceived': true,
            'confirmedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
      }
      rethrow;
    }
  }

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
    String orderNumber = '';

    await _db.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Order not found.');
      }
      final data = orderSnap.data()!;
      orderNumber = data['orderNumber'] as String? ?? '';
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

      for (final entry in decrements.entries) {
        if (entry.value <= 0) continue;
        transaction.update(_db.collection(_colInventory).doc(entry.key), {
          'currentStock': FieldValue.increment(-entry.value),
        });
      }

      final unreturnedDiff = gallonsDelivered - emptyReturned;
      final orderUpdate = <String, dynamic>{
        'status': 'delivered',
        'riderConfirmedDelivery': true,
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

    if (customerId.isNotEmpty) {
      unawaited(_push.notifyUser(
        uid: customerId,
        title: 'Order update',
        body: 'Your order $orderNumber has been delivered. Thank you for choosing Aqua Ops!',
        data: {'orderId': orderId},
      ));
    }
  }

  // ── Team ──────────────────────────────────────────────────────────

  Stream<List<UserModel>> getTeamMembersStream() {
    return _db.collection(_colUsers).where('role', whereIn: ['staff', 'rider']).snapshots().map((snapshot) {
      final members = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    });
  }

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
    final orderRef = _db.collection(_colOrders).doc(orderId);
    await orderRef.update({
      'assignedRiderId': riderId,
      'assignedRiderName': riderName,
      'status': 'outForDelivery',
    });

    final snap = await orderRef.get();
    final data = snap.data();
    if (data == null) return;
    final orderNumber = data['orderNumber'] as String? ?? '';
    final customerId = data['customerId'] as String?;

    if (customerId != null && customerId.isNotEmpty) {
      unawaited(_push.notifyUser(
        uid: customerId,
        title: 'Order update',
        body: 'Your order $orderNumber is out for delivery!',
        data: {'orderId': orderId},
      ));
    }
    unawaited(_push.notifyUser(
      uid: riderId,
      title: 'New delivery assigned',
      body: 'You\'ve been assigned $orderNumber.',
      data: {'orderId': orderId},
    ));
  }

  // ── Users ─────────────────────────────────────────────────────────

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
    // arrayUnion so each device this account logs into keeps its own slot
    // instead of overwriting the last one — otherwise only the most
    // recently logged-in device ever gets notified. merge: true so this
    // never throws NOT_FOUND if it runs before the user's profile doc
    // exists yet (e.g. a signup race) — the token just waits as an orphan
    // field until the rest of the profile is written.
    await _db.collection(_colUsers).doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
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

  // ── Shifts ────────────────────────────────────────────────────────

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

  // ── Rider Cash-Outs (Connected Rider + Owner Workflow) ────────────

  Stream<RiderCashOutModel?> getLatestRiderCashOutStream(String riderId) {
    return _db
        .collection(_colRiderCashouts)
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Filter by status on the raw map to avoid undefined getter on model
      final completedDocs = snapshot.docs.where((d) {
        final st = d.data()['status'] as String?;
        return st == null || st == 'completed';
      }).toList();
      if (completedDocs.isEmpty) return null;

      final cashOuts = completedDocs
          .map((d) => RiderCashOutModel.fromMap(d.data(), d.id))
          .toList();
      cashOuts.sort((a, b) => b.closedAt.compareTo(a.closedAt));
      return cashOuts.first;
    });
  }

  Stream<Map<String, dynamic>?> getActiveRiderPendingCashOutStream(String riderId) {
    return _db
        .collection(_colRiderCashouts)
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      data['id'] = snap.docs.first.id;
      return data;
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingRiderCashOutsStream() {
    return _db
        .collection(_colRiderCashouts)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
      return list;
    });
  }

  Future<String> submitRiderCashOutRequest({
    required String riderId,
    required String riderName,
    required double reportedCash,
    required double expectedCash,
    required double gcashCollected,
    required int stopsCompleted,
    required int gallonsDelivered,
    required int emptiesReturned,
    required List<String> orderIds,
    required DateTime since,
  }) async {
    final existingPending = await _db
        .collection(_colRiderCashouts)
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingPending.docs.isNotEmpty) {
      throw StateError('You already have a cash-out turnover pending dispatch verification.');
    }

    final docRef = _db.collection(_colRiderCashouts).doc();
    await docRef.set({
      'riderId': riderId,
      'riderName': riderName,
      'reportedCash': reportedCash,
      'cashCollected': expectedCash,
      'gcashCollected': gcashCollected,
      'stopsCompleted': stopsCompleted,
      'gallonsDelivered': gallonsDelivered,
      'emptiesReturned': emptiesReturned,
      'orderIds': orderIds,
      'since': Timestamp.fromDate(since),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'closedAt': FieldValue.serverTimestamp(),
    });

    unawaited(_push.notifyDispatchQueue(
      title: 'Cash-out awaiting verification',
      body: '$riderName submitted a shift turnover — ₱${reportedCash.toStringAsFixed(2)} reported. Review it in Rider Cash-Out.',
      data: {'cashOutId': docRef.id},
    ));

    return docRef.id;
  }

  Future<void> cancelRiderCashOutRequest(String cashOutId, String riderId) async {
    final docRef = _db.collection(_colRiderCashouts).doc(cashOutId);
    final snap = await docRef.get();
    if (!snap.exists) throw StateError('Cash-out request not found.');
    final data = snap.data()!;
    if (data['riderId'] != riderId) throw StateError('Unauthorized.');
    if (data['status'] != 'pending') throw StateError('Only pending requests can be cancelled.');

    await docRef.delete();
  }

  Future<double> verifyAndCloseRiderCashOut({
    required String cashOutId,
    required double actualCashReceived,
    required String verifiedByName,
    required String verifiedById,
  }) async {
    final docRef = _db.collection(_colRiderCashouts).doc(cashOutId);
    final snap = await docRef.get();
    if (!snap.exists) throw StateError('Cash-out request not found.');
    final data = snap.data()!;
    if (data['status'] == 'completed') throw StateError('This cash-out has already been verified.');

    final expectedCash = (data['cashCollected'] as num?)?.toDouble() ?? 0.0;
    final discrepancy = actualCashReceived - expectedCash;

    await docRef.update({
      'status': 'completed',
      'cashHandedOver': actualCashReceived,
      'discrepancy': discrepancy,
      'verifiedByName': verifiedByName,
      'verifiedById': verifiedById,
      'closedAt': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    final riderId = data['riderId'] as String?;
    final riderName = data['riderName'] as String? ?? 'Rider';
    final discrepancyNote = discrepancy == 0
        ? 'matched exactly'
        : '${discrepancy > 0 ? 'over' : 'short'} by ₱${discrepancy.abs().toStringAsFixed(2)}';
    if (riderId != null && riderId.isNotEmpty) {
      unawaited(_push.notifyUser(
        uid: riderId,
        title: 'Cash-out verified',
        body: 'Your turnover was verified — $discrepancyNote.',
        data: {'cashOutId': cashOutId},
      ));
    }
    unawaited(_push.notifyDispatchQueue(
      title: 'Rider cash-out closed',
      body: '$riderName handed over ₱${actualCashReceived.toStringAsFixed(2)} — $discrepancyNote.',
      data: {'cashOutId': cashOutId},
    ));

    return discrepancy;
  }

  Future<void> rejectRiderCashOut({
    required String cashOutId,
    required String rejectionReason,
    required String rejectedByName,
  }) async {
    if (rejectionReason.trim().isEmpty) throw ArgumentError('Rejection reason required.');
    final docRef = _db.collection(_colRiderCashouts).doc(cashOutId);
    final snap = await docRef.get();
    final riderId = snap.data()?['riderId'] as String?;

    await docRef.update({
      'status': 'rejected',
      'rejectionReason': rejectionReason.trim(),
      'rejectedByName': rejectedByName,
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    if (riderId != null && riderId.isNotEmpty) {
      unawaited(_push.notifyUser(
        uid: riderId,
        title: 'Cash-out rejected',
        body: 'Your turnover was rejected: $rejectionReason',
        data: {'cashOutId': cashOutId},
      ));
    }
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

    final orders = snapshot.docs
        .map(_orderFromDoc)
        .where((o) => o.revenueDate.isAfter(since))
        .toList();

    final summary = summarizeRiderCashOut(orders);
    final discrepancy = cashHandedOver - summary.cashCollected;
    final docRef = _db.collection(_colRiderCashouts).doc();

    await docRef.set({
      'riderId': riderId,
      'riderName': riderName,
      'status': 'completed',
      'stopsCompleted': summary.stopsCompleted,
      'gallonsDelivered': summary.gallonsDelivered,
      'emptiesReturned': summary.emptiesReturned,
      'cashCollected': summary.cashCollected,
      'gcashCollected': summary.gcashCollected,
      'cashHandedOver': cashHandedOver,
      'discrepancy': discrepancy,
      'verifiedByName': verifiedByName,
      'orderIds': orders.map((o) => o.id).toList(),
      'closedAt': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    final discrepancyNote = discrepancy == 0
        ? 'matched exactly'
        : '${discrepancy > 0 ? 'over' : 'short'} by ₱${discrepancy.abs().toStringAsFixed(2)}';
    unawaited(_push.notifyUser(
      uid: riderId,
      title: 'Cash-out closed',
      body: 'Dispatch closed your shift turnover — $discrepancyNote.',
      data: {'cashOutId': docRef.id},
    ));

    return discrepancy;
  }

  Future<int> transferRiderOrders({
    required String fromRiderId,
    required String toRiderId,
    required String toRiderName,
    required String reason,
    List<String>? specificOrderIds,
  }) async {
    final snapshot = await _db
        .collection(_colOrders)
        .where('assignedRiderId', isEqualTo: fromRiderId)
        .where('status', isEqualTo: 'outForDelivery')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = _db.batch();
    int count = 0;
    for (final doc in snapshot.docs) {
      if (specificOrderIds != null && !specificOrderIds.contains(doc.id)) {
        continue;
      }
      batch.update(doc.reference, {
        'assignedRiderId': toRiderId,
        'assignedRiderName': toRiderName,
        'lastTransferReason': reason,
        'lastTransferredAt': FieldValue.serverTimestamp(),
      });
      count++;
    }
    await batch.commit();
    return count;
  }

  // ── Emergency Transfer Requests ───────────────────────────────────

  Future<String> createEmergencyRequest({
    required String riderId,
    required String riderName,
    String? riderPhone,
    required List<String> affectedOrderIds,
    required String reason,
    String? description,
  }) async {
    if (affectedOrderIds.isEmpty) {
      throw ArgumentError('At least one active delivery must be selected.');
    }
    if (reason.toLowerCase() == 'other' && (description == null || description.trim().isEmpty)) {
      throw ArgumentError('Please provide a description when selecting "Other".');
    }

    final existingPending = await _db
        .collection(_colEmergencyRequests)
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: EmergencyRequestStatus.pending.name)
        .limit(1)
        .get();

    if (existingPending.docs.isNotEmpty) {
      throw StateError('You already have an active emergency request pending dispatch review.');
    }

    final docRef = _db.collection(_colEmergencyRequests).doc();
    final request = EmergencyRequestModel(
      id: docRef.id,
      riderId: riderId,
      riderName: riderName,
      riderPhone: riderPhone,
      affectedOrderIds: affectedOrderIds,
      reason: reason,
      description: description?.trim(),
      status: EmergencyRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await docRef.set(request.toMap());

    unawaited(_push.notifyDispatchQueue(
      title: 'Emergency transfer request',
      body: '$riderName needs help with ${affectedOrderIds.length} ${affectedOrderIds.length == 1 ? 'delivery' : 'deliveries'} — $reason. Review it in Emergency Requests.',
      data: {'emergencyRequestId': docRef.id},
    ));

    return docRef.id;
  }

  Stream<List<EmergencyRequestModel>> getEmergencyRequestsStream({
    String? riderId,
    EmergencyRequestStatus? statusFilter,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(_colEmergencyRequests);

    if (riderId != null) {
      query = query.where('riderId', isEqualTo: riderId);
    }
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EmergencyRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<EmergencyRequestModel?> getSingleEmergencyRequestStream(String requestId) {
    return _db
        .collection(_colEmergencyRequests)
        .doc(requestId)
        .snapshots()
        .map((doc) => (doc.exists && doc.data() != null) ? EmergencyRequestModel.fromFirestore(doc) : null);
  }

  Future<void> cancelEmergencyRequest({
    required String requestId,
    required String riderId,
  }) async {
    final docRef = _db.collection(_colEmergencyRequests).doc(requestId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) throw StateError('Request not found.');
    final data = snapshot.data()!;

    if (data['riderId'] != riderId) {
      throw StateError('Unauthorized.');
    }
    if (data['status'] != EmergencyRequestStatus.pending.name) {
      throw StateError('Only pending requests can be cancelled.');
    }

    await docRef.update({
      'status': EmergencyRequestStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    unawaited(_push.notifyDispatchQueue(
      title: 'Emergency request withdrawn',
      body: '${data['riderName'] ?? 'A rider'} cancelled their emergency transfer request.',
      data: {'emergencyRequestId': requestId},
    ));
  }

  Future<void> declineEmergencyRequest({
    required String requestId,
    required String declineReason,
  }) async {
    if (declineReason.trim().isEmpty) {
      throw ArgumentError('A decline reason is required.');
    }

    final docRef = _db.collection(_colEmergencyRequests).doc(requestId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) throw StateError('Request not found.');
    final data = snapshot.data()!;

    if (data['status'] != EmergencyRequestStatus.pending.name) {
      throw StateError('This request has already been reviewed or resolved.');
    }

    await docRef.update({
      'status': EmergencyRequestStatus.declined.name,
      'declineReason': declineReason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final riderId = data['riderId'] as String?;
    if (riderId != null && riderId.isNotEmpty) {
      unawaited(_push.notifyUser(
        uid: riderId,
        title: 'Emergency request declined',
        body: declineReason.trim(),
        data: {'emergencyRequestId': requestId},
      ));
    }
  }

  Future<int> resolveEmergencyRequestAndTransfer({
    required String requestId,
    required String fromRiderId,
    required String toRiderId,
    required String toRiderName,
    List<String>? specificOrderIds,
    required String reason,
  }) async {
    final reqRef = _db.collection(_colEmergencyRequests).doc(requestId);
    final reqSnap = await reqRef.get();

    if (!reqSnap.exists) throw StateError('Request not found.');
    final reqData = reqSnap.data()!;

    if (reqData['status'] == EmergencyRequestStatus.resolved.name) {
      throw StateError('This emergency request has already been resolved.');
    }

    final snapshot = await _db
        .collection(_colOrders)
        .where('assignedRiderId', isEqualTo: fromRiderId)
        .where('status', isEqualTo: 'outForDelivery')
        .get();

    final batch = _db.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      if (specificOrderIds != null && !specificOrderIds.contains(doc.id)) {
        continue;
      }
      batch.update(doc.reference, {
        'assignedRiderId': toRiderId,
        'assignedRiderName': toRiderName,
        'lastTransferReason': reason,
        'lastTransferredAt': FieldValue.serverTimestamp(),
      });
      count++;
    }

    batch.update(reqRef, {
      'status': EmergencyRequestStatus.resolved.name,
      'replacementRiderId': toRiderId,
      'replacementRiderName': toRiderName,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    unawaited(_push.notifyUser(
      uid: fromRiderId,
      title: 'Emergency request resolved',
      body: '$count ${count == 1 ? 'delivery was' : 'deliveries were'} transferred to $toRiderName.',
      data: {'emergencyRequestId': requestId},
    ));
    unawaited(_push.notifyUser(
      uid: toRiderId,
      title: 'Deliveries transferred to you',
      body: '$count ${count == 1 ? 'delivery' : 'deliveries'} reassigned to you from another rider\'s emergency.',
      data: {'emergencyRequestId': requestId},
    ));

    return count;
  }

  // ── Saved addresses ───────────────────────────────────────────────

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
    double? latitude,
    double? longitude,
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
      latitude: latitude,
      longitude: longitude,
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

  // ── Refunds ───────────────────────────────────────────────────────

  List<RefundModel> _mapRefundRequestsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final refunds = snapshot.docs.map((doc) => RefundModel.fromMap(doc.data(), doc.id)).toList();
    refunds.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return refunds;
  }

  Future<RefundModel?> getRefundOnce(String refundId) async {
    final doc = await _db.collection(_colRefundRequests).doc(refundId).get();
    final data = doc.data();
    if (data == null) return null;
    return RefundModel.fromMap(data, doc.id);
  }

  Stream<List<RefundModel>> getRefundRequestsStream() {
    return _db.collection(_colRefundRequests).snapshots().map(_mapRefundRequestsSnapshot);
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
    final docRef = await _db.collection(_colRefundRequests).add({
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

    unawaited(_push.notifyDispatchQueue(
      title: 'Refund request submitted',
      body: '$customerName requested a refund for $orderNumber — $reason.',
      data: {'refundId': docRef.id},
    ));
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
    final existing = await _db.collection(_colRefundRequests).doc(refundId).get();
    final existingData = existing.data();
    final customerId = existingData?['customerId'] as String?;
    final orderNumber = existingData?['orderNumber'] as String?;

    await _db.collection(_colRefundRequests).doc(refundId).update({
      'status': status,
      'processedByName': processedByName,
      if (resolutionType != null) 'resolutionType': resolutionType,
      if (gcashRefNumber != null) 'gcashRefNumber': gcashRefNumber,
      if (redeliveryScheduledAt != null) 'redeliveryScheduledAt': Timestamp.fromDate(redeliveryScheduledAt),
      'processedAt': FieldValue.serverTimestamp(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });

    if (customerId != null && customerId.isNotEmpty) {
      final orderLabel = orderNumber ?? 'your order';
      String body;
      switch (status) {
        case 'rejected':
          body = 'Your refund request for $orderLabel was declined${rejectionReason != null ? ': $rejectionReason' : '.'}';
          break;
        case 'approved':
          body = resolutionType == 'refund'
              ? 'Your refund for $orderLabel was approved — the GCash transfer is being processed.'
              : 'Your refund request for $orderLabel was approved — a free redelivery has been scheduled.';
          break;
        case 'processed':
          body = 'Your refund for $orderLabel has been sent via GCash${gcashRefNumber != null ? ' (Ref #$gcashRefNumber)' : '.'}';
          break;
        default:
          body = 'There\'s an update on your refund request for $orderLabel.';
      }
      unawaited(_push.notifyUser(
        uid: customerId,
        title: 'Refund update',
        body: body,
        data: {'refundId': refundId},
      ));
    }
  }

  // ── Settings ──────────────────────────────────────────────────────

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

  // Lets the owner upload a real photo per product (customer store's
  // catalog is a fixed constant list in code — just the image per id is
  // swappable, without needing a full product-management system).
  Stream<Map<String, String>> getProductImagesStream() {
    return _db.collection(_colSettings).doc(_docProductImages).snapshots().map((doc) {
      final raw = doc.data()?['images'] as Map<String, dynamic>?;
      if (raw == null) return <String, String>{};
      return raw.map((key, value) => MapEntry(key, value as String));
    });
  }

  Future<void> setProductImage(String productId, String imageUrl) async {
    await _db.collection(_colSettings).doc(_docProductImages).set({
      'images': {productId: imageUrl},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Products (customer store catalog) ─────────────────────────────

  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _db.collection(_colProducts).orderBy('createdAt').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? '',
          'price': (data['price'] as num?)?.toDouble() ?? 0.0,
          'type': data['type'] as String? ?? '',
        };
      }).toList(),
    );
  }

  // One-time migration from the old hardcoded catalog (lib/core/constants/products.dart)
  // to Firestore, so existing order ids (r_slim, r_round, ...) keep matching.
  // Safe to call on every owner session — only adds whichever catalog ids
  // are still missing (e.g. a newly added default like bottle500), and
  // never touches an id that already exists, so it won't clobber the
  // owner's own edits to that product.
  Future<void> seedDefaultProductsIfEmpty() async {
    final existing = await _db.collection(_colProducts).get();
    final existingIds = existing.docs.map((d) => d.id).toSet();
    final missing = catalogProducts.where((p) => !existingIds.contains(p.id));
    if (missing.isEmpty) return;
    final batch = _db.batch();
    for (final p in missing) {
      batch.set(_db.collection(_colProducts).doc(p.id), {
        'name': p.name,
        'price': p.price,
        'type': p.type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> addProduct({required String name, required double price, required String type}) async {
    await _db.collection(_colProducts).add({
      'name': name,
      'price': price,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(String productId, {required String name, required double price, required String type}) async {
    await _db.collection(_colProducts).doc(productId).update({
      'name': name,
      'price': price,
      'type': type,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection(_colProducts).doc(productId).delete();
  }

  // ── Branches ──────────────────────────────────────────────────────

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

  // ── Live tracking ─────────────────────────────────────────────────

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