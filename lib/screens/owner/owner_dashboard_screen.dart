import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/inventory_model.dart';
import '../../models/shift_model.dart';
import '../../services/firestore_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final String _hubName = 'Drink 8 Water Refilling Station';
  final String _statusLabel = 'STATION ONLINE';
  String _period = 'today';

  final FirestoreService _firestoreService = FirestoreService();

  String get _dateLabel {
    switch (_period) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return 'Today';
    }
  }

  (DateTime, DateTime) _periodBounds() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case 'week':
        final startOfWeek = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
        return (startOfWeek, startOfWeek.subtract(const Duration(days: 7)));
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
        return (startOfMonth, startOfPrevMonth);
      default:
        return (startOfToday, startOfToday.subtract(const Duration(days: 1)));
    }
  }

  void _onOpenDispatchConsole() {
    Navigator.pushReplacementNamed(context, '/dispatch');
  }

  void _onManageSupplies() {
    Navigator.pushReplacementNamed(context, '/inventory');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Relaxed for tablet readability
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 130),
      child: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getAllOrdersStream(),
        builder: (context, ordersSnapshot) {
          final orders = ordersSnapshot.data ?? const <OrderModel>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHubHeaderSection(),
              const SizedBox(height: 24),
              _buildRevenueCard(orders),
              const SizedBox(height: 32),
              _buildDispatchSection(orders),
              const SizedBox(height: 32),
              StreamBuilder<List<InventoryModel>>(
                stream: _firestoreService.getInventoryStream(),
                builder: (context, invSnapshot) {
                  return _buildSuppliesSection(invSnapshot.data ?? const <InventoryModel>[]);
                },
              ),
              const SizedBox(height: 32),
              _buildReconciliationSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHubHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hubName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          color: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => setState(() => _period = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'today', child: Text('Today', style: TextStyle(fontSize: 14))),
            PopupMenuItem(value: 'week', child: Text('This Week', style: TextStyle(fontSize: 14))),
            PopupMenuItem(value: 'month', child: Text('This Month', style: TextStyle(fontSize: 14))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primarySky),
                const SizedBox(width: 6),
                Text(
                  _dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primarySky,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primarySky),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(List<OrderModel> orders) {
    final (periodStart, prevPeriodStart) = _periodBounds();

    final paidOrders = orders.where((o) => o.status == OrderStatus.delivered && o.isPaid);
    final periodOrders = paidOrders.where((o) => !o.revenueDate.isBefore(periodStart));
    final prevPeriodOrders = paidOrders.where(
          (o) => !o.revenueDate.isBefore(prevPeriodStart) && o.revenueDate.isBefore(periodStart),
    );

    final dailyGrossRevenue = periodOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final prevGrossRevenue = prevPeriodOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final cashInTill = periodOrders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final gcashQr = periodOrders
        .where((o) => o.paymentMethod == PaymentMethod.gcash)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    int roundGallons = 0;
    int slimGallons = 0;
    for (final order in periodOrders) {
      for (final item in order.items) {
        final name = item.name.toLowerCase();
        if (name.contains('round')) {
          roundGallons += item.quantity;
        } else if (name.contains('slim') || name.contains('alkaline')) {
          slimGallons += item.quantity;
        }
      }
    }
    final gallonsPumped = roundGallons + slimGallons;
    final ordersCompleted = periodOrders.length;

    final growthPercent = prevGrossRevenue == 0
        ? (dailyGrossRevenue > 0 ? 100.0 : 0.0)
        : (((dailyGrossRevenue - prevGrossRevenue) / prevGrossRevenue) * 100);

    final bool isPositiveGrowth = growthPercent >= 0;
    final Color growthColor = isPositiveGrowth ? AppColors.emerald600 : AppColors.rose600;
    final Color growthBgColor = isPositiveGrowth ? AppColors.emerald50 : AppColors.rose50;
    final IconData growthIcon = isPositiveGrowth ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: AppColors.primarySky, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GROSS REVENUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthBgColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(growthIcon, size: 14, color: growthColor),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositiveGrowth ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: growthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${dailyGrossRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'vs ₱${prevGrossRevenue.toStringAsFixed(0)} prior',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildRevenueMetricBox(
                  title: 'CASH IN TILL',
                  amount: cashInTill,
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.emerald600,
                  bgColor: AppColors.emerald50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueMetricBox(
                  title: 'GCASH / QR',
                  amount: gcashQr,
                  icon: Icons.qr_code_2_rounded,
                  color: AppColors.primarySky,
                  bgColor: AppColors.sky50,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.slate100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$gallonsPumped Gallons Pumped',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$roundGallons Round • $slimGallons Slim',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '$ordersCompleted',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueMetricBox({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSection(List<OrderModel> orders) {
    final activeDeliveries = orders.where((o) => o.status == OrderStatus.outForDelivery).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Dispatch Fleet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sky50,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.sky100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accentTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${activeDeliveries.length} En Route',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primarySky,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activeDeliveries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Column(
              children: [
                Icon(Icons.two_wheeler, color: AppColors.slate300, size: 32),
                SizedBox(height: 12),
                Text(
                  'No active deliveries right now',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...activeDeliveries.take(3).map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRiderCard(o),
          )),
        const SizedBox(height: 4),
        InkWell(
          onTap: _onOpenDispatchConsole,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySky,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Open Live Dispatch Console',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderCard(OrderModel order) {
    final itemSummary = order.items.isEmpty
        ? '—'
        : order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    final riderLabel = (order.assignedRiderName != null && order.assignedRiderName!.isNotEmpty)
        ? order.assignedRiderName!
        : 'Unassigned';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Delivering',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemSummary,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.slate100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.two_wheeler, size: 16, color: AppColors.slate400),
                  const SizedBox(width: 6),
                  Text(
                    riderLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliesSection(List<InventoryModel> supplies) {
    final visibleSupplies = supplies.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Supplies & Bottling Stock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            InkWell(
              onTap: _onManageSupplies,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Manage All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (visibleSupplies.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.slate300, size: 32),
                SizedBox(height: 12),
                Text(
                  'No inventory items yet',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 12.0;
              final int columns = constraints.maxWidth >= 600 ? 3 : (constraints.maxWidth >= 350 ? 2 : 1);
              final double itemWidth = (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: visibleSupplies.map((s) => SizedBox(
                  width: itemWidth,
                  child: _buildSupplyCard(s),
                )).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSupplyCard(InventoryModel supply) {
    final bool isLow = supply.isLowStock;
    final IconData icon = supply.category == 'water' ? Icons.water_drop : Icons.inventory_2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Icon(icon, size: 16, color: AppColors.slate500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLow ? AppColors.rose50 : AppColors.emerald50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLow ? 'LOW' : 'GOOD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLow ? AppColors.rose600 : AppColors.emerald600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${supply.currentStock}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isLow ? AppColors.rose600 : AppColors.textLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supply.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reconciliation Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<ShiftModel?>(
          stream: _firestoreService.getLatestShiftStream(),
          builder: (context, snapshot) {
            final shift = snapshot.data;
            final now = DateTime.now();
            final openedToday = shift != null &&
                shift.openedAt.year == now.year &&
                shift.openedAt.month == now.month &&
                shift.openedAt.day == now.day;

            if (shift == null || (shift.status == ShiftStatus.closed && !openedToday)) {
              return _buildReconciliationCard(
                icon: Icons.storefront,
                iconColor: AppColors.slate500,
                iconBgColor: AppColors.slate100,
                title: 'No Active Shift',
                subtitle: 'Staff haven\'t opened a shift today yet.',
                trailingLabel: null,
              );
            }

            if (shift.status == ShiftStatus.open) {
              return _buildReconciliationCard(
                icon: Icons.schedule,
                iconColor: AppColors.amber600,
                iconBgColor: AppColors.amber50,
                title: 'Shift In Progress',
                subtitle: 'Opened by ${shift.openedByName}\nFloat: ₱${shift.openingCash.toStringAsFixed(2)}',
                trailingLabel: 'In Progress',
                trailingColor: AppColors.amber600,
                trailingBgColor: AppColors.amber50,
              );
            }

            final discrepancy = shift.discrepancy ?? 0;
            final isBalanced = discrepancy.abs() < 0.01;

            return _buildReconciliationCard(
              icon: isBalanced ? Icons.check_circle_outline : Icons.error_outline,
              iconColor: isBalanced ? AppColors.emerald600 : AppColors.rose600,
              iconBgColor: isBalanced ? AppColors.emerald50 : AppColors.rose50,
              title: 'Closed by ${shift.closedByName}',
              subtitle: 'Counted: ₱${shift.closingCash?.toStringAsFixed(2) ?? '—'}\nExpected: ₱${shift.expectedCash?.toStringAsFixed(2) ?? '—'}${isBalanced ? '' : '\nDiscrepancy: ${discrepancy > 0 ? '+' : ''}₱${discrepancy.toStringAsFixed(2)}'}',
              trailingLabel: isBalanced ? 'Balanced' : 'Discrepancy',
              trailingColor: isBalanced ? AppColors.emerald600 : AppColors.rose600,
              trailingBgColor: isBalanced ? AppColors.emerald50 : AppColors.rose50,
            );
          },
        ),
      ],
    );
  }

  Widget _buildReconciliationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String? trailingLabel,
    Color? trailingColor,
    Color? trailingBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    if (trailingLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trailingBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trailingLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: trailingColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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