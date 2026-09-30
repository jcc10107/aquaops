import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'rider_cash_out_modal.dart';
import 'emergency_transfer_modal.dart';

class DeliveryQueueScreen extends StatefulWidget {
  const DeliveryQueueScreen({super.key});
  @override
  State<DeliveryQueueScreen> createState() => _DeliveryQueueScreenState();
}

class _DeliveryQueueScreenState extends State<DeliveryQueueScreen> {
  String _area = 'all';
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _callCustomer(String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number on file for this order.'), backgroundColor: AppColors.error),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open dialer for $phone.'), backgroundColor: AppColors.error));
    }
  }

  void _showAssignRiderSheet(OrderModel order, List<UserModel> riders) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Assign Rider', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              ),
              if (riders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No rider accounts found.', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ...riders.map((rider) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.two_wheeler, color: AppColors.primaryLight)),
                  title: Text(rider.name),
                  subtitle: Text(rider.assignedArea ?? rider.phone),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(sheetContext);
                    try {
                      await _firestoreService.assignRider(orderId: order.id, riderId: rider.id, riderName: rider.name);
                      messenger.showSnackBar(SnackBar(content: Text('Assigned to ${rider.name}.')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to assign: $e'), backgroundColor: AppColors.error));
                    }
                  },
                )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _onNavTapped(int index) {
    final role = currentUserRoleNotifier.value;
    if (role == 'owner') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/owner_dashboard');
      if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 2) return;
      if (index == 3) Navigator.pushReplacementNamed(context, '/inventory');
      if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
    } else if (role == 'staff') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 1) return;
      if (index == 2) Navigator.pushReplacementNamed(context, '/inventory');
      if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
    } else {
      if (index == 0) return;
      if (index == 1) Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Widget _buildFloatingBottomNav(bool isDark, String role) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.95) : AppColors.surfaceLight.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 12))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: role == 'owner' ? 2 : (role == 'staff' ? 1 : 0),
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: AppColors.primaryLight,
                      unselectedItemColor: AppColors.textSecondary,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: role == 'owner'
                          ? const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ]
                          : role == 'staff'
                          ? const [
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Station POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ]
                          : const [
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Routes'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashOut(BuildContext context) {
    showDialog(context: context, builder: (context) => const RiderCashOutModal());
  }

  void _showEmergencyTransfer(BuildContext context) {
    showDialog(context: context, builder: (context) => const EmergencyTransferModal());
  }

  void _showFulfillDropoffModal(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : AppColors.textLight;

    final int droppedOff = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    int emptyCollected = droppedOff;
    bool paymentConfirmed = true;
    bool isSubmitting = false;
    String paymentMethod = order.paymentMethod == PaymentMethod.gcash ? 'gcash' : 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final int unreturnedDiff = droppedOff - emptyCollected;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 390,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 16))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            gradient: AppColors.vividGradient,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.water_drop, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Fulfill Drop-off', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(width: 6),
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6CF8BB), shape: BoxShape.circle)),
                                      ],
                                    ),
                                    Text(order.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE0F2FE))),
                                    Text(order.orderNumber, style: const TextStyle(fontSize: 11, color: Color(0xFFE0F2FE))),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.inventory_2, size: 16, color: AppColors.primaryLight),
                                              SizedBox(width: 4),
                                              Text('CONTAINER TELEMATICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: unreturnedDiff == 0 ? AppColors.secondaryLight : AppColors.coralAlert,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle, size: 12, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(unreturnedDiff == 0 ? 'Balanced (0)' : 'Diff ($unreturnedDiff)', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                              child: Column(
                                                children: [
                                                  const Text('Delivered', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  Text('$droppedOff', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                                  const Text('5-Gal Full', style: TextStyle(fontSize: 10, color: AppColors.borderLight)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                              child: Column(
                                                children: [
                                                  const Text('Collected', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => setStateModal(() => emptyCollected = emptyCollected > 0 ? emptyCollected - 1 : 0),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                                          child: const Icon(Icons.remove, size: 14, color: AppColors.primaryLight),
                                                        ),
                                                      ),
                                                      Container(width: 28, alignment: Alignment.center, child: Text('$emptyCollected', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textMain))),
                                                      InkWell(
                                                        onTap: () => setStateModal(() => emptyCollected++),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                                          child: const Icon(Icons.add, size: 14, color: AppColors.primaryLight),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text('Empty Return', style: TextStyle(fontSize: 10, color: AppColors.borderLight)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.payments, size: 16, color: AppColors.primaryLight),
                                              SizedBox(width: 4),
                                              Text('PAYMENT COLLECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                          Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setStateModal(() => paymentMethod = 'cash'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(color: paymentMethod == 'cash' ? AppColors.primaryLight : Colors.white, borderRadius: BorderRadius.circular(100)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.payments, size: 16, color: paymentMethod == 'cash' ? Colors.white : AppColors.textLight),
                                                    const SizedBox(width: 4),
                                                    Text('Cash', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paymentMethod == 'cash' ? Colors.white : AppColors.textLight)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setStateModal(() => paymentMethod = 'gcash'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(color: paymentMethod == 'gcash' ? AppColors.primaryLight : Colors.white, borderRadius: BorderRadius.circular(100)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.account_balance_wallet, size: 16, color: paymentMethod == 'gcash' ? Colors.white : AppColors.cyanElectric),
                                                    const SizedBox(width: 4),
                                                    Text('GCash QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paymentMethod == 'gcash' ? Colors.white : AppColors.textLight)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (order.gcashReference != null && order.gcashReference!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.tag, size: 15, color: AppColors.cyanElectric),
                                              const SizedBox(width: 6),
                                              const Text('Customer-provided ref: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              Text(order.gcashReference!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => setStateModal(() => paymentConfirmed = !paymentConfirmed),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                          child: Row(
                                            children: [
                                              Icon(paymentConfirmed ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.secondaryLight, size: 16),
                                              const SizedBox(width: 8),
                                              const Text('Confirm full payment received', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.textSecondary),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Photo proof of delivery isn\'t captured yet — this needs camera/upload support in the rider app.',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                        ),
                                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: (paymentConfirmed && !isSubmitting)
                                            ? () async {
                                          setStateModal(() => isSubmitting = true);
                                          final messenger = ScaffoldMessenger.of(this.context);
                                          final dialogNavigator = Navigator.of(context);
                                          try {
                                            await _firestoreService.fulfillDelivery(
                                              orderId: order.id,
                                              customerId: order.customerId ?? '',
                                              gallonsDelivered: droppedOff,
                                              emptyReturned: emptyCollected,
                                              paymentMethod: paymentMethod,
                                            );
                                            if (!mounted) return;
                                            dialogNavigator.pop();
                                            messenger.showSnackBar(const SnackBar(content: Text('Delivery Completed!')));
                                          } catch (e) {
                                            setStateModal(() => isSubmitting = false);
                                            messenger.showSnackBar(SnackBar(content: Text('Failed to complete delivery: $e'), backgroundColor: AppColors.coralAlert));
                                          }
                                        }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondaryLight,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                        ),
                                        icon: isSubmitting
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.verified, size: 18, color: Colors.white),
                                        label: const Text('Delivered', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _countForArea(List<OrderModel> orders, String area) {
    if (area == 'all') return orders.length;
    return orders.where((d) => d.areaZone == area).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textMain = isDark ? Colors.white : AppColors.textLight;
    final role = currentUserRoleNotifier.value;
    final isDispatcher = role == 'owner' || role == 'staff';

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      appBar: const CustomHeader(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Area-Based Delivery Queue & Dispatch', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  const Text('Ordered neighborhood routes, real-time drop-off verification & digital PoD', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  if (isDispatcher)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEmergencyTransfer(context),
                          icon: const Icon(Icons.swap_horiz, size: 16, color: Color(0xFFD97706)),
                          label: const Text('Emergency Transfer', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: isDark ? const Color(0xFF451A03).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCashOut(context),
                          icon: const Icon(Icons.attach_money, size: 16, color: AppColors.secondaryLight),
                          label: const Text('Shift Cash-Out', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6CF8BB)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: isDark ? const Color(0xFF022C22).withValues(alpha: 0.5) : const Color(0xFFECFDF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<UserModel>>(
                    stream: _firestoreService.getRidersStream(),
                    builder: (context, riderSnapshot) {
                      final riders = riderSnapshot.data ?? const <UserModel>[];

                      return StreamBuilder<List<OrderModel>>(
                    stream: _firestoreService.getActiveOrdersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('Failed to load deliveries: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final allOrders = snapshot.data!;
                      final isRider = currentUserRoleNotifier.value == 'rider';
                      final orders = isRider ? allOrders.where((o) => o.assignedRiderId == _uid).toList() : allOrders;
                      final filteredDeliveries = orders.where((d) => _area == 'all' || d.areaZone == _area).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3))),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            _buildFilterTab('all', 'All Areas', _countForArea(orders, 'all'), isDark),
                                            const SizedBox(width: 8),
                                            _buildFilterTab('sa', 'Barangay San Antonio', _countForArea(orders, 'sa'), isDark),
                                            const SizedBox(width: 8),
                                            _buildFilterTab('si', 'Barangay San Isidro', _countForArea(orders, 'si'), isDark),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isRider) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.two_wheeler, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${riders.length} rider${riders.length == 1 ? '' : 's'} available • tap "Assigned Rider" on an order to dispatch', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Text('ACTIVE DELIVERY QUEUE (${filteredDeliveries.length} PENDING)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (filteredDeliveries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text('No active deliveries in this area.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                            ),
                          ...filteredDeliveries.map((d) => _buildQueueCard(d, textMain, isDark, riders)),
                        ],
                      );
                    },
                  );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(isDark, role),
    );
  }

  Widget _buildFilterTab(String val, String label, int count, bool isDark) {
    bool isActive = _area == val;
    return InkWell(
      onTap: () => setState(() => _area = val),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.vividGradient : null,
          color: isActive ? null : const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.white : AppColors.textLight)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.white, borderRadius: BorderRadius.circular(100)),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  String _statusBadgeLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'AWAITING RIDER';
      case OrderStatus.refilling:
        return 'REFILLING';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _statusBadgeColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFD97706);
      case OrderStatus.refilling:
        return AppColors.primaryLight;
      case OrderStatus.outForDelivery:
        return AppColors.cyanElectric;
      case OrderStatus.delivered:
        return AppColors.secondaryLight;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  Widget _buildQueueCard(OrderModel order, Color textMain, bool isDark, List<UserModel> riders) {
    final qtySummary = order.items.isEmpty
        ? '—'
        : order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    final rider = order.assignedRiderName ?? 'Unassigned';
    final canReassign = currentUserRoleNotifier.value != 'rider';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyanElectric.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle), child: Center(child: Text(order.orderNumber.length > 4 ? order.orderNumber.substring(order.orderNumber.length - 4) : order.orderNumber, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 10)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customerName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.coralAlert),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order.deliveryAddress ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                        ],
                      ),
                      if (order.status == OrderStatus.outForDelivery && order.lastTransferReason != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz, size: 12, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Transferred: ${order.lastTransferReason}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusBadgeColor(order.status).withValues(alpha: 0.1), border: Border.all(color: _statusBadgeColor(order.status).withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(100)),
                  child: Text(_statusBadgeLabel(order.status), style: TextStyle(fontSize: 10, color: _statusBadgeColor(order.status), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order & Qty', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(qtySummary, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount Due', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Mode', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(order.paymentMethod == PaymentMethod.gcash ? 'GCASH' : 'CASH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: canReassign ? () => _showAssignRiderSheet(order, riders) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Assigned Rider', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                if (canReassign) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 10, color: AppColors.primaryLight),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(rider, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: order.assignedRiderId == null ? AppColors.coralAlert : textMain), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _callCustomer(order.customerPhone),
                  icon: const Icon(Icons.call, size: 14, color: AppColors.secondaryLight),
                  label: const Text('Call', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFulfillDropoffModal(order),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                    label: const Text('Complete Drop-off & Verify Payment', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}