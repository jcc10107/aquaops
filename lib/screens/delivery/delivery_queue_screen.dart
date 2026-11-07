import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../main.dart';
import '../../models/emergency_request_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/rider_location_service.dart';
import '../../widgets/bottom_sheet_chrome.dart';
import '../messaging/chat_conversation_screen.dart';
import 'fulfill_delivery_screen.dart';
import 'owner_emergency_requests_modal.dart';
import 'rider_cash_out_modal.dart';
import 'rider_delivery_map_screen.dart';
import 'rider_emergency_request_modal.dart';

class DeliveryQueueScreen extends StatefulWidget {
  const DeliveryQueueScreen({super.key});

  @override
  State<DeliveryQueueScreen> createState() => _DeliveryQueueScreenState();
}

class _DeliveryQueueScreenState extends State<DeliveryQueueScreen> {
  String _area = 'all';
  String _statusFilter = 'all';
  String _sortBy = 'latest';

  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  final RiderLocationService _riderLocationService = RiderLocationService();
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<String> _lastBroadcastOrderIds = const [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;
  bool _pendingListExpanded = false;

  final Set<String> _dismissedRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _attemptSync();
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

  bool _matchesArea(OrderModel d, String area) {
    if (area == 'all') return true;
    final group = zoneGroupOf(d.areaZone);
    if (area == 'other') return !sanPabloZoneCodes.containsKey(group);
    final query = area.toLowerCase();
    return group == area ||
        d.areaZone.toLowerCase().contains(query) ||
        (d.deliveryAddress != null && d.deliveryAddress!.toLowerCase().contains(query));
  }

  bool _matchesStatus(OrderModel d, String status) {
    if (status == 'all') return true;
    if (status == 'pending') return d.status == OrderStatus.pending;
    if (status == 'outForDelivery') return d.status == OrderStatus.outForDelivery;
    if (status == 'delivered') return d.status == OrderStatus.delivered;
    if (status == 'cancelled') return d.status == OrderStatus.cancelled;
    return d.status.name == status;
  }

  bool _matchesSearch(OrderModel d, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return d.customerName.toLowerCase().contains(q) ||
        d.orderNumber.toLowerCase().contains(q) ||
        (d.deliveryAddress ?? '').toLowerCase().contains(q) ||
        d.areaZone.toLowerCase().contains(q);
  }

  List<OrderModel> _sortOrders(List<OrderModel> list) {
    final sorted = List<OrderModel>.from(list);
    sorted.sort((a, b) {
      return _sortBy == 'latest'
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  String _getAreaLabel(String areaKey) {
    if (areaKey == 'all') return 'All Areas';
    if (areaKey == 'other') return 'Other Barangays';
    return sanPabloZoneCodes[areaKey] ?? areaKey;
  }

  String _formatOrderTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _openAreaSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allEntries = [
              const MapEntry('all', 'All Areas'),
              ...sanPabloZoneCodes.entries,
              const MapEntry('other', 'Other Barangays'),
            ];

            final filteredEntries = allEntries.where((entry) {
              if (searchQuery.trim().isEmpty) return true;
              return entry.value.toLowerCase().contains(searchQuery.trim().toLowerCase()) ||
                  entry.key.toLowerCase().contains(searchQuery.trim().toLowerCase());
            }).toList();

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceIce,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      const BottomSheetDragHandle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            const Text(
                              'Select Area',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textLight),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                          onChanged: (val) => setModalState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search area or barangay...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate400),
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.slate400),
                              onPressed: () => setModalState(() => searchQuery = ''),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky)),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.slate200),
                      Flexible(
                        child: filteredEntries.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No matching areas found', style: TextStyle(fontSize: 13, color: AppColors.slate400)),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredEntries.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemBuilder: (context, idx) {
                            final item = filteredEntries[idx];
                            final bool isSelected = _area == item.key;
                            return InkWell(
                              onTap: () {
                                setState(() => _area = item.key);
                                Navigator.pop(sheetContext);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primarySky.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.key == 'all' ? Icons.dashboard_outlined : Icons.location_on_outlined,
                                      size: 18,
                                      color: isSelected ? AppColors.primarySky : AppColors.slate400,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppColors.primarySky : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) const Icon(Icons.check, size: 18, color: AppColors.primarySky),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
            constraints: BoxConstraints(maxWidth: 800, maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: const BoxDecoration(
                color: AppColors.surfaceIce,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BottomSheetDragHandle(),
                  const SizedBox(height: 12),
                  BottomSheetHeader(
                    title: 'Assign Rider',
                    subtitle: 'Order #${order.orderNumber} • ${order.customerName}',
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 16),
                  if (riders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('No rider accounts found.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: riders.map((rider) {
                            final bool isSelected = order.assignedRiderId == rider.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
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
                                      messenger.showSnackBar(SnackBar(content: Text('Assigned to ${rider.name}.')));
                                    } catch (e) {
                                      messenger.showSnackBar(SnackBar(content: Text('Failed to assign: $e'), backgroundColor: AppColors.error));
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primarySky : AppColors.surfaceFrost,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.two_wheeler, size: 20, color: isSelected ? Colors.white : AppColors.primarySky),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(rider.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                                              Text(rider.assignedArea ?? rider.phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: isSelected ? AppColors.primarySky : AppColors.borderLight),
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

  void _showEmergencyTransfer(BuildContext context, bool isRider) {
    if (isRider) {
      showDialog(
        context: context,
        builder: (context) => const RiderEmergencyRequestModal(),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const OwnerEmergencyRequestsModal(),
      );
    }
  }

  Future<void> _openDeliveryChat(OrderModel order) async {
    try {
      final convo = await _messagingService.getOrCreateDeliveryConversation(order: order);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(conversation: convo),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: AppColors.coralAlert),
      );
    }
  }

  void _confirmCancelRiderRequest(BuildContext context, EmergencyRequestModel req) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceIce,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel this emergency transfer request? Station dispatch will be notified.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestoreService.cancelEmergencyRequest(
                  requestId: req.id,
                  riderId: req.riderId,
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Emergency request cancelled.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.coralAlert),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownerEmergencyRequestBanner() {
    return StreamBuilder<List<EmergencyRequestModel>>(
      stream: _firestoreService.getEmergencyRequestsStream(statusFilter: EmergencyRequestStatus.pending),
      builder: (context, snapshot) {
        final pending = snapshot.data ?? const <EmergencyRequestModel>[];
        if (pending.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const OwnerEmergencyRequestsModal(),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x10D97706), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pending.length} Emergency ${pending.length == 1 ? 'Request' : 'Requests'} Pending',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                        Text(
                          '${pending.first.riderName} reported "${pending.first.reason}". Tap to review.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFFB45309)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _riderLiveRequestTrackingBanner() {
    final currentUserId = AuthService().currentUserId ?? '';
    if (currentUserId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<EmergencyRequestModel>>(
      stream: _firestoreService.getEmergencyRequestsStream(riderId: currentUserId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <EmergencyRequestModel>[];
        if (requests.isEmpty) return const SizedBox.shrink();

        final activeReq = requests.firstWhere(
              (r) => !_dismissedRequestIds.contains(r.id),
          orElse: () => requests.first,
        );

        if (_dismissedRequestIds.contains(activeReq.id)) return const SizedBox.shrink();

        if (activeReq.status == EmergencyRequestStatus.pending) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Transfer Pending Review',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'Reported "${activeReq.reason}" for ${activeReq.affectedOrderIds.length} stops. Stand by for dispatch.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmCancelRiderRequest(context, activeReq),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.coralAlert)),
                  ),
                ],
              ),
            ),
          );
        }

        if (activeReq.status == EmergencyRequestStatus.declined) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 22, color: AppColors.coralAlert),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Transfer Declined by Dispatch',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                        ),
                        Text(
                          'Reason: "${activeReq.declineReason ?? 'Please contact station dispatch.'}"',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
                    onPressed: () => setState(() => _dismissedRequestIds.add(activeReq.id)),
                  ),
                ],
              ),
            ),
          );
        }

        if (activeReq.status == EmergencyRequestStatus.resolved) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 22, color: Color(0xFF059669)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Transferred Successfully',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                        ),
                        Text(
                          '${activeReq.affectedOrderIds.length} stops handed over to ${activeReq.replacementRiderName ?? 'replacement rider'}.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF065F46)),
                    onPressed: () => setState(() => _dismissedRequestIds.add(activeReq.id)),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDeliveryOperationsSection({required bool isRider}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, size: 14, color: AppColors.slate500),
                SizedBox(width: 6),
                Text(
                  'DELIVERY OPERATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 340;

                final cashOutButton = SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCashOut(context),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 17, color: Colors.white),
                    label: const Text(
                      'Rider Cash-Out',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );

                final emergencyTransferButton = SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEmergencyTransfer(context, isRider),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 19, color: Color(0xFFD97706)),
                    label: Text(
                      isRider ? 'Request Help' : 'Emergency Transfer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFCD34D)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );

                if (isStacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cashOutButton,
                      const SizedBox(height: 8),
                      emergencyTransferButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cashOutButton),
                    const SizedBox(width: 10),
                    Expanded(child: emergencyTransferButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingSyncBanner() {
    return ValueListenableBuilder<Box>(
      valueListenable: _offlineQueue.listenable(),
      builder: (context, box, _) {
        final pendingCount = box.length;
        if (pendingCount == 0) return const SizedBox.shrink();
        final records = _offlineQueue.getAllPending();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.amber50,
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _syncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber700))
                          : const Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.amber700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$pendingCount deliveries pending sync', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber900)),
                            const Text('Saved offline.', style: TextStyle(fontSize: 10, color: AppColors.amber700)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _syncing ? null : () => _attemptSync(showResult: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: Icon(_pendingListExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.amber800),
                        onPressed: () => setState(() => _pendingListExpanded = !_pendingListExpanded),
                      ),
                    ],
                  ),
                ),
                if (_pendingListExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(children: records.map((r) => _pendingRecordTile(r)).toList()),
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

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$orderNumber • $customerName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber900)),
                if (address.isNotEmpty)
                  Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('$gallons gal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber900)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label) {
    final bool isSelected = _statusFilter == statusKey;
    return InkWell(
      onTap: () => setState(() => _statusFilter = statusKey),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? AppColors.primarySky : AppColors.slate200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaFilterButton() {
    final bool hasSpecificArea = _area != 'all';
    final label = _getAreaLabel(_area);
    return InkWell(
      onTap: _openAreaSelectorModal,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasSpecificArea ? AppColors.surfaceFrost : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: hasSpecificArea ? AppColors.primarySky : AppColors.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 15, color: hasSpecificArea ? AppColors.primarySky : AppColors.slate600),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasSpecificArea ? FontWeight.w700 : FontWeight.w500,
                  color: hasSpecificArea ? AppColors.primarySky : AppColors.slate600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16, color: hasSpecificArea ? AppColors.primarySky : AppColors.slate500),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
            child: const Icon(Icons.location_off_outlined, size: 28, color: AppColors.primarySky),
          ),
          const SizedBox(height: 14),
          const Text('No orders found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(
            _area != 'all' ? 'No active deliveries matching in ${_getAreaLabel(_area)}.' : 'No deliveries matching your current filters.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() {
              _area = 'all';
              _statusFilter = 'all';
              _searchCtrl.clear();
            }),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primarySky),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Reset All Filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primarySky)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, List<UserModel> riders, bool isRider) {
    final canReassign = !isRider;
    final totalGallons = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final itemsLabel = totalGallons > 0 ? '$totalGallons items' : '${order.items.length} items';
    final riderName = order.assignedRiderName ?? 'Unassigned';

    Color statusBadgeBg;
    Color statusBadgeText;
    String statusTitle;
    IconData statusIcon;
    Color statusIconColor;
    Color statusIconBg;

    switch (order.status) {
      case OrderStatus.pending:
        statusBadgeBg = const Color(0xFFFEF3C7);
        statusBadgeText = const Color(0xFFB45309);
        statusTitle = 'Pending';
        statusIcon = Icons.inventory_2_outlined;
        statusIconColor = const Color(0xFFD97706);
        statusIconBg = const Color(0xFFFEF3C7);
        break;
      case OrderStatus.refilling:
        statusBadgeBg = const Color(0xFFEFF6FF);
        statusBadgeText = const Color(0xFF1D4ED8);
        statusTitle = 'Refilling';
        statusIcon = Icons.autorenew_rounded;
        statusIconColor = const Color(0xFF2563EB);
        statusIconBg = const Color(0xFFEFF6FF);
        break;
      case OrderStatus.outForDelivery:
        statusBadgeBg = const Color(0xFFE0F2FE);
        statusBadgeText = const Color(0xFF0369A1);
        statusTitle = 'Out for Delivery';
        statusIcon = Icons.local_shipping_outlined;
        statusIconColor = const Color(0xFF0284C7);
        statusIconBg = const Color(0xFFE0F2FE);
        break;
      case OrderStatus.delivered:
        statusBadgeBg = const Color(0xFFD1FAE5);
        statusBadgeText = const Color(0xFF047857);
        statusTitle = 'Delivered';
        statusIcon = Icons.check_circle_outline;
        statusIconColor = const Color(0xFF059669);
        statusIconBg = const Color(0xFFD1FAE5);
        break;
      case OrderStatus.cancelled:
        statusBadgeBg = const Color(0xFFFEE2E2);
        statusBadgeText = const Color(0xFFB91C1C);
        statusTitle = 'Failed';
        statusIcon = Icons.error_outline;
        statusIconColor = const Color(0xFFDC2626);
        statusIconBg = const Color(0xFFFEE2E2);
        break;
    }

    final isCOD = order.paymentMethod == PaymentMethod.cash;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // An unassigned order has no rider actually en route — opening
            // the live navigation map would show the viewer's own GPS
            // position mislabeled as "the rider." Route to assignment
            // instead, which is the actual next step for this order.
            if (order.assignedRiderId == null) {
              if (canReassign) _showAssignRiderSheet(order, riders);
              return;
            }
            if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RiderDeliveryMapScreen(order: order)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FulfillDeliveryScreen(order: order)),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: statusIconBg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(statusIcon, size: 18, color: statusIconColor),
                    ),
                    const SizedBox(width: 8),
                    Text('#${order.orderNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusBadgeBg, borderRadius: BorderRadius.circular(100)),
                      child: Text(statusTitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusBadgeText)),
                    ),
                    const Spacer(),
                    // Chat Action Button with Customer
                    IconButton(
                      tooltip: 'Message Customer',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primarySky),
                      onPressed: () => _openDeliveryChat(order),
                    ),
                    const SizedBox(width: 4),
                    Text(_formatOrderTime(order.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.slate400),
                  ],
                ),
                const SizedBox(height: 10),
                Text(order.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress ?? 'No address provided',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(itemsLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                    const SizedBox(width: 12),
                    Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCOD ? AppColors.slate100 : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(isCOD ? 'COD' : 'GCash', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isCOD ? AppColors.slate600 : const Color(0xFF1D4ED8))),
                    ),
                    const Spacer(),
                    if (canReassign)
                      InkWell(
                        onTap: () => _showAssignRiderSheet(order, riders),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.two_wheeler, size: 14, color: order.assignedRiderId == null ? AppColors.coralAlert : AppColors.slate500),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 80),
                                child: Text(
                                  riderName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: order.assignedRiderId == null ? AppColors.coralAlert : AppColors.slate600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = UserRole.fromString(currentUserRoleNotifier.value);
    final isRider = currentRole == UserRole.rider;
    final bottomInset = MediaQuery.of(context).padding.bottom + 110;

    return Container(
      color: AppColors.surfaceCanvas,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<List<UserModel>>(
            stream: _firestoreService.getRidersStream(),
            builder: (context, riderSnapshot) {
              final riders = riderSnapshot.data ?? const <UserModel>[];

              return StreamBuilder<List<OrderModel>>(
                stream: _firestoreService.getActiveOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Center(
                        child: Text(
                          'Failed to load deliveries: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.coralAlert),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allOrders = snapshot.data!;
                  final roleScopedOrders = isRider
                      ? allOrders.where((o) => o.assignedRiderId == AuthService().currentUserId).toList()
                      : allOrders;

                  if (isRider) {
                    _syncRiderBroadcast(
                      roleScopedOrders.where((o) => o.status == OrderStatus.outForDelivery).map((o) => o.id).toList(),
                    );
                  }

                  final pendingCount = roleScopedOrders.where((o) => o.status == OrderStatus.pending).length;
                  final outCount = roleScopedOrders.where((o) => o.status == OrderStatus.outForDelivery).length;
                  final completedCount = roleScopedOrders.where((o) => o.status == OrderStatus.delivered).length;

                  final filteredOrders = roleScopedOrders.where((d) {
                    return _matchesArea(d, _area) &&
                        _matchesStatus(d, _statusFilter) &&
                        _matchesSearch(d, _searchCtrl.text);
                  }).toList();

                  final sortedOrders = _sortOrders(filteredOrders);

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColors.sky50, shape: BoxShape.circle),
                              child: const Icon(Icons.local_shipping, color: AppColors.primarySky, size: 24),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Delivery Queue',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight, height: 1.1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildSummaryCard(
                              icon: Icons.inventory_2_outlined,
                              iconColor: const Color(0xFFD97706),
                              iconBgColor: const Color(0xFFFEF3C7),
                              count: '$pendingCount',
                              label: 'Pending',
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryCard(
                              icon: Icons.local_shipping_outlined,
                              iconColor: const Color(0xFF0284C7),
                              iconBgColor: const Color(0xFFE0F2FE),
                              count: '$outCount',
                              label: 'Out for Delivery',
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryCard(
                              icon: Icons.check_circle_outline,
                              iconColor: const Color(0xFF059669),
                              iconBgColor: const Color(0xFFD1FAE5),
                              count: '$completedCount',
                              label: 'Completed',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _pendingSyncBanner(),
                        if (!isRider)
                          _ownerEmergencyRequestBanner()
                        else
                          _riderLiveRequestTrackingBanner(),
                        _buildDeliveryOperationsSection(isRider: isRider),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                          decoration: InputDecoration(
                            hintText: 'Search by customer, address, or order #',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate400),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.slate400),
                              onPressed: () => setState(() => _searchCtrl.clear()),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusChip('all', 'All'),
                              const SizedBox(width: 6),
                              _buildStatusChip('pending', 'Pending'),
                              const SizedBox(width: 6),
                              _buildStatusChip('outForDelivery', 'Out for Delivery'),
                              const SizedBox(width: 6),
                              _buildStatusChip('delivered', 'Delivered'),
                              const SizedBox(width: 6),
                              _buildStatusChip('cancelled', 'Failed'),
                              const SizedBox(width: 8),
                              _buildAreaFilterButton(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(100)),
                                  child: Text('${sortedOrders.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              initialValue: _sortBy,
                              surfaceTintColor: Colors.transparent,
                              color: AppColors.surfaceIce,
                              onSelected: (val) => setState(() => _sortBy = val),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_vert, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _sortBy == 'latest' ? 'Latest first' : 'Oldest first',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'latest', child: Text('Latest first', style: TextStyle(fontSize: 13))),
                                PopupMenuItem(value: 'oldest', child: Text('Oldest first', style: TextStyle(fontSize: 13))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (sortedOrders.isEmpty)
                          _buildEmptyState()
                        else
                          ...sortedOrders.map((o) => _buildOrderCard(o, riders, isRider)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}