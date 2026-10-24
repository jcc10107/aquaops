import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart'; // Added centralized layout constants
import '../../core/theme/app_typography.dart';
import '../../models/order_model.dart';
import '../../models/refund_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import '../../widgets/screen_title_block.dart';
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

  static const Color _surfaceDim = Color(0xFFD2D9F4);

  TextStyle _ts({
    required double size,
    required FontWeight weight,
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

  TextStyle get _labelSm => _ts(size: 10, weight: FontWeight.w800, color: AppColors.outline, height: 1.2, letterSpacing: 0.6);
  TextStyle get _labelMd => _ts(size: 11, weight: FontWeight.w700, color: AppColors.textSecondary, height: 1.27, letterSpacing: 0.22);
  TextStyle get _labelLg => _ts(size: 13, weight: FontWeight.w700, color: AppColors.textLight, height: 1.23, letterSpacing: 0.13);
  TextStyle get _bodyMd => _ts(size: 13, weight: FontWeight.w500, color: AppColors.textLight, height: 1.38);
  TextStyle get _headlineSm => _ts(size: 17, weight: FontWeight.w700, color: AppColors.textLight, height: 1.41, letterSpacing: -0.17);

  @override
  void dispose() {
    _historySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.cancelOrder(orderId);
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
      barrierColor: const Color(0xCC020617),
      builder: (ctx) => ProofOfDeliveryDialog(
        title: 'PROOF OF DELIVERY',
        subtitle: 'Order ${order.orderNumber}',
        imageUrl: url,
        chromeHeight: 250,
        badgeIcon: Icons.verified,
        badgeIconColor: const Color(0xFF34D399),
        badgeText: 'Rider Verified Drop-off',
        detailsChild: RichText(
          text: TextSpan(
            style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate600, height: 1.5),
            children: [
              const TextSpan(text: 'Delivered: '),
              TextSpan(
                text: deliveredAt != null ? _formatDateTime(deliveredAt) : 'Time not recorded',
                style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.surfaceDark),
              ),
              if (order.assignedRiderName != null && order.assignedRiderName!.trim().isNotEmpty) ...[
                const TextSpan(text: '\nRider: '),
                TextSpan(
                  text: order.assignedRiderName!.trim(),
                  style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.surfaceDark),
                ),
              ],
              if (recipient != null) ...[
                const TextSpan(text: '\nReceived by: '),
                TextSpan(
                  text: recipient,
                  style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.surfaceDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    return const ScreenTitleBlock(
      badgeText: 'CUSTOMER HUB',
      title: 'My Orders',
      icon: Icons.shopping_bag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.myOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
    final historyOrders = widget.myOrders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList();

    final String? uid = AuthService().currentUserId;
    final double topInset = MediaQuery.of(context).padding.top;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Container(
        padding: EdgeInsets.only(top: topInset + CustomHeader.contentHeight),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: StreamBuilder<List<RefundModel>>(
              stream: uid == null ? Stream<List<RefundModel>>.empty() : _firestoreService.getRefundRequestsForCustomerStream(uid),
              builder: (context, snapshot) {
                final refunds = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: 16),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: selected
              ? BoxDecoration(
            color: AppColors.primarySky,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x590284C7), blurRadius: 16, offset: Offset(0, 4))],
          )
              : const BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showDot && selected)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.cyanElectric,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.cyanElectric, blurRadius: 6)],
                  ),
                ),
              Text(
                label,
                style: _labelMd.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.2) : _surfaceDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: _labelSm.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSwitcher(int activeCount, int historyCount, int refundCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          _buildTabButton(index: 0, label: 'Active', count: activeCount, showDot: widget.hasActiveOrder),
          _buildTabButton(index: 1, label: 'History', count: historyCount, showDot: false),
          _buildTabButton(index: 2, label: 'Refunds', count: refundCount, showDot: false),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text, style: _bodyMd.copyWith(color: AppColors.outline)),
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
    final int currentStep = order.status == OrderStatus.outForDelivery ? 2 : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
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
                  Text('CURRENT SHIPMENT', style: _labelSm.copyWith(color: AppColors.primarySky)),
                  const SizedBox(height: 2),
                  Text(order.orderNumber, style: _headlineSm),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFrost,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.cyanElectric,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.cyanElectric, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status == OrderStatus.outForDelivery ? 'Out for delivery' : 'Placed',
                      style: _labelMd.copyWith(color: AppColors.primarySky),
                    ),
                  ],
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
                decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, size: 16, color: AppColors.primarySky),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: _labelSm.copyWith(color: AppColors.textSecondary, letterSpacing: 0)),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress ?? 'No Address Provided',
                      style: _bodyMd.copyWith(height: 1.2),
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
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HYDRATION MANIFEST', style: _labelSm.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                for (int i = 0; i < order.items.length; i++) ...[
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.local_drink, size: 16, color: AppColors.primarySky),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.items[i].quantity}× ${order.items[i].name}',
                          style: _bodyMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('₱${order.items[i].totalPrice.toStringAsFixed(2)}', style: _labelLg),
                    ],
                  ),
                  if (i < order.items.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            order.isPaid ? 'Paid via ${order.paymentMethod.name}' : 'Cash on Delivery',
                            style: _labelSm.copyWith(color: AppColors.secondary, letterSpacing: 0),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Total', style: _labelSm.copyWith(color: AppColors.textSecondary, letterSpacing: 0)),
                          const SizedBox(width: 4),
                          Text('₱${order.totalAmount.toStringAsFixed(2)}', style: _headlineSm.copyWith(color: AppColors.primarySky)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerMapScreen(order: order)));
                  },
                  icon: const Icon(Icons.near_me, size: 20, color: Colors.white),
                  label: Text('Live Map Route', style: _labelLg.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0x590284C7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _cancelOrder(order.id),
                icon: const Icon(Icons.close, size: 18, color: AppColors.errorText),
                label: Text('Cancel', style: _labelMd.copyWith(color: AppColors.errorText)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorContainer,
                  foregroundColor: AppColors.errorText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepper(int currentStep) {
    double progress = 0.0;
    if (currentStep == 0) progress = 0.15;
    if (currentStep == 1) progress = 0.5;
    if (currentStep == 2) progress = 0.85;
    if (currentStep >= 3) progress = 1.0;

    Widget stepCircle(int index, IconData icon, bool isActive) {
      final isCurrent = index == currentStep;
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySky : AppColors.surfaceContainer,
          shape: BoxShape.circle,
          border: isCurrent ? Border.all(color: AppColors.surfaceFrost, width: 4) : null,
          boxShadow: isCurrent ? const [BoxShadow(color: Color(0x660284C7), blurRadius: 12)] : null,
        ),
        child: Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.outline),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                right: 16,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(999))),
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
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Placed', style: _labelSm.copyWith(color: currentStep >= 0 ? AppColors.primarySky : AppColors.outline, letterSpacing: 0)),
            Text('Filling', style: _labelSm.copyWith(color: currentStep >= 1 ? AppColors.primarySky : AppColors.outline, letterSpacing: 0)),
            Text('Delivery', style: _labelSm.copyWith(color: currentStep >= 2 ? AppColors.primarySky : AppColors.outline, letterSpacing: 0)),
            Text('Done', style: _labelSm.copyWith(color: currentStep >= 3 ? AppColors.primarySky : AppColors.outline, letterSpacing: 0)),
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
      if (_orderHistoryFilter == 'refunded') return order.status == OrderStatus.cancelled;
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
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
          ),
          child: TextField(
            controller: _historySearchCtrl,
            onChanged: (_) => setState(() {}),
            style: _bodyMd,
            decoration: InputDecoration(
              hintText: 'Search Order ID or product...',
              hintStyle: _bodyMd.copyWith(color: AppColors.outline),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.outline),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              _buildHistoryFilter('all', 'All ($allC)'),
              const SizedBox(width: 6),
              _buildHistoryFilter('delivered', 'Delivered ($delC)'),
              const SizedBox(width: 6),
              _buildHistoryFilter('month', 'This Month ($moC)'),
              const SizedBox(width: 6),
              _buildHistoryFilter('cancelled', 'Cancelled ($canC)'),
              const SizedBox(width: 6),
              _buildHistoryFilter('refunded', 'Refunded ($canC)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x590284C7), blurRadius: 8, offset: Offset(0, 2))]
              : const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)],
        ),
        child: Text(
          label,
          style: _labelMd.copyWith(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildOrderHistoryCard(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    final statusIcon = isDelivered ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.schedule);
    final statusLabel = isDelivered ? 'Delivered' : (isCancelled ? 'Cancelled' : 'Pending');

    final Color chipBg = isDelivered ? AppColors.secondaryContainer : (isCancelled ? AppColors.errorContainer : AppColors.surfaceContainer);
    final Color chipText = isDelivered ? AppColors.onSecondaryContainer : (isCancelled ? AppColors.errorText : AppColors.outline);

    final String itemsStr = order.items.map((i) => '${i.quantity}× ${i.name}').join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(order.orderNumber, style: _headlineSm),
                  const SizedBox(width: 8),
                  Text(_formatDate(order.createdAt), style: _labelSm.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: chipText),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: _labelSm.copyWith(color: chipText, letterSpacing: 0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.water_drop, size: 18, color: isCancelled ? AppColors.outline : AppColors.primarySky),
              const SizedBox(width: 8),
              Expanded(
                child: Text(itemsStr, style: _bodyMd.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${order.totalAmount.toStringAsFixed(2)}',
                style: _headlineSm.copyWith(
                  color: isCancelled ? AppColors.outline : AppColors.primarySky,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.surfaceContainerLow),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isCancelled
                      ? 'Refunded to ${order.paymentMethod.name}'
                      : 'Paid with ${order.paymentMethod.name} • Standard Drop',
                  style: _labelSm.copyWith(color: isCancelled ? AppColors.secondary : AppColors.textSecondary, letterSpacing: 0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  if (!isCancelled) ...[
                    InkWell(
                      onTap: () {
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
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.currency_exchange, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Refund', style: _labelMd.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () => _reorder(order),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySky,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color(0x290284C7), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Reorder', style: _labelMd.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isDelivered) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _openProofOfDelivery(order),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('View Proof of Delivery', style: _labelMd.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
        statusColor = AppColors.amber500;
        badgeBg = AppColors.amber50;
        badgeBorder = AppColors.amber200;
        badgeLabel = 'Under Review';
        break;
      case RefundStatus.approved:
        statusColor = AppColors.secondary;
        badgeBg = AppColors.secondaryContainer.withValues(alpha: 0.25);
        badgeBorder = AppColors.secondaryContainer;
        badgeLabel = 'Approved';
        break;
      case RefundStatus.processed:
        statusColor = AppColors.secondary;
        badgeBg = AppColors.secondaryContainer.withValues(alpha: 0.25);
        badgeBorder = AppColors.secondaryContainer;
        badgeLabel = 'Completed';
        break;
      case RefundStatus.rejected:
        statusColor = AppColors.errorText;
        badgeBg = AppColors.errorContainer;
        badgeBorder = AppColors.errorContainer;
        badgeLabel = 'Declined';
        break;
    }
    final Color badgeTextColor = r.status == RefundStatus.pending ? AppColors.amber800 : statusColor;

    final bool isRejected = r.status == RefundStatus.rejected;
    final bool isProcessed = r.status == RefundStatus.processed;
    final bool isApprovedOrLater = r.status == RefundStatus.approved || isProcessed;
    final double widthFactor = isProcessed ? 1.0 : (isApprovedOrLater ? 0.75 : 0.5);
    final IconData step2Icon = isRejected ? Icons.close : (isApprovedOrLater ? Icons.check : Icons.sync);
    final IconData step3Icon = isProcessed ? Icons.check : Icons.lock;
    final Color step3Bg = isProcessed ? statusColor : AppColors.surfaceContainer;
    final Color step3IconColor = isProcessed ? Colors.white : AppColors.outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeBorder.withValues(alpha: 0.6)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(r.orderNumber, style: _headlineSm),
                  const SizedBox(width: 8),
                  Text(_formatDate(r.requestedAt), style: _labelSm.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(badgeLabel, style: _labelSm.copyWith(color: badgeTextColor, letterSpacing: 0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                child: Icon(Icons.water_drop, size: 16, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemsStr, style: _bodyMd.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(r.reason.isEmpty ? 'Refund reported' : r.reason, style: _labelSm.copyWith(letterSpacing: 0), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('₱${r.amount.toStringAsFixed(2)}', style: _headlineSm.copyWith(color: AppColors.primarySky)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
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
                          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: widthFactor,
                            child: Container(decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(999))),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 13, color: Colors.white),
                          ),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: badgeBorder, width: 2),
                            ),
                            child: Icon(step2Icon, size: 13, color: Colors.white),
                          ),
                          Container(
                            width: 24, height: 24,
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
                    Text('Ticket Lodged', style: _labelSm.copyWith(color: badgeTextColor, letterSpacing: 0)),
                    Text('QA Audit', style: _labelSm.copyWith(color: badgeTextColor, letterSpacing: 0)),
                    Text('Refund Release', style: _labelSm.copyWith(color: isProcessed ? badgeTextColor : AppColors.outline, letterSpacing: 0)),
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
                color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondaryContainer),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _redeliveryNoticeText(r.redeliveryScheduledAt),
                      style: _labelSm.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600, letterSpacing: 0),
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