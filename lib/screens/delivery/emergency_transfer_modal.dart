import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../models/emergency_request_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class EmergencyTransferModal extends StatefulWidget {
  final EmergencyRequestModel? request;

  const EmergencyTransferModal({super.key, this.request});

  @override
  State<EmergencyTransferModal> createState() => _EmergencyTransferModalState();
}

class _EmergencyTransferModalState extends State<EmergencyTransferModal> {
  static const String _font = 'Plus Jakarta Sans';

  final FirestoreService _firestoreService = FirestoreService();
  String _reason = 'Bike Breakdown';
  String? _sourceRiderId;
  String? _targetRiderId;
  bool _isTransferring = false;
  bool _isDone = false;
  String _queueScope = 'all';
  bool _notifyDispatch = true;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle_outlined},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm_outlined},
    {'label': 'Rider Medical', 'icon': Icons.medical_services_outlined},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _sourceRiderId = widget.request!.riderId;
      _reason = widget.request!.reason;
    }
  }

  Future<void> _confirmTransfer(UserModel source, UserModel target) async {
    setState(() => _isTransferring = true);
    try {
      if (widget.request != null) {
        // Atomic resolution: Reassign orders and mark request as resolved
        final specificIds = _queueScope == 'split' ? widget.request!.affectedOrderIds : null;
        await _firestoreService.resolveEmergencyRequestAndTransfer(
          requestId: widget.request!.id,
          fromRiderId: source.id,
          toRiderId: target.id,
          toRiderName: target.name,
          specificOrderIds: specificIds,
          reason: _reason,
        );
      } else {
        // Manual dispatcher reassignment
        await _firestoreService.transferRiderOrders(
          fromRiderId: source.id,
          toRiderId: target.id,
          toRiderName: target.name,
          reason: _reason,
        );
      }

      if (!mounted) return;
      setState(() {
        _isTransferring = false;
        _isDone = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully transferred route to ${target.name}.'),
          backgroundColor: AppColors.emerald600,
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTransferring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to transfer: $e'),
          backgroundColor: AppColors.coralAlert,
        ),
      );
    }
  }

  Widget _buildCard({
    required Widget child,
    Color? bg,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.slate200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // Pale icy blue (0xFFF0F9FF)
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: StreamBuilder<List<UserModel>>(
                      stream: _firestoreService.getRidersStream(),
                      builder: (context, ridersSnapshot) {
                        return StreamBuilder<List<OrderModel>>(
                          stream: _firestoreService.getActiveOrdersStream(),
                          builder: (context, ordersSnapshot) {
                            final riders = ridersSnapshot.data ?? const <UserModel>[];
                            final activeOrders = ordersSnapshot.data ?? const <OrderModel>[];

                            int activeCountFor(String riderId) =>
                                activeOrders.where((o) => o.assignedRiderId == riderId).length;
                            double codFor(String riderId) => activeOrders
                                .where((o) => o.assignedRiderId == riderId && o.paymentMethod == PaymentMethod.cash)
                                .fold<double>(0, (s, o) => s + o.totalAmount);

                            final ridersWithLoad =
                            riders.where((r) => activeCountFor(r.id) > 0).toList();

                            if (riders.length < 2) {
                              return _buildNoticeBox(
                                'Need at least 2 rider accounts in the system to transfer a route.',
                              );
                            }
                            if (ridersWithLoad.isEmpty) {
                              return _buildNoticeBox(
                                'No rider currently has active deliveries in their queue to transfer.',
                              );
                            }

                            _sourceRiderId ??= ridersWithLoad.first.id;
                            final source = ridersWithLoad.firstWhere(
                                  (r) => r.id == _sourceRiderId,
                              orElse: () => ridersWithLoad.first,
                            );
                            final targetCandidates =
                            riders.where((r) => r.id != source.id).toList();
                            _targetRiderId ??=
                            targetCandidates.isEmpty ? null : targetCandidates.first.id;
                            final target = targetCandidates.isEmpty
                                ? null
                                : targetCandidates.firstWhere(
                                  (r) => r.id == _targetRiderId,
                              orElse: () => targetCandidates.first,
                            );

                            final sourcePendingStops = activeCountFor(source.id);
                            final sourceCod = codFor(source.id);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.request != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Approving request for ${widget.request!.riderName} (${widget.request!.reason}). Select a replacement rider below.',
                                            style: const TextStyle(
                                              fontFamily: _font,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF065F46),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // 1. Trigger Reason Grid
                                _buildReasonSection(),
                                const SizedBox(height: 18),

                                // 2. Source Rider Card
                                _buildSourceRiderCard(
                                  source: source,
                                  ridersWithLoad: ridersWithLoad,
                                  pendingStops: sourcePendingStops,
                                  codTotal: sourceCod,
                                ),
                                const SizedBox(height: 12),

                                // Downward Transfer Indicator
                                Center(
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.amber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x26000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.arrow_downward, size: 18, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 3. Target Rider Card
                                _buildTargetRiderCard(
                                  target: target,
                                  targetCandidates: targetCandidates,
                                  activeCountFor: activeCountFor,
                                ),
                                const SizedBox(height: 18),

                                // 4. Transfer Scope
                                _buildScopeSection(sourcePendingStops),
                                const SizedBox(height: 16),

                                // 5. Dispatch Notification Toggle
                                _buildNotificationToggle(),
                                const SizedBox(height: 24),

                                // 6. Action Buttons
                                _buildActionButtons(
                                  source: source,
                                  target: target,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceIce,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.primarySky, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.request != null ? 'Reassign Route (Emergency)' : 'Emergency Route Transfer',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Live Queue Reassignment Protocol',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.slate400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '1. Trigger Reason',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.amber200),
              ),
              child: const Text(
                'VERIFIED',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const double gap = 8;
            final double itemWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: _reasons.map((r) {
                final String label = r['label'] as String;
                final IconData icon = r['icon'] as IconData;
                final bool active = _reason == label;

                return InkWell(
                  onTap: () => setState(() => _reason = label),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.amber50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppColors.amber500 : AppColors.slate200,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: active ? AppColors.amber700 : AppColors.slate400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              fontWeight: active ? FontWeight.bold : FontWeight.w600,
                              color: active ? AppColors.amber900 : AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceRiderCard({
    required UserModel source,
    required List<UserModel> ridersWithLoad,
    required int pendingStops,
    required double codTotal,
  }) {
    return _buildCard(
      borderColor: AppColors.amber200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SOURCE RIDER (CURRENT QUEUE)',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.amber700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Stalled Route',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amber200),
                ),
                child: const Icon(Icons.two_wheeler, size: 20, color: AppColors.amber700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: source.id,
                    dropdownColor: AppColors.surfaceIce,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400, size: 20),
                    items: ridersWithLoad.map((r) {
                      return DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _sourceRiderId = v;
                      if (_targetRiderId == v) _targetRiderId = null;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            source.assignedArea ?? (sanPabloZoneCodes['si'] ?? 'Barangay San Isidro'),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, size: 16, color: AppColors.primarySky),
                    const SizedBox(width: 6),
                    Text(
                      '$pendingStops Pending Stops',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${codTotal.toStringAsFixed(2)} COD',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRiderCard({
    required UserModel? target,
    required List<UserModel> targetCandidates,
    required int Function(String) activeCountFor,
  }) {
    if (target == null) {
      return _buildCard(
        child: const Text(
          'No other rider available to receive the transfer.',
          style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.slate500),
        ),
      );
    }

    return _buildCard(
      borderColor: AppColors.emerald200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TARGET RIDER (NEW ASSIGNEE)',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.emerald700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Replacement',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald200),
                ),
                child: const Icon(Icons.directions_bike, size: 20, color: AppColors.emerald700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: target.id,
                    dropdownColor: AppColors.surfaceIce,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400, size: 20),
                    items: targetCandidates.map((r) {
                      return DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _targetRiderId = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            target.assignedArea ?? (sanPabloZoneCodes['si'] ?? 'Barangay San Isidro'),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.slate500),
                    SizedBox(width: 6),
                    Text(
                      'Current Workload',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${activeCountFor(target.id)} active orders',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSection(int sourcePendingStops) {
    final affectedCount = widget.request?.affectedOrderIds.length ?? sourcePendingStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Queue Transfer Scope',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _queueScope = 'all'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _queueScope == 'all' ? AppColors.amber50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _queueScope == 'all' ? AppColors.amber500 : AppColors.slate200,
                      width: _queueScope == 'all' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _queueScope == 'all' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: _queueScope == 'all' ? AppColors.amber700 : AppColors.slate400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Stops ($sourcePendingStops)',
                              style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'Full queue handoff',
                              style: TextStyle(fontFamily: _font, fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _queueScope = 'split'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _queueScope == 'split' ? AppColors.amber50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _queueScope == 'split' ? AppColors.amber500 : AppColors.slate200,
                      width: _queueScope == 'split' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _queueScope == 'split' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: _queueScope == 'split' ? AppColors.amber700 : AppColors.slate400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected ($affectedCount)',
                              style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'Affected stops only',
                              style: TextStyle(fontFamily: _font, fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.amber700, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notify Rider & Station Dispatch',
                  style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                Text(
                  'Send immediate alert on reassignment',
                  style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _notifyDispatch,
            activeThumbColor: AppColors.amber500,
            onChanged: (val) => setState(() => _notifyDispatch = val),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required UserModel source,
    required UserModel? target,
  }) {
    final isApproval = widget.request != null;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: (_isTransferring || _isDone) ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slate200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: (_isTransferring || _isDone || target == null)
                  ? null
                  : () => _confirmTransfer(source, target),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproval ? const Color(0xFF059669) : AppColors.amber500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.slate200,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isTransferring
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.swap_horiz, size: 18),
              label: Text(
                _isTransferring
                    ? 'Transferring...'
                    : (isApproval ? 'Confirm & Transfer' : 'Transfer Queue'),
                style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}