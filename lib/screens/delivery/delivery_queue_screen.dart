import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'rider_cash_out_modal.dart';
import 'emergency_transfer_modal.dart';
import 'fulfill_delivery_screen.dart';

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

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
                child: Text('Assign Rider', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
              if (riders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No rider accounts found.', style: TextStyle(color: Color(0xFF64748B))),
                )
              else
                ...riders.map((rider) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.two_wheeler, color: Color(0xFF0284C7))),
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

  void _showCashOut(BuildContext context) {
    showDialog(context: context, builder: (context) => const RiderCashOutModal());
  }

  void _showEmergencyTransfer(BuildContext context) {
    showDialog(context: context, builder: (context) => const EmergencyTransferModal());
  }

  int _countForArea(List<OrderModel> orders, String area) {
    if (area == 'all') return orders.length;
    return orders.where((d) => d.areaZone == area).length;
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRoleNotifier.value;
    final isDispatcher = role == 'owner' || role == 'staff';
    final canCashOut = role == 'owner' || role == 'staff' || role == 'rider';
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 130 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                    child: const Center(child: Icon(Icons.local_shipping, color: Color(0xFF0284C7), size: 22)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: const Color(0xFFBAE6FD)),
                                    ),
                                    child: const Text('DISPATCH HUB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 0.5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Area-Based Delivery Queue & Dispatch', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (isDispatcher) ...[
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showEmergencyTransfer(context),
                                    borderRadius: BorderRadius.circular(100),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB).withValues(alpha: 0.8),
                                        border: Border.all(color: const Color(0xFFFCD34D)),
                                        borderRadius: BorderRadius.circular(100),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.swap_horiz, size: 17, color: Color(0xFFB45309)),
                                          SizedBox(width: 6),
                                          Text('Emergency Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (canCashOut)
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showCashOut(context),
                                    borderRadius: BorderRadius.circular(100),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5).withValues(alpha: 0.8),
                                        border: Border.all(color: const Color(0xFF6EE7B7)),
                                        borderRadius: BorderRadius.circular(100),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.attach_money, size: 17, color: Color(0xFF047857)),
                                          SizedBox(width: 6),
                                          Text('Shift Cash-Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                                      child: Text('Failed to load deliveries: ${snapshot.error}', style: const TextStyle(color: Color(0xFFF43F5E))),
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
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
                                        ),
                                        child: Column(
                                          children: [
                                            const Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.near_me, size: 17, color: Color(0xFF0284C7)),
                                                    SizedBox(width: 6),
                                                    Text('Dispatch Zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    _BlinkingDot(color: Color(0xFF10B981)),
                                                    SizedBox(width: 4),
                                                    Text('Live Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  _buildFilterTab('all', 'All Areas', _countForArea(orders, 'all')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterTab('si', 'Barangay San Isidro', _countForArea(orders, 'si')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterTab('dr', 'Barangay Del Remedio', _countForArea(orders, 'dr')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterTab('sr', 'Barangay San Roque', _countForArea(orders, 'sr')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterTab('sm', 'Barangay San Marcos', _countForArea(orders, 'sm')),
                                                ],
                                              ),
                                            ),
                                            if (!isRider) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.only(top: 10),
                                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.two_wheeler, size: 17, color: Color(0xFF0284C7)),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Plus Jakarta Sans'),
                                                          children: [
                                                            TextSpan(text: '${riders.length} riders available', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                                            const TextSpan(text: ' • tap "Assigned Rider" on an order to dispatch'),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Text('ACTIVE DELIVERY QUEUE (${filteredDeliveries.length} PENDING)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 0.5)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (filteredDeliveries.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 24),
                                          child: Text('No active deliveries in this area.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                        ),
                                      ...filteredDeliveries.map((d) => _buildQueueCard(d, riders)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String val, String label, int count) {
    bool isActive = _area == val;
    return InkWell(
      onTap: () => setState(() => _area = val),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF00B4D8), Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: isActive ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF334155))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(100)),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF475569))),
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

  Color _statusBadgeBgColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFFFFBEB);
      case OrderStatus.refilling: return const Color(0xFFEFF6FF);
      case OrderStatus.outForDelivery: return const Color(0xFFECFEFF);
      case OrderStatus.delivered: return const Color(0xFFECFDF5);
      case OrderStatus.cancelled: return const Color(0xFFFEF2F2);
    }
  }

  Color _statusBadgeTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFB45309);
      case OrderStatus.refilling: return const Color(0xFF1D4ED8);
      case OrderStatus.outForDelivery: return const Color(0xFF0E7490);
      case OrderStatus.delivered: return const Color(0xFF047857);
      case OrderStatus.cancelled: return const Color(0xFFB91C1C);
    }
  }

  Color _statusBadgeBorderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFFDE68A);
      case OrderStatus.refilling: return const Color(0xFFBFDBFE);
      case OrderStatus.outForDelivery: return const Color(0xFFA5F3FC);
      case OrderStatus.delivered: return const Color(0xFFA7F3D0);
      case OrderStatus.cancelled: return const Color(0xFFFECACA);
    }
  }

  Widget _buildQueueCard(OrderModel order, List<UserModel> riders) {
    final qtySummary = order.items.isEmpty
        ? '—'
        : order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    final rider = order.assignedRiderName ?? 'Unassigned';
    final canReassign = currentUserRoleNotifier.value != 'rider';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 13, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Expanded(child: Text(order.deliveryAddress ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _statusBadgeBgColor(order.status), border: Border.all(color: _statusBadgeBorderColor(order.status)), borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (order.status == OrderStatus.outForDelivery) ...[
                            const _BlinkingDot(color: Color(0xFF06B6D4)),
                            const SizedBox(width: 4),
                          ],
                          Text(_statusBadgeLabel(order.status), style: TextStyle(fontSize: 10, color: _statusBadgeTextColor(order.status), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.outForDelivery && order.lastTransferReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Text('Transferred: ${order.lastTransferReason}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ORDER & QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(qtySummary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AMOUNT DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
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
                            const Text('PAYMENT MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: order.paymentMethod == PaymentMethod.gcash ? const Color(0xFF3B82F6) : const Color(0xFF10B981), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(order.paymentMethod == PaymentMethod.gcash ? 'GCASH' : 'CASH', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ASSIGNED RIDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: canReassign ? () => _showAssignRiderSheet(order, riders) : null,
                              child: Row(
                                children: [
                                  Expanded(child: Text(rider, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: order.assignedRiderId == null ? const Color(0xFFF43F5E) : const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                                  if (canReassign) const Text(' ✎', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _callCustomer(order.customerPhone),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(100)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call, size: 16, color: Color(0xFF475569)),
                        SizedBox(width: 6),
                        Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FulfillDeliveryScreen(order: order),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 17, color: Colors.white),
                          SizedBox(width: 6),
                          Flexible(child: Text('Complete Drop-off & Verify Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
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