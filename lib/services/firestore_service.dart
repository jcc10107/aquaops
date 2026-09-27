import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of area delivery orders
  Stream<List<OrderModel>> getOrdersStreamByArea(String areaZone) {
    return _db
        .collection('orders')
        .where('areaZone', isEqualTo: areaZone)
        .where('status', isNotEqualTo: 'delivered')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel(
      id: doc.id,
      orderNumber: doc['orderNumber'],
      customerName: doc['customerName'],
      customerPhone: doc['customerPhone'],
      deliveryAddress: doc['deliveryAddress'],
      areaZone: doc['areaZone'],
      items: [],
      totalAmount: (doc['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.outForDelivery,
      paymentMethod: PaymentMethod.cash,
      isPaid: doc['isPaid'] ?? false,
      createdAt: DateTime.now(),
    ))
        .toList());
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

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
