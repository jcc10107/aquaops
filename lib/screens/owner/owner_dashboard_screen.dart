import 'package:flutter/material.dart';
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
  static const Color skyBlue = Color(0xFF0284C7);
  static const Color primary = Color(0xFF006194);
  static const Color primaryContainer = Color(0xFF007BB9);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color cyanHighlight = Color(0xFF22D3EE);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3F4850);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color primaryFixed = Color(0xFFCCE5FF);

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
        constraints: const BoxConstraints(maxWidth: 450),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getAllOrdersStream(),
        builder: (context, ordersSnapshot) {
          final orders = ordersSnapshot.data ?? const <OrderModel>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHubHeaderSection(),
              const SizedBox(height: 16),
              _buildRevenueCard(orders),
              const SizedBox(height: 16),
              _buildDispatchSection(orders),
              const SizedBox(height: 16),
              StreamBuilder<List<InventoryModel>>(
                stream: _firestoreService.getInventoryStream(),
                builder: (context, invSnapshot) {
                  return _buildSuppliesSection(invSnapshot.data ?? const <InventoryModel>[]);
                },
              ),
              const SizedBox(height: 16),
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hubName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: -0.4),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xBF6CF8BB), shape: BoxShape.circle)),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: secondary, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: secondary, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          color: surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) => setState(() => _period = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'today', child: Text('Today')),
            PopupMenuItem(value: 'week', child: Text('This Week')),
            PopupMenuItem(value: 'month', child: Text('This Month')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(100)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 15, color: skyBlue),
                const SizedBox(width: 4),
                Text(_dateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: skyBlue)),
                const Icon(Icons.arrow_drop_down, size: 16, color: skyBlue),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryContainer, cyanElectric],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x59006194), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments, size: 18, color: cyanHighlight),
                  SizedBox(width: 6),
                  Text('DAILY GROSS REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 1.2)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: secondaryContainer, borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 12, color: onSecondaryContainer),
                    const SizedBox(width: 2),
                    Text('+${growthPercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSecondaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₱${dailyGrossRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
              const SizedBox(width: 8),
              Text('vs ₱${prevGrossRevenue.toStringAsFixed(0)} prior', style: const TextStyle(fontSize: 11, color: primaryFixed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CASH IN TILL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 0.6)),
                          Icon(Icons.check_circle, size: 14, color: secondaryContainer),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₱${cashInTill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Reconciled ready', style: TextStyle(fontSize: 10, color: primaryFixed), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GCASH / QR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 0.6)),
                          Icon(Icons.verified, size: 14, color: cyanHighlight),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₱${gcashQr.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('InstaPay verified', style: TextStyle(fontSize: 10, color: primaryFixed), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.local_drink, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$gallonsPumped Gallons Pumped', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryFixed)),
                        Text('$roundGallons Round • $slimGallons Slim', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Orders Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryFixed)),
                    Text('$ordersCompleted orders', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: secondaryContainer)),
                  ],
                ),
              ],
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
            const Row(
              children: [
                Icon(Icons.two_wheeler, color: skyBlue, size: 20),
                SizedBox(width: 6),
                Text('Active Dispatch Fleet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: surfaceFrost, borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: tealAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${activeDeliveries.length} En Route', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: skyBlue)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeDeliveries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
            child: const Text('No orders out for delivery right now.', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
          )
        else
          ...activeDeliveries.take(3).map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildRiderCard(o),
          )),
        InkWell(
          onTap: _onOpenDispatchConsole,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: surfaceFrost, borderRadius: BorderRadius.circular(100)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Open Live Dispatch Console', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: skyBlue)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18, color: skyBlue),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F007BB9), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: surfaceFrost, shape: BoxShape.circle),
                    child: const Center(
                      child: Icon(Icons.person, color: skyBlue, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(order.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(100)),
                            child: Text(order.id, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: skyBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(order.deliveryAddress ?? '', style: const TextStyle(fontSize: 11, color: onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Out for delivery',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 15, color: secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('₱${order.totalAmount.toStringAsFixed(0)} • $itemSummary', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(riderLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: skyBlue)),
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
            const Row(
              children: [
                Icon(Icons.inventory_2, color: skyBlue, size: 20),
                SizedBox(width: 6),
                Text('Supplies & Bottling Stock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            InkWell(
              onTap: _onManageSupplies,
              child: const Text('Manage All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: skyBlue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleSupplies.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
            child: const Text('No inventory items yet.', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
          )
        else
          Row(
            children: visibleSupplies
                .asMap()
                .entries
                .map((entry) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: entry.key == visibleSupplies.length - 1 ? 0 : 8),
                child: _buildSupplyCard(entry.value),
              ),
            ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSupplyCard(InventoryModel supply) {
    final bool isLow = supply.isLowStock;
    final Color accent = isLow ? coralAlert : secondary;
    final IconData icon = supply.category == 'water' ? Icons.water_drop : Icons.inventory_2;
    final int pctLeft = supply.maxCapacity == 0 ? 0 : ((supply.currentStock / supply.maxCapacity) * 100).round();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: accent),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isLow ? errorContainer : secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isLow ? '$pctLeft% LEFT' : 'GOOD',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isLow ? onErrorContainer : onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${supply.currentStock}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isLow ? coralAlert : onSurface)),
          Text(supply.name, style: const TextStyle(fontSize: 11, color: onSurfaceVariant), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(isLow ? 'Restock ASAP' : 'Stock healthy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLow ? coralAlert : secondary)),
        ],
      ),
    );
  }

  Widget _buildReconciliationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: skyBlue, size: 20),
            SizedBox(width: 6),
            Text('Reconciliation Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<ShiftModel?>(
          stream: _firestoreService.getLatestShiftStream(),
          builder: (context, snapshot) {
            final shift = snapshot.data;
            final now = DateTime.now();
            final openedToday = shift != null && shift.openedAt.year == now.year && shift.openedAt.month == now.month && shift.openedAt.day == now.day;

            if (shift == null || (shift.status == ShiftStatus.closed && !openedToday)) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                child: const Text('No shift opened today yet. Staff open a shift from the POS screen.', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
              );
            }

            if (shift.status == ShiftStatus.open) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0F007BB9), blurRadius: 16)]),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                      child: const Icon(Icons.hourglass_top, size: 20, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shift In Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface)),
                          Text('Opened by ${shift.openedByName} with ₱${shift.openingCash.toStringAsFixed(2)} float', style: const TextStyle(fontSize: 11, color: onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final discrepancy = shift.discrepancy ?? 0;
            final isBalanced = discrepancy.abs() < 0.01;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0F007BB9), blurRadius: 16)]),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: isBalanced ? secondaryContainer : errorContainer, shape: BoxShape.circle),
                    child: Icon(isBalanced ? Icons.task_alt : Icons.warning_amber, size: 20, color: isBalanced ? onSecondaryContainer : onErrorContainer),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text('Closed by ${shift.closedByName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: isBalanced ? secondaryContainer : errorContainer, borderRadius: BorderRadius.circular(100)),
                              child: Text(isBalanced ? 'Balanced' : 'Discrepancy', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isBalanced ? onSecondaryContainer : onErrorContainer)),
                            ),
                          ],
                        ),
                        Text(
                          'Counted ₱${shift.closingCash?.toStringAsFixed(2) ?? '—'} vs expected ₱${shift.expectedCash?.toStringAsFixed(2) ?? '—'}${isBalanced ? '' : ' (${discrepancy > 0 ? '+' : ''}₱${discrepancy.toStringAsFixed(2)})'}',
                          style: const TextStyle(fontSize: 11, color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}