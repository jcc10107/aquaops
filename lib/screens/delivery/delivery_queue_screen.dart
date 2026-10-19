import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/rider_location_service.dart';
import '../customer/customer_map_screen.dart';
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
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  final RiderLocationService _riderLocationService = RiderLocationService();
  List<String> _lastBroadcastOrderIds = const [];
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;
  bool _pendingListExpanded = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Covers reopening the app after it was closed while offline.
    _attemptSync();
    // Covers signal coming back while the rider is already on this screen.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _attemptSync();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _searchCtrl.dispose();
    _riderLocationService.stop();
    super.dispose();
  }

  void _syncRiderBroadcast(List<String> outForDeliveryOrderIds) {
    outForDeliveryOrderIds.sort();
    if (listEquals(outForDeliveryOrderIds, _lastBroadcastOrderIds)) return;
    _lastBroadcastOrderIds = outForDeliveryOrderIds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _riderLocationService.setActiveOrderIds(outForDeliveryOrderIds);
    });
  }

  Future<void> _attemptSync({bool showResult = false}) async {
    if (_syncing) return;
    if (_offlineQueue.getAllPending().isEmpty) return;
    setState(() => _syncing = true);
    final (synced, stillPending) = await _offlineQueue.syncAll(
      firestoreService: _firestoreService,
      cloudinaryService: _cloudinaryService,
    );
    if (!mounted) return;
    setState(() => _syncing = false);
    if (showResult) {
      final message = stillPending == 0
          ? 'All deliveries synced!'
          : 'Synced $synced — $stillPending still pending.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _pendingSyncBanner() {
    return ValueListenableBuilder<Box>(
      valueListenable: _offlineQueue.listenable(),
      builder: (context, box, _) {
        final pendingCount = box.length;
        if (pendingCount == 0) return const SizedBox.shrink();
        final records = _offlineQueue.getAllPending();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withValues(alpha: 0.8),
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _pendingListExpanded = !_pendingListExpanded),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Row(
                      children: [
                        _syncing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB45309)))
                            : const Icon(Icons.cloud_off, size: 18, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$pendingCount ${pendingCount == 1 ? 'delivery' : 'deliveries'} pending sync',
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ),
                        Icon(_pendingListExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: const Color(0xFFB45309)),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _syncing ? null : () => _attemptSync(showResult: true),
                          child: const Text('Sync Now', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309), decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pendingListExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      children: records.map((r) => _pendingRecordTile(r)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pendingRecordTile(Map<String, dynamic> record) {
    final orderNumber = (record['orderNumber'] as String?) ?? record['orderId'] as String;
    final customerName = (record['customerName'] as String?) ?? 'Unknown customer';
    final address = (record['deliveryAddress'] as String?) ?? '';
    final gallons = record['gallonsDelivered'] as int? ?? 0;
    final recipient = record['recipientName'] as String?;
    final queuedAt = DateTime.tryParse(record['queuedAt'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
              Text('$gallons gal', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 2),
          Text(customerName, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF131B2E))),
          if (address.isNotEmpty)
            Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: Color(0xFF3F4850))),
          if (recipient != null && recipient.isNotEmpty)
            Text('Received by: $recipient', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: Color(0xFF3F4850))),
          if (queuedAt != null)
            Text('Queued ${_fmtQueuedTime(queuedAt)}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  String _fmtQueuedTime(DateTime t) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${p(t.month)}-${p(t.day)} ${p(t.hour)}:${p(t.minute)}';
  }

  void _showAssignRiderSheet(OrderModel order, List<UserModel> riders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 50,
                    spreadRadius: -12,
                    offset: Offset(0, 25),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFC7D2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Rider',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF131B2E),
                            ),
                          ),
                          Text(
                            'Select a rider to dispatch this order',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF3F4850),
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: const Color(0xFFEAEDFF),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(sheetContext),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(Icons.close,
                                size: 20, color: Color(0xFF3F4850)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (riders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No rider accounts found.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF3F4850),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: riders.map((rider) {
                            final bool isSelected =
                                order.assignedRiderId == rider.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isSelected
                                    ? const Color(0xFFE0F2FE)
                                    : const Color(0xFFF2F3FF),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(sheetContext);
                                    try {
                                      await _firestoreService.assignRider(
                                        orderId: order.id,
                                        riderId: rider.id,
                                        riderName: rider.name,
                                      );
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Assigned to ${rider.name}.')),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to assign: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0284C7)
                                                : const Color(0xFFE0F2FE),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.two_wheeler,
                                            size: 20,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF0284C7),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rider.name,
                                                style: const TextStyle(
                                                  fontFamily:
                                                  'Plus Jakarta Sans',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF131B2E),
                                                ),
                                              ),
                                              Text(
                                                rider.assignedArea ?? rider.phone,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily:
                                                  'Plus Jakarta Sans',
                                                  fontSize: 11,
                                                  color: Color(0xFF3F4850),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 22,
                                          color: isSelected
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFFBFC7D2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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

  static const List<String> _codedZones = ['si', 'dr', 'sr', 'sm'];

  // 'other' groups every barangay that isn't one of the 4 legacy-coded
  // ones — both the old literal 'other' value and any of the ~75 real
  // barangay names now saved directly on the order.
  bool _matchesArea(OrderModel d, String area) {
    if (area == 'all') return true;
    final group = zoneGroupOf(d.areaZone);
    if (area == 'other') return !_codedZones.contains(group);
    return group == area;
  }

  int _countForArea(List<OrderModel> orders, String area) {
    if (area == 'all') return orders.length;
    return orders.where((d) => _matchesArea(d, area)).length;
  }

  bool _matchesStatus(OrderModel d, String status) {
    if (status == 'all') return true;
    return d.status.name == status;
  }

  bool _matchesSearch(OrderModel d, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return d.customerName.toLowerCase().contains(q) ||
        d.orderNumber.toLowerCase().contains(q) ||
        (d.deliveryAddress ?? '').toLowerCase().contains(q);
  }

  Widget _buildStatusFilterTab(String val, String label) {
    final bool isActive = _statusFilter == val;
    return InkWell(
      onTap: () => setState(() => _statusFilter = val),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRoleNotifier.value;
    final isDispatcher = role == 'owner' || role == 'staff';
    final canCashOut = isDispatcher;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
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
                          child: const Text('DISPATCH HUB', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Area-Based Delivery Queue & Dispatch', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2)),
                  ],
                ),
                const SizedBox(height: 16),
                _pendingSyncBanner(),
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
                                Text('Emergency Transfer', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
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
                                Text('Shift Cash-Out', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
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
                            child: Text('Failed to load deliveries: ${snapshot.error}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFFF43F5E))),
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
                        if (isRider) {
                          _syncRiderBroadcast(
                            orders.where((o) => o.status == OrderStatus.outForDelivery).map((o) => o.id).toList(),
                          );
                        }
                        final filteredDeliveries = orders
                            .where((d) => _matchesArea(d, _area) && _matchesStatus(d, _statusFilter) && _matchesSearch(d, _searchCtrl.text))
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
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
                                          Text('Dispatch Zone', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _BlinkingDot(color: Color(0xFF10B981)),
                                          SizedBox(width: 4),
                                          Text('Live Dispatch', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
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
                                        const SizedBox(width: 8),
                                        _buildFilterTab('other', 'Other Barangays', _countForArea(orders, 'other')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: 'Search customer, order #, or address...',
                                      hintStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                                      suffixIcon: _searchCtrl.text.isEmpty
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                                              onPressed: () => setState(() => _searchCtrl.clear()),
                                            ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildStatusFilterTab('all', 'All Statuses'),
                                        const SizedBox(width: 6),
                                        _buildStatusFilterTab('pending', 'Pending'),
                                        const SizedBox(width: 6),
                                        _buildStatusFilterTab('refilling', 'Refilling'),
                                        const SizedBox(width: 6),
                                        _buildStatusFilterTab('outForDelivery', 'Out for Delivery'),
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
                                Text('ACTIVE DELIVERY QUEUE (${filteredDeliveries.length} PENDING)', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (filteredDeliveries.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('No active deliveries in this area.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: Color(0xFF64748B))),
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
          color: isActive ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF334155))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(100)),
              child: Text('$count', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF475569))),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
      ),
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
                    Text(order.customerName, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 13, color: Color(0xFFF43F5E)),
                        const SizedBox(width: 2),
                        Expanded(child: Text(order.deliveryAddress ?? '', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
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
                    Text(_statusBadgeLabel(order.status), style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, color: _statusBadgeTextColor(order.status), fontWeight: FontWeight.bold)),
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
                  Text('Transferred: ${order.lastTransferReason}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFB45309))),
                ],
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Container(
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
                          const Text('ORDER & QTY', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(qtySummary, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AMOUNT DUE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
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
                          const Text('PAYMENT MODE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (order.paymentMethod == PaymentMethod.gcash) ...[
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                              ],
                              Text(order.paymentMethod == PaymentMethod.gcash ? 'GCASH' : 'CASH', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ASSIGNED RIDER', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: canReassign ? () => _showAssignRiderSheet(order, riders) : null,
                            child: Row(
                              children: [
                                Expanded(child: Text(rider, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: order.assignedRiderId == null ? const Color(0xFFF43F5E) : const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                                if (canReassign) const Text(' ✎', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Color(0xFF94A3B8))),
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
          const SizedBox(height: 12),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FulfillDeliveryScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 17, color: Colors.white),
                  label: const Text('Complete Drop-off & Verify Payment', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('In-app messaging is coming soon. Please call or text the customer directly for now.')),
                        );
                      },
                      icon: const Icon(Icons.chat, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('Send Message', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerMapScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('View Route', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
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
}