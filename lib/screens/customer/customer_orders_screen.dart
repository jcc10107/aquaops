import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/order_model.dart';
import '../../models/refund_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import 'customer_map_screen.dart';
import 'customer_refund_request_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  final List<OrderModel> myOrders;
  final bool hasActiveOrder;
  final List<Map<String, dynamic>> products;
  final Function(Map<String, int>) onReorder;
  final VoidCallback? onProfileTap;

  const CustomerOrdersScreen({
    super.key,
    required this.myOrders,
    required this.hasActiveOrder,
    required this.products,
    required this.onReorder,
    this.onProfileTap,
  });

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  int _ordersTab = 0;
  String _orderHistoryFilter = 'all';
  final TextEditingController _historySearchCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final MessagingService _messagingService = MessagingService();

  final Set<String> _confirmedOrderIds = {};
  final Set<String> _confirmingOrderIds = {};

  TextStyle _ts({
    required double size,
    FontWeight weight = FontWeight.w500,
    required Color color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return AppTypography.ts(
      size: size,
      weight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(
      decoration: decoration,
      decorationColor: decoration != null ? color : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadConfirmedReceipts();
  }

  @override
  void dispose() {
    _historySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfirmedReceipts() async {
    final String? uid = AuthService().currentUserId;
    if (uid == null) return;

    try {
      final userReceipts = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('confirmed_receipts')
          .get();
      if (mounted && userReceipts.docs.isNotEmpty) {
        setState(() {
          _confirmedOrderIds.addAll(userReceipts.docs.map((d) => d.id));
        });
      }
    } catch (_) {}

    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .where('customerConfirmedReceipt', isEqualTo: true)
          .get();
      if (mounted && snap.docs.isNotEmpty) {
        setState(() {
          _confirmedOrderIds.addAll(snap.docs.map((d) => d.id));
        });
      }
    } catch (_) {}
  }

  Future<void> _showConfirmReceivedDialog(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Order Receipt',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        content: Text(
          'Have you received all items for Order #${order.orderNumber} in good condition?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySky,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Received', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final String? uid = AuthService().currentUserId;
    setState(() => _confirmingOrderIds.add(order.id));
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.confirmOrderReceived(
        orderId: order.id,
        customerId: uid ?? order.customerId ?? '',
      );
      if (mounted) {
        setState(() {
          _confirmingOrderIds.remove(order.id);
          _confirmedOrderIds.add(order.id);
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Order receipt confirmed. Thank you!'),
            backgroundColor: AppColors.emerald600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmingOrderIds.remove(order.id));
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to confirm receipt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.cancelOrder(orderId);
      // Best-effort — see lockDeliveryConversationAsCompleted's own note on
      // the lazy fallback if this doesn't succeed.
      unawaited(_messagingService.lockDeliveryConversationAsCompleted(orderId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Order Cancelled.'), backgroundColor: AppColors.error),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _reorder(OrderModel order) {
    final updates = <String, int>{};
    for (final item in order.items) {
      final product = widget.products.firstWhere(
            (p) => p['name'] == item.name,
        orElse: () => const {},
      );
      if (product.isNotEmpty) {
        final productId = product['id'];
        if (productId != null) {
          updates[productId.toString()] = item.quantity;
        }
      }
    }
    widget.onReorder(updates);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Items added to cart.')),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(d)} at $hour12:$minute $ampm';
  }

  void _openProofOfDelivery(OrderModel order) {
    final String? url = (order.proofOfDeliveryUrl != null && order.proofOfDeliveryUrl!.trim().isNotEmpty)
        ? order.proofOfDeliveryUrl!.trim()
        : null;
    final String? recipient = (order.recipientName != null && order.recipientName!.trim().isNotEmpty)
        ? order.recipientName!.trim()
        : null;
    final DateTime? deliveredAt = order.deliveredAt;

    showDialog(
      context: context,
      barrierColor: AppColors.backgroundDark.withValues(alpha: 0.6),
      builder: (ctx) => ProofOfDeliveryDialog(
        title: 'PROOF OF DELIVERY',
        subtitle: 'Order #${order.orderNumber}',
        imageUrl: url,
        chromeHeight: 250,
        badgeIcon: Icons.verified,
        badgeIconColor: AppColors.emerald600,
        badgeText: 'Rider Verified Drop-off',
        detailsChild: RichText(
          text: TextSpan(
            style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate600, height: 1.5),
            children: [
              const TextSpan(text: 'Delivered: '),
              TextSpan(
                text: deliveredAt != null ? _formatDateTime(deliveredAt) : 'Time not recorded',
                style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.textLight),
              ),
              if (order.assignedRiderName != null && order.assignedRiderName!.trim().isNotEmpty) ...[
                const TextSpan(text: '\nRider: '),
                TextSpan(
                  text: order.assignedRiderName!.trim(),
                  style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.textLight),
                ),
              ],
              if (recipient != null) ...[
                const TextSpan(text: '\nReceived by: '),
                TextSpan(
                  text: recipient,
                  style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.textLight),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderReceivedButton({
    required OrderModel order,
    required bool riderConfirmed,
    required bool customerConfirmed,
    required bool isConfirming,
  }) {
    // State 3: Customer already confirmed
    if (customerConfirmed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.emerald50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.emerald200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, size: 14, color: AppColors.emerald700),
            const SizedBox(width: 4),
            Text(
              'Received',
              style: _ts(size: 12, weight: FontWeight.bold, color: AppColors.emerald700),
            ),
          ],
        ),
      );
    }

    // State 1 & 2: Enabled only when rider has confirmed delivery
    final bool canConfirm = riderConfirmed && !isConfirming;

    return ElevatedButton.icon(
      onPressed: canConfirm ? () => _showConfirmReceivedDialog(order) : null,
      icon: isConfirming
          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(
        Icons.check_circle_outline,
        size: 14,
        color: canConfirm ? Colors.white : AppColors.slate400,
      ),
      label: Text(
        'Order Received',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: canConfirm ? Colors.white : AppColors.slate400,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canConfirm ? AppColors.primarySky : AppColors.slate100,
        foregroundColor: canConfirm ? Colors.white : AppColors.slate400,
        disabledBackgroundColor: AppColors.slate100,
        disabledForegroundColor: AppColors.slate400,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Active orders include:
    // 1. Pending, refilling, outForDelivery
    // 2. Delivered orders awaiting customer receipt confirmation
    final activeOrders = widget.myOrders.where((o) {
      if (o.status == OrderStatus.cancelled) return false;
      final bool isDelivered = o.riderConfirmedDelivery || o.status == OrderStatus.delivered;
      final bool customerConfirmed = o.customerConfirmedReceipt || _confirmedOrderIds.contains(o.id);

      if (!isDelivered) return true;
      return !customerConfirmed;
    }).toList();

    // History orders include all delivered and cancelled orders
    final historyOrders = widget.myOrders.where((o) {
      return o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled;
    }).toList();

    final String? uid = AuthService().currentUserId;
    final double topInset = MediaQuery.of(context).padding.top;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Container(
        padding: EdgeInsets.only(top: topInset + CustomHeader.contentHeight),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<RefundModel>>(
              stream: uid == null
                  ? Stream<List<RefundModel>>.empty()
                  : _firestoreService.getRefundRequestsForCustomerStream(uid),
              builder: (context, snapshot) {
                final refunds = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.sky50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: AppColors.primarySky,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'My Orders',
                                  style: _ts(
                                    size: 17,
                                    weight: FontWeight.bold,
                                    color: AppColors.textLight,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildOrderSwitcher(activeOrders.length, historyOrders.length, refunds.length),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ordersTab == 0
                          ? _buildActiveOrdersList(activeOrders, bottomInset)
                          : _ordersTab == 1
                          ? _buildOrderHistoryList(historyOrders, bottomInset)
                          : _buildRefundsList(refunds, bottomInset),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSwitcher(int activeCount, int historyCount, int refundCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTabButton(index: 0, label: 'Active', count: activeCount, showDot: activeCount > 0),
          _buildTabButton(index: 1, label: 'History', count: historyCount, showDot: false),
          _buildTabButton(index: 2, label: 'Refunds', count: refundCount, showDot: false),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required int count,
    required bool showDot,
  }) {
    final selected = _ordersTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _ordersTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showDot && selected)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySky,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                label,
                style: _ts(
                  size: 12,
                  weight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? AppColors.primarySky : AppColors.slate600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.sky50 : AppColors.slate200,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: _ts(
                    size: 10,
                    weight: FontWeight.bold,
                    color: selected ? AppColors.primarySky : AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text, style: _ts(size: 13, color: AppColors.slate400)),
      ),
    );
  }

  Widget _buildActiveOrdersList(List<OrderModel> activeOrders, double bottomInset) {
    if (activeOrders.isEmpty) return _buildEmptyState('No active orders right now.');
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + bottomInset),
      itemCount: activeOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildActiveOrderCard(activeOrders[index]),
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    final bool riderConfirmed = order.riderConfirmedDelivery || order.status == OrderStatus.delivered;
    final bool customerConfirmed = order.customerConfirmedReceipt || _confirmedOrderIds.contains(order.id);
    final bool isConfirming = _confirmingOrderIds.contains(order.id);

    int currentStep = 0;
    if (order.status == OrderStatus.pending) currentStep = 0;
    if (order.status == OrderStatus.refilling) currentStep = 1;
    if (order.status == OrderStatus.outForDelivery) currentStep = 2;
    if (riderConfirmed) currentStep = 3;

    final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.refilling;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riderConfirmed ? AppColors.emerald200 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER DETAILS', style: _ts(size: 10, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('#${order.orderNumber}', style: _ts(size: 16, weight: FontWeight.bold, color: AppColors.textLight)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riderConfirmed ? AppColors.emerald50 : AppColors.sky50,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: riderConfirmed ? AppColors.emerald200 : AppColors.sky200),
                ),
                child: Text(
                  riderConfirmed
                      ? 'Delivered by Driver'
                      : (order.status == OrderStatus.outForDelivery
                      ? 'Out for delivery'
                      : (order.status == OrderStatus.refilling ? 'Refilling' : 'Order Placed')),
                  style: _ts(
                    size: 11,
                    weight: FontWeight.bold,
                    color: riderConfirmed ? AppColors.emerald700 : AppColors.primarySky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActiveStepper(currentStep),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.sky50, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, size: 16, color: AppColors.primarySky),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress ?? 'No Address Provided',
                      style: _ts(size: 13, weight: FontWeight.bold, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORDER ITEMS', style: _ts(size: 10, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                for (int i = 0; i < order.items.length; i++) ...[
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.water_drop_outlined, size: 15, color: AppColors.primarySky),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.items[i].quantity}× ${order.items[i].name}',
                          style: _ts(size: 13, weight: FontWeight.bold, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('₱${order.items[i].totalPrice.toStringAsFixed(2)}', style: _ts(size: 13, weight: FontWeight.bold, color: AppColors.textLight)),
                    ],
                  ),
                  if (i < order.items.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.slate200),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.isPaid ? 'Paid via ${order.paymentMethod.name.toUpperCase()}' : 'Cash on Delivery',
                      style: _ts(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        Text('Total: ', style: _ts(size: 12, color: AppColors.textSecondary)),
                        Text('₱${order.totalAmount.toStringAsFixed(2)}', style: _ts(size: 16, weight: FontWeight.w800, color: AppColors.primarySky)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions Section in Active Orders Card
          Row(
            children: [
              // Order Received button (gray when disabled, blue when ready, green when received)
              Expanded(
                child: _buildOrderReceivedButton(
                  order: order,
                  riderConfirmed: riderConfirmed,
                  customerConfirmed: customerConfirmed,
                  isConfirming: isConfirming,
                ),
              ),

              // Secondary contextual actions
              if (order.status == OrderStatus.outForDelivery) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerMapScreen(order: order)));
                  },
                  icon: const Icon(Icons.near_me, size: 15),
                  label: const Text('Live Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primarySky,
                    side: const BorderSide(color: AppColors.primarySky),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else if (riderConfirmed) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _openProofOfDelivery(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primarySky,
                    side: const BorderSide(color: AppColors.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Proof', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ] else if (canCancel) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _cancelOrder(order.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rose600,
                    side: const BorderSide(color: AppColors.rose200),
                    backgroundColor: AppColors.rose50,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepper(int currentStep) {
    double progress = 0.15;
    if (currentStep == 1) progress = 0.50;
    if (currentStep == 2) progress = 0.85;
    if (currentStep >= 3) progress = 1.0;

    Widget stepCircle(int index, IconData icon, bool isActive) {
      final isCurrent = index == currentStep;
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySky : AppColors.slate200,
          shape: BoxShape.circle,
          border: isCurrent ? Border.all(color: AppColors.sky200, width: 3) : null,
        ),
        child: Icon(icon, size: 15, color: isActive ? Colors.white : AppColors.slate400),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 16,
              right: 16,
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(100)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(100))),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                stepCircle(0, Icons.receipt_long, currentStep >= 0),
                stepCircle(1, Icons.water_drop, currentStep >= 1),
                stepCircle(2, Icons.local_shipping, currentStep >= 2),
                stepCircle(3, Icons.check_circle, currentStep >= 3),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Placed', style: _ts(size: 11, weight: currentStep >= 0 ? FontWeight.bold : FontWeight.normal, color: currentStep >= 0 ? AppColors.primarySky : AppColors.slate400)),
            Text('Refilling', style: _ts(size: 11, weight: currentStep >= 1 ? FontWeight.bold : FontWeight.normal, color: currentStep >= 1 ? AppColors.primarySky : AppColors.slate400)),
            Text('Delivery', style: _ts(size: 11, weight: currentStep >= 2 ? FontWeight.bold : FontWeight.normal, color: currentStep >= 2 ? AppColors.primarySky : AppColors.slate400)),
            Text('Done', style: _ts(size: 11, weight: currentStep >= 3 ? FontWeight.bold : FontWeight.normal, color: currentStep >= 3 ? AppColors.primarySky : AppColors.slate400)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderHistoryList(List<OrderModel> historyOrders, double bottomInset) {
    final now = DateTime.now();
    List<OrderModel> displayed = historyOrders.where((order) {
      if (_orderHistoryFilter == 'all') return true;
      if (_orderHistoryFilter == 'delivered') return order.status == OrderStatus.delivered;
      if (_orderHistoryFilter == 'cancelled') return order.status == OrderStatus.cancelled;
      if (_orderHistoryFilter == 'month') return order.createdAt.year == now.year && order.createdAt.month == now.month;
      return true;
    }).toList();

    final sq = _historySearchCtrl.text.trim().toLowerCase();
    if (sq.isNotEmpty) {
      displayed = displayed.where((o) => o.orderNumber.toLowerCase().contains(sq) || o.items.any((i) => i.name.toLowerCase().contains(sq))).toList();
    }

    final int allC = historyOrders.length;
    final int delC = historyOrders.where((o) => o.status == OrderStatus.delivered).length;
    final int moC = historyOrders.where((o) => o.createdAt.month == now.month && o.createdAt.year == now.year).length;
    final int canC = historyOrders.where((o) => o.status == OrderStatus.cancelled).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + bottomInset),
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: _historySearchCtrl,
            onChanged: (_) => setState(() {}),
            style: _ts(size: 13, color: AppColors.textLight),
            decoration: InputDecoration(
              hintText: 'Search order ID or item...',
              hintStyle: _ts(size: 13, color: AppColors.slate400),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildHistoryFilter('all', 'All ($allC)'),
              const SizedBox(width: 8),
              _buildHistoryFilter('delivered', 'Delivered ($delC)'),
              const SizedBox(width: 8),
              _buildHistoryFilter('month', 'This Month ($moC)'),
              const SizedBox(width: 8),
              _buildHistoryFilter('cancelled', 'Cancelled ($canC)'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (displayed.isEmpty)
          _buildEmptyState('No orders match your filter.')
        else
          ...displayed.map((o) => _buildOrderHistoryCard(o)),
      ],
    );
  }

  Widget _buildHistoryFilter(String filterKey, String label) {
    final active = _orderHistoryFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _orderHistoryFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? AppColors.primarySky : AppColors.slate200),
        ),
        child: Text(
          label,
          style: _ts(
            size: 12,
            weight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    final statusLabel = isDelivered ? 'Delivered' : (isCancelled ? 'Cancelled' : 'Pending');
    final Color chipBg = isDelivered ? AppColors.emerald50 : (isCancelled ? AppColors.rose50 : AppColors.slate100);
    final Color chipText = isDelivered ? AppColors.emerald700 : (isCancelled ? AppColors.rose600 : AppColors.slate600);

    final String itemsStr = order.items.map((i) => '${i.quantity}× ${i.name}').join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('#${order.orderNumber}', style: _ts(size: 14, weight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(width: 8),
                  Text(_formatDate(order.createdAt), style: _ts(size: 11, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: _ts(size: 10, weight: FontWeight.bold, color: chipText)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 16, color: isCancelled ? AppColors.slate400 : AppColors.primarySky),
              const SizedBox(width: 6),
              Expanded(
                child: Text(itemsStr, style: _ts(size: 13, weight: FontWeight.w500, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${order.totalAmount.toStringAsFixed(2)}',
                style: _ts(
                  size: 15,
                  weight: FontWeight.bold,
                  color: isCancelled ? AppColors.slate400 : AppColors.textLight,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),

          // Clean History Actions: Proof of delivery on left, Refund + Reorder on right (No Order Received button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isDelivered)
                InkWell(
                  onTap: () => _openProofOfDelivery(order),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.primarySky),
                      const SizedBox(width: 4),
                      Text('Proof of Delivery', style: _ts(size: 11, weight: FontWeight.bold, color: AppColors.primarySky)),
                    ],
                  ),
                )
              else
                Text(
                  isCancelled ? 'Cancelled' : 'Paid via ${order.paymentMethod.name}',
                  style: _ts(size: 11, color: AppColors.textSecondary),
                ),

              Row(
                children: [
                  if (!isCancelled) ...[
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerRefundRequestScreen(
                              order: order,
                              onSubmit: (reason, description, gcashName, gcashNumber, photoUrl) => _firestoreService.submitRefundRequest(
                                orderId: order.id,
                                orderNumber: order.orderNumber,
                                customerId: order.customerId ?? '',
                                customerName: order.customerName,
                                reason: reason,
                                description: description,
                                gcashName: gcashName,
                                gcashNumber: gcashNumber,
                                amount: order.totalAmount,
                                itemsSummary: order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                                photoUrl: photoUrl,
                              ),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.slate200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text('Refund', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate600)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: () => _reorder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Reorder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundsList(List<RefundModel> refunds, double bottomInset) {
    if (refunds.isEmpty) return _buildEmptyState('No active refund requests.');
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + bottomInset),
      itemCount: refunds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildRefundCard(refunds[index]),
    );
  }

  Widget _buildRefundCard(RefundModel r) {
    final String itemsStr = r.itemsSummary.isEmpty ? 'Refund Request' : r.itemsSummary;

    final Color statusColor;
    final Color badgeBg;
    final Color badgeBorder;
    final String badgeLabel;
    switch (r.status) {
      case RefundStatus.pending:
        statusColor = AppColors.amber700;
        badgeBg = AppColors.amber50;
        badgeBorder = AppColors.amber200;
        badgeLabel = 'Under Review';
        break;
      case RefundStatus.approved:
        statusColor = AppColors.primarySky;
        badgeBg = AppColors.sky50;
        badgeBorder = AppColors.sky200;
        badgeLabel = 'Approved';
        break;
      case RefundStatus.processed:
        statusColor = AppColors.emerald700;
        badgeBg = AppColors.emerald50;
        badgeBorder = AppColors.emerald200;
        badgeLabel = 'Completed';
        break;
      case RefundStatus.rejected:
        statusColor = AppColors.rose600;
        badgeBg = AppColors.rose50;
        badgeBorder = AppColors.rose200;
        badgeLabel = 'Declined';
        break;
    }

    final bool isRejected = r.status == RefundStatus.rejected;
    final bool isProcessed = r.status == RefundStatus.processed;
    final bool isApprovedOrLater = r.status == RefundStatus.approved || isProcessed;
    final double widthFactor = isProcessed ? 1.0 : (isApprovedOrLater ? 0.70 : 0.40);
    final IconData step2Icon = isRejected ? Icons.close : (isApprovedOrLater ? Icons.check : Icons.sync);
    final IconData step3Icon = isProcessed ? Icons.check : Icons.lock;
    final Color step3Bg = isProcessed ? statusColor : AppColors.slate200;
    final Color step3IconColor = isProcessed ? Colors.white : AppColors.slate400;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('#${r.orderNumber}', style: _ts(size: 14, weight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(width: 8),
                  Text(_formatDate(r.requestedAt), style: _ts(size: 11, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(badgeLabel, style: _ts(size: 10, weight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                child: Icon(Icons.water_drop_outlined, size: 16, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemsStr, style: _ts(size: 13, weight: FontWeight.bold, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(r.reason.isEmpty ? 'Refund claimed' : r.reason, style: _ts(size: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('₱${r.amount.toStringAsFixed(2)}', style: _ts(size: 15, weight: FontWeight.bold, color: AppColors.primarySky)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(100)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: widthFactor,
                            child: Container(decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(100))),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 13, color: Colors.white),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: badgeBorder, width: 2),
                            ),
                            child: Icon(step2Icon, size: 13, color: Colors.white),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: step3Bg, shape: BoxShape.circle),
                            child: Icon(step3Icon, size: 13, color: step3IconColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket Lodged', style: _ts(size: 10, weight: FontWeight.bold, color: statusColor)),
                    Text('Audit Review', style: _ts(size: 10, weight: FontWeight.bold, color: statusColor)),
                    Text('Settlement', style: _ts(size: 10, weight: FontWeight.bold, color: isProcessed ? statusColor : AppColors.slate400)),
                  ],
                ),
              ],
            ),
          ),
          if (r.resolutionType == 'redelivery' && r.redeliveryScheduledAt != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.emerald200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: AppColors.emerald700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _redeliveryNoticeText(r.redeliveryScheduledAt),
                      style: _ts(size: 11, weight: FontWeight.bold, color: AppColors.emerald700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _redeliveryNoticeText(DateTime? scheduledAt) {
    if (scheduledAt == null) return 'Priority Redelivery scheduled';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour24 = scheduledAt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    final dateStr = '${months[scheduledAt.month - 1]} ${scheduledAt.day}, ${scheduledAt.year}';
    return 'Redelivery scheduled for $dateStr at $hour12:$minute $ampm';
  }
}