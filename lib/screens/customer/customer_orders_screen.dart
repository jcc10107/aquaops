import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_header.dart';
import 'customer_map_screen.dart';

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
  String _orderHistoryFilter = 'All Orders';
  final TextEditingController _historySearchCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  static const Color _background = Color(0xFFF8FAFC);
  static const Color _surfaceLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainer = Color(0xFFEAEDFF);
  static const Color _surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color _surfaceFrost = Color(0xFFE0F2FE);
  static const Color _surfaceIce = Color(0xFFF0F9FF);
  static const Color _surfaceDim = Color(0xFFD2D9F4);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _outline = Color(0xFF707881);
  static const Color _primary = Color(0xFF0284C7);
  static const Color _primaryStart = Color(0xFF00A8E8);
  static const Color _primaryEnd = Color(0xFF0077B6);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _secondaryContainer = Color(0xFF6CF8BB);
  static const Color _onSecondaryContainer = Color(0xFF00714D);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _errorText = Color(0xFF93000A);

  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryStart, _primaryEnd],
  );

  TextStyle _t(
      double size,
      FontWeight weight,
      Color color, {
        double? height,
        double? letterSpacing,
        TextDecoration? decoration,
        Color? decorationColor,
      }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

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
        const SnackBar(
          content: Text('Order Cancelled.'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: AppColors.error,
        ),
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

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.myOrders
        .where((o) =>
    o.status != OrderStatus.delivered &&
        o.status != OrderStatus.cancelled)
        .toList();
    final historyOrders = widget.myOrders
        .where((o) =>
    o.status == OrderStatus.delivered ||
        o.status == OrderStatus.cancelled)
        .toList();

    final Widget switcher =
    _buildOrderSwitcher(activeOrders.length, historyOrders.length);
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      color: _background,
      padding: EdgeInsets.only(top: topInset + CustomHeader.contentHeight),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: _ordersTab == 0
              ? _buildActiveOrdersList(activeOrders, switcher)
              : _buildOrderHistoryList(historyOrders, switcher),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: selected
              ? BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x590284C7),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          )
              : const BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showDot)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: _cyan,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _cyan, blurRadius: 6)],
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _t(
                  13,
                  FontWeight.w700,
                  selected ? Colors.white : _onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : _surfaceDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: _t(
                    10,
                    FontWeight.w700,
                    selected ? Colors.white : _onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSwitcher(int activeCount, int historyCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            label: 'Active Orders',
            count: activeCount,
            showDot: widget.hasActiveOrder,
          ),
          _buildTabButton(
            index: 1,
            label: 'Order History',
            count: historyCount,
            showDot: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchDesk() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceFrost,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, size: 20, color: _primary),
              const SizedBox(width: 8),
              Text(
                'AquaOps Dispatch Desk',
                style: _t(13, FontWeight.w500, _onSurface, height: 1.4),
              ),
            ],
          ),
          Text(
            'GET HELP',
            style: _t(
              10,
              FontWeight.w800,
              _primary,
              height: 1.2,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text, style: _t(13, FontWeight.w500, _outline)),
      ),
    );
  }

  Widget _buildActiveOrdersList(
      List<OrderModel> activeOrders,
      Widget switcher,
      ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 112),
      children: [
        switcher,
        const SizedBox(height: 16),
        if (activeOrders.isEmpty)
          _buildEmptyState('No active orders right now.')
        else
          for (final order in activeOrders) ...[
            _buildActiveOrderCard(order),
            const SizedBox(height: 16),
          ],
        _buildDispatchDesk(),
      ],
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    final int currentStep = order.status == OrderStatus.outForDelivery ? 2 : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT SHIPMENT',
                      style: _t(
                        10,
                        FontWeight.w800,
                        _primary,
                        height: 1.2,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.orderNumber,
                      style: _t(
                        17,
                        FontWeight.w700,
                        _onSurface,
                        height: 1.4,
                        letterSpacing: -0.17,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _surfaceFrost,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _cyan,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _cyan, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status == OrderStatus.outForDelivery
                          ? 'Out for delivery'
                          : 'Placed',
                      style: _t(11, FontWeight.w700, _primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepper(currentStep),
          const SizedBox(height: 16),
          if (order.status == OrderStatus.outForDelivery) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceIce,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _surfaceFrost,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          size: 20,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rider: Express Fleet',
                            style: _t(
                              10,
                              FontWeight.w400,
                              _onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ETA: In Route',
                            style: _t(
                              17,
                              FontWeight.w700,
                              _primary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _surfaceLowest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, size: 18, color: _primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _surfaceFrost,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 16,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: _t(
                          10,
                          FontWeight.w400,
                          _onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress ?? '',
                        style: _t(
                          13,
                          FontWeight.w500,
                          _onSurface,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceIce,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HYDRATION MANIFEST',
                  style: _t(
                    10,
                    FontWeight.w800,
                    _onSurfaceVariant,
                    height: 1.2,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < order.items.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: _surfaceLowest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_drink,
                                size: 16,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${order.items[i].quantity}× ${order.items[i].name}',
                                style: _t(
                                  13,
                                  FontWeight.w500,
                                  _onSurface,
                                  height: 1.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₱${order.items[i].totalPrice.toStringAsFixed(2)}',
                        style: _t(
                          13,
                          FontWeight.w700,
                          _onSurface,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (i < order.items.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x10000000), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: _secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.isPaid
                                ? (order.paymentMethod == PaymentMethod.gcash
                                ? 'Paid via GCash'
                                : 'Paid')
                                : 'Cash on Delivery',
                            style: _t(
                              10,
                              FontWeight.w800,
                              _secondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Total',
                            style: _t(
                              10,
                              FontWeight.w500,
                              _onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₱${order.totalAmount.toStringAsFixed(2)}',
                            style: _t(
                              17,
                              FontWeight.w700,
                              _primary,
                              height: 1.4,
                            ),
                          ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerMapScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.near_me,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Live Map Route',
                    style: _t(13, FontWeight.w700, Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0x590284C7),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _cancelOrder(order.id),
                icon: const Icon(Icons.close, size: 18, color: _errorText),
                label: Text(
                  'Cancel',
                  style: _t(11, FontWeight.w700, _errorText),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorContainer,
                  foregroundColor: _errorText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    final double progress = currentStep == 0
        ? 0.0
        : (currentStep == 1 ? 0.33 : (currentStep == 2 ? 0.75 : 1.0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepperDot(0, currentStep, Icons.receipt_long),
                    _buildStepperDot(1, currentStep, Icons.water_drop),
                    _buildStepperDot(2, currentStep, Icons.local_shipping),
                    _buildStepperDot(3, currentStep, Icons.check_circle),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepLabel('Placed', true),
              _stepLabel('Filling', true),
              _stepLabel('Delivery', currentStep >= 2),
              _stepLabel('Done', currentStep >= 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepLabel(String text, bool active) {
    return Text(
      text,
      style: _t(
        10,
        active ? FontWeight.w700 : FontWeight.w400,
        active ? _primary : _outline,
        height: 1.2,
      ),
    );
  }

  Widget _buildStepperDot(int stepIndex, int currentStep, IconData icon) {
    final bool isActive = currentStep >= stepIndex;
    final bool isCurrent = currentStep == stepIndex;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? _primary : _surfaceContainer,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? const [BoxShadow(color: Color(0x660284C7), blurRadius: 12)]
            : const [],
        border: isCurrent ? Border.all(color: _surfaceFrost, width: 4) : null,
      ),
      child: Icon(
        icon,
        size: 16,
        color: isActive ? Colors.white : _outline,
      ),
    );
  }

  Widget _buildOrderHistoryList(
      List<OrderModel> historyOrders,
      Widget switcher,
      ) {
    final now = DateTime.now();
    List<OrderModel> displayedHistory = historyOrders.where((order) {
      if (_orderHistoryFilter == 'All Orders') return true;
      if (_orderHistoryFilter == 'Delivered') {
        return order.status == OrderStatus.delivered;
      }
      if (_orderHistoryFilter == 'Cancelled') {
        return order.status == OrderStatus.cancelled;
      }
      if (_orderHistoryFilter == 'Refunded') {
        return order.status == OrderStatus.cancelled;
      }
      if (_orderHistoryFilter == 'This Month') {
        return order.createdAt.year == now.year &&
            order.createdAt.month == now.month;
      }
      return true;
    }).toList();

    final searchQuery = _historySearchCtrl.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      displayedHistory = displayedHistory.where((order) {
        return order.orderNumber.toLowerCase().contains(searchQuery) ||
            order.items.any((i) => i.name.toLowerCase().contains(searchQuery));
      }).toList();
    }

    final int allCount = historyOrders.length;
    final int delCount =
        historyOrders.where((o) => o.status == OrderStatus.delivered).length;
    final int moCount = historyOrders
        .where((o) =>
    o.createdAt.month == now.month && o.createdAt.year == now.year)
        .length;
    final int canCount =
        historyOrders.where((o) => o.status == OrderStatus.cancelled).length;
    final int refCount = canCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 112),
      children: [
        switcher,
        const SizedBox(height: 16),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 4),
            ],
          ),
          child: TextField(
            controller: _historySearchCtrl,
            onChanged: (_) => setState(() {}),
            style: _t(13, FontWeight.w500, _onSurface),
            decoration: InputDecoration(
              hintText: 'Search Order ID or product...',
              hintStyle: _t(13, FontWeight.w500, _outline),
              prefixIcon: const Icon(Icons.search, size: 20, color: _outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              _buildHistoryFilterChip('All Orders', 'All ($allCount)'),
              const SizedBox(width: 6),
              _buildHistoryFilterChip('Delivered', 'Delivered ($delCount)'),
              const SizedBox(width: 6),
              _buildHistoryFilterChip('This Month', 'This Month ($moCount)'),
              const SizedBox(width: 6),
              _buildHistoryFilterChip('Cancelled', 'Cancelled ($canCount)'),
              const SizedBox(width: 6),
              _buildHistoryFilterChip(
                'Refunded',
                'Refunded ($refCount)',
                refunded: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (displayedHistory.isEmpty)
          _buildEmptyState('No orders match your filter.')
        else
          ...displayedHistory.map((order) => _buildOrderHistoryCard(order)),
        const SizedBox(height: 4),
        _buildDispatchDesk(),
      ],
    );
  }

  Widget _buildHistoryFilterChip(
      String actualFilter,
      String displayLabel, {
        bool refunded = false,
      }) {
    final bool isActive = _orderHistoryFilter == actualFilter;
    return GestureDetector(
      onTap: () => setState(() => _orderHistoryFilter = actualFilter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? _gradient : null,
          color: isActive ? null : _surfaceLowest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? const [
            BoxShadow(
              color: Color(0x5900A8E8),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
              : const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (refunded) ...[
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: isActive ? Colors.white : _onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              displayLabel,
              style: _t(
                11,
                isActive ? FontWeight.w700 : FontWeight.w500,
                isActive ? Colors.white : _onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildReorderButton(OrderModel order) {
    return ElevatedButton.icon(
      onPressed: () => _reorder(order),
      icon: const Icon(Icons.repeat, size: 16, color: Colors.white),
      label: Text(
        'Reorder',
        style: _t(11, FontWeight.w700, Colors.white, height: 1.2),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildRefundButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.currency_exchange,
            size: 16,
            color: _onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Refund',
            style: _t(11, FontWeight.w700, _onSurfaceVariant, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final statusLabel =
    isDelivered ? 'Delivered' : (isCancelled ? 'Cancelled' : 'Pending');
    final statusIcon = isDelivered
        ? Icons.check_circle
        : (isCancelled ? Icons.cancel : Icons.schedule);

    final chipBg = isDelivered
        ? _secondaryContainer
        : (isCancelled ? _errorContainer : _surfaceContainer);
    final chipText = isDelivered
        ? _onSecondaryContainer
        : (isCancelled ? _errorText : _outline);

    final orderDate =
        '${_monthName(order.createdAt.month)} ${order.createdAt.day}, ${order.createdAt.year}';
    final shortDate =
        '${_monthName(order.createdAt.month)} ${order.createdAt.day}';
    final paymentLabel =
    order.paymentMethod == PaymentMethod.gcash ? 'GCash' : 'Cash';

    final String itemsSummary = order.items.isEmpty
        ? ''
        : order.items.map((i) => '${i.quantity}× ${i.name}').join(', ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.orderNumber,
                        style: _t(
                          17,
                          FontWeight.w700,
                          _onSurface,
                          height: 1.4,
                          letterSpacing: -0.17,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        orderDate,
                        style: _t(10, FontWeight.w800, _outline, height: 1.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: chipText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: _t(10, FontWeight.w800, chipText, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.local_drink,
                size: 18,
                color: isCancelled ? _outline : _primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  itemsSummary,
                  style: _t(
                    13,
                    FontWeight.w500,
                    _onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${order.totalAmount.toStringAsFixed(2)}',
                style: _t(
                  17,
                  FontWeight.w700,
                  isCancelled ? _outline : _primary,
                  height: 1.4,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                  decorationColor: _outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: _surfaceContainerLow,
          ),
          const SizedBox(height: 8),
          if (isCancelled)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: _secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Refunded • $shortDate',
                          style: _t(
                            10,
                            FontWeight.w500,
                            _secondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildReorderButton(order),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Paid with $paymentLabel • Express Drop',
                    style: _t(
                      10,
                      FontWeight.w500,
                      _onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRefundButton(),
                    const SizedBox(width: 8),
                    _buildReorderButton(order),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}