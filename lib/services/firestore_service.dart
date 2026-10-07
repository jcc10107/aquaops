import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/inventory_model.dart';
import '../models/shift_model.dart';
import '../models/rider_cash_out_model.dart';
import '../models/saved_address_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of all inventory items, ordered by category then name
  Stream<List<InventoryModel>> getInventoryStream() {
    return _db.collection('inventory').snapshots().map((snapshot) {
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
    await _db.collection('inventory').doc(itemId).update({
      'currentStock': FieldValue.increment(quantityToAdd),
    });
  }

  // Stream of maintenance/machinery alerts, most urgent & soonest due first.
  Stream<List<MaintenanceAlertModel>> getMaintenanceAlertsStream() {
    return _db.collection('maintenance_alerts').snapshots().map((snapshot) {
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
    await _db.collection('maintenance_alerts').add(alert.toMap());
  }

  Future<void> setMaintenanceAlertCompleted(String alertId, bool isCompleted) async {
    await _db.collection('maintenance_alerts').doc(alertId).update({'isCompleted': isCompleted});
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
    final orderRef = _db.collection('orders').doc();
    final orderNumber = 'POS-${orderRef.id.substring(0, 6).toUpperCase()}';

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
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (roundGallons > 0) {
      batch.update(_db.collection('inventory').doc('inv_water_round'), {
        'currentStock': FieldValue.increment(-roundGallons),
      });
    }
    if (slimGallons > 0) {
      batch.update(_db.collection('inventory').doc('inv_water_slim'), {
        'currentStock': FieldValue.increment(-slimGallons),
      });
    }
    if (packagingUnits > 0) {
      batch.update(_db.collection('inventory').doc('inv_pkg_caps'), {
        'currentStock': FieldValue.increment(-packagingUnits),
      });
      batch.update(_db.collection('inventory').doc('inv_pkg_seals'), {
        'currentStock': FieldValue.increment(-packagingUnits),
      });
    }

    await batch.commit();
    return orderNumber;
  }

  OrderModel _orderFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final itemsData = (data['items'] as List<dynamic>?) ?? [];
    final createdAtRaw = data['createdAt'];
    final deliveredAtRaw = data['deliveredAt'];

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'],
      areaZone: data['areaZone'] ?? '',
      items: itemsData.map((i) {
        final item = i as Map<String, dynamic>;
        return OrderItem(
          name: item['name'] ?? '',
          quantity: (item['quantity'] ?? 0).toInt(),
          unitPrice: (item['unitPrice'] ?? 0).toDouble(),
          requiresPackaging: item['requiresPackaging'] ?? true,
        );
      }).toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
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
      lastTransferReason: data['lastTransferReason'],
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now(),
      deliveredAt: deliveredAtRaw is Timestamp ? deliveredAtRaw.toDate() : null,
    );
  }

  // Stream of active (not yet delivered/cancelled) orders, newest first.
  Stream<List<OrderModel>> getActiveOrdersStream() {
    return _db.collection('orders').snapshots().map((snapshot) {
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
    return _db.collection('orders').snapshots().map(
      (snapshot) => snapshot.docs.map(_orderFromDoc).toList(),
    );
  }

  // Stream of a single customer's own orders, newest first.
  Stream<List<OrderModel>> getOrdersForCustomerStream(String customerId) {
    return _db
        .collection('orders')
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
  }) async {
    final orderRef = _db.collection('orders').doc();
    final orderNumber = 'ORD-${orderRef.id.substring(0, 6).toUpperCase()}';

    await orderRef.set({
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'areaZone': areaZone,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'gcashReference': gcashReference,
      'isPaid': false,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderNumber;
  }

  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({'status': 'cancelled'});
  }

  // Fulfill drop-off with atomic inventory and container balance deduction
  Future<void> fulfillDelivery({
    required String orderId,
    required String customerId,
    required int gallonsDelivered,
    required int emptyReturned,
    required String paymentMethod,
    String? proofOfDeliveryUrl,
  }) async {
    final batch = _db.batch();
    final orderRef = _db.collection('orders').doc(orderId);

    final unreturnedDiff = gallonsDelivered - emptyReturned;

    batch.update(orderRef, {
      'status': 'delivered',
      'isPaid': true,
      'gallonsDelivered': gallonsDelivered,
      'emptyGallonsReturned': emptyReturned,
      'unreturnedDiff': unreturnedDiff,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    // Update packaging consumables stock (caps & shrink seals)
    final capsRef = _db.collection('inventory').doc('inv_pkg_caps');
    batch.update(capsRef, {
      'currentStock': FieldValue.increment(-gallonsDelivered),
    });

    final sealsRef = _db.collection('inventory').doc('inv_pkg_seals');
    batch.update(sealsRef, {
      'currentStock': FieldValue.increment(-gallonsDelivered),
    });

    // Update customer unreturned container balance
    if (customerId.isNotEmpty) {
      final userRef = _db.collection('users').doc(customerId);
      batch.update(userRef, {
        'unreturnedContainers': FieldValue.increment(unreturnedDiff),
      });
    }

    await batch.commit();
  }

  // Stream of all rider accounts, for dispatch assignment.
  // Stream of Staff and Rider accounts, for the owner's team management screen.
  Stream<List<UserModel>> getTeamMembersStream() {
    return _db.collection('users').where('role', whereIn: ['staff', 'rider']).snapshots().map((snapshot) {
      final members = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    });
  }

  Stream<List<UserModel>> getRidersStream() {
    return _db.collection('users').where('role', isEqualTo: 'rider').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  // Assigning a rider is what actually dispatches the order — a pending
  // order that gets a rider becomes "out for delivery" for real.
  Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'assignedRiderId': riderId,
      'assignedRiderName': riderName,
      'status': 'outForDelivery',
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Live version of getUser — used where the profile should update on screen
  // as soon as it changes (e.g. after an edit), without a manual refetch.
  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (doc) => (doc.exists && doc.data() != null) ? UserModel.fromMap(doc.data()!, doc.id) : null,
    );
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  // Removes a team member's AquaOps profile document. Does NOT delete their
  // Firebase Auth login — that requires Admin SDK privileges we don't have
  // client-side, so their account can still authenticate even after this.
  Future<void> deleteUserProfile(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    String? address,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      if (address != null) 'address': address,
    });
  }

  Future<void> setNotificationsEnabled(String uid, bool enabled) async {
    await _db.collection('users').doc(uid).update({'notificationsEnabled': enabled});
  }

  // Stream of the currently open shift, if any (null when none is open).
  Stream<ShiftModel?> getOpenShiftStream() {
    return _db.collection('shifts').where('status', isEqualTo: 'open').limit(1).snapshots().map(
      (snapshot) => snapshot.docs.isEmpty ? null : ShiftModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id),
    );
  }

  // Stream of the most recently opened shift, open or closed — for status display.
  Stream<ShiftModel?> getLatestShiftStream() {
    return _db.collection('shifts').orderBy('openedAt', descending: true).limit(1).snapshots().map(
      (snapshot) => snapshot.docs.isEmpty ? null : ShiftModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id),
    );
  }

  Future<void> openShift({required String openedByName, required double openingCash}) async {
    await _db.collection('shifts').add({
      'openedByName': openedByName,
      'openingCash': openingCash,
      'openedAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  // Closes a shift and reconciles it: expected cash = opening float + all
  // paid cash sales recorded since the shift opened.
  Future<double> closeShift({
    required String shiftId,
    required DateTime openedAt,
    required double openingCash,
    required double closingCash,
    required String closedByName,
  }) async {
    final snapshot = await _db
        .collection('orders')
        .where('paymentMethod', isEqualTo: 'cash')
        .where('isPaid', isEqualTo: true)
        .get();

    final cashCollected = snapshot.docs
        .map(_orderFromDoc)
        .where((o) => !o.revenueDate.isBefore(openedAt))
        .fold<double>(0, (total, o) => total + o.totalAmount);

    final expectedCash = openingCash + cashCollected;
    final discrepancy = closingCash - expectedCash;

    await _db.collection('shifts').doc(shiftId).update({
      'status': 'closed',
      'closedByName': closedByName,
      'closingCash': closingCash,
      'expectedCash': expectedCash,
      'discrepancy': discrepancy,
      'closedAt': FieldValue.serverTimestamp(),
    });

    return discrepancy;
  }

  // Stream of a rider's most recent cash-out, closed or not — used both to
  // display their last result and to know the cutoff for their next one.
  Stream<RiderCashOutModel?> getLatestRiderCashOutStream(String riderId) {
    return _db
        .collection('rider_cashouts')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final cashOuts = snapshot.docs.map((d) => RiderCashOutModel.fromMap(d.data(), d.id)).toList();
      cashOuts.sort((a, b) => b.closedAt.compareTo(a.closedAt));
      return cashOuts.first;
    });
  }

  // Reconciles a rider's cash-out: tallies their delivered orders since their
  // last cash-out (or all time, if this is their first) and records the
  // physical cash actually handed over against what was expected.
  Future<double> closeRiderCashOut({
    required String riderId,
    required String riderName,
    required DateTime since,
    required double cashHandedOver,
    required String verifiedByName,
  }) async {
    final snapshot = await _db
        .collection('orders')
        .where('assignedRiderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'delivered')
        .get();

    final orders = snapshot.docs.map(_orderFromDoc).where((o) => o.revenueDate.isAfter(since)).toList();

    final cashCollected = orders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (total, o) => total + o.totalAmount);
    final gcashCollected = orders
        .where((o) => o.paymentMethod == PaymentMethod.gcash)
        .fold<double>(0, (total, o) => total + o.totalAmount);
    final gallonsDelivered = orders.fold<int>(0, (total, o) => total + o.gallonsDelivered);
    final emptiesReturned = orders.fold<int>(0, (total, o) => total + o.emptyGallonsReturned);
    final discrepancy = cashHandedOver - cashCollected;

    await _db.collection('rider_cashouts').add({
      'riderId': riderId,
      'riderName': riderName,
      'stopsCompleted': orders.length,
      'gallonsDelivered': gallonsDelivered,
      'emptiesReturned': emptiesReturned,
      'cashCollected': cashCollected,
      'gcashCollected': gcashCollected,
      'cashHandedOver': cashHandedOver,
      'discrepancy': discrepancy,
      'verifiedByName': verifiedByName,
      'closedAt': FieldValue.serverTimestamp(),
    });

    return discrepancy;
  }

  // Bulk-reassigns every active (not yet delivered) order currently on a
  // rider's queue to a different rider — an emergency route handoff.
  Future<int> transferRiderOrders({
    required String fromRiderId,
    required String toRiderId,
    required String toRiderName,
    required String reason,
  }) async {
    final snapshot = await _db
        .collection('orders')
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

  // Stream of a customer's saved delivery addresses, oldest (primary) first.
  Stream<List<SavedAddressModel>> getSavedAddressesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SavedAddressModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addSavedAddress({
    required String uid,
    required String label,
    required String addressText,
    String? note,
  }) async {
    await _db.collection('users').doc(uid).collection('addresses').add(
      SavedAddressModel(id: '', label: label, addressText: addressText, note: note).toMap(),
    );
  }

  Future<void> updateSavedAddressLabel({
    required String uid,
    required String addressId,
    required String label,
  }) async {
    await _db.collection('users').doc(uid).collection('addresses').doc(addressId).update({'label': label});
  }

  Future<void> deleteSavedAddress({required String uid, required String addressId}) async {
    await _db.collection('users').doc(uid).collection('addresses').doc(addressId).delete();
  }
}
