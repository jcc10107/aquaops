import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RiderEmergencyRequestModal extends StatefulWidget {
  const RiderEmergencyRequestModal({super.key});

  @override
  State<RiderEmergencyRequestModal> createState() => _RiderEmergencyRequestModalState();
}

class _RiderEmergencyRequestModalState extends State<RiderEmergencyRequestModal> {
  static const String _font = 'Plus Jakarta Sans';

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _descCtrl = TextEditingController();

  String _reason = 'Bike Breakdown';
  final Set<String> _selectedOrderIds = <String>{};
  bool _initializedSelection = false;
  bool _isSubmitting = false;
  String? _orderSelectionError;
  String? _descError;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle_outlined},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm_outlined},
    {'label': 'Rider Medical', 'icon': Icons.medical_services_outlined},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2_outlined},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(String riderName, String? riderPhone) async {
    final currentUserId = AuthService().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      return;
    }

    setState(() {
      _orderSelectionError = _selectedOrderIds.isEmpty ? 'Select at least one delivery order to hand off.' : null;
      _descError = (_reason == 'Other' && _descCtrl.text.trim().isEmpty)
          ? 'Please describe the emergency situation under "Other".'
          : null;
    });
    if (_orderSelectionError != null || _descError != null) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.createEmergencyRequest(
        riderId: currentUserId,
        riderName: riderName,
        riderPhone: riderPhone,
        affectedOrderIds: _selectedOrderIds.toList(),
        reason: _reason,
        description: _descCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency request sent to Station Dispatch for review.'),
          backgroundColor: Color(0xFF059669), // Emerald
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '')),
          backgroundColor: AppColors.coralAlert,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // Matches the Delivery Queue background
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<List<OrderModel>>(
                    stream: _firestoreService.getActiveOrdersStream(),
                    builder: (context, ordersSnapshot) {
                      if (ordersSnapshot.hasError) {
                        return Center(
                          child: Text('Error loading orders: ${ordersSnapshot.error}',
                              style: const TextStyle(color: AppColors.coralAlert)),
                        );
                      }
                      if (!ordersSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Only include orders assigned to this rider that are still active
                      final myOrders = ordersSnapshot.data!
                          .where((o) =>
                      o.assignedRiderId == currentUserId &&
                          (o.status == OrderStatus.outForDelivery ||
                              o.status == OrderStatus.pending ||
                              o.status == OrderStatus.refilling))
                          .toList();

                      // Select all active orders by default on first load
                      if (!_initializedSelection && myOrders.isNotEmpty) {
                        _selectedOrderIds.addAll(myOrders.map((o) => o.id));
                        _initializedSelection = true;
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Warning Alert Banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFD97706)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Submitting this request alerts the station dispatch to review and reassign your route to an available rider.',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 12,
                                        color: Color(0xFF92400E),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 1. Select Emergency Reason
                            _buildReasonSection(),
                            const SizedBox(height: 18),

                            // 2. Select Affected Deliveries
                            _buildOrdersSection(myOrders),
                            const SizedBox(height: 18),

                            // 3. Optional / Required Notes
                            _buildNotesSection(),
                            const SizedBox(height: 24),

                            // 4. Action Buttons
                            FutureBuilder(
                              future: _firestoreService.getUser(currentUserId),
                              builder: (context, userSnap) {
                                final riderName = userSnap.data?.name ?? 'Rider';
                                final riderPhone = userSnap.data?.phone;

                                return _buildActionButtons(
                                  hasDeliveries: myOrders.isNotEmpty,
                                  riderName: riderName,
                                  riderPhone: riderPhone,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCanvas,
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
                child: const Icon(Icons.close, color: AppColors.slate600, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Emergency Transfer',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Station Dispatch Assistance',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Reason for Request',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
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
                  onTap: () => setState(() {
                    _reason = label;
                    if (label != 'Other') _descError = null;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFFBEB) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? const Color(0xFFF59E0B) : AppColors.slate200,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: active ? const Color(0xFFD97706) : AppColors.slate400,
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
                              color: active ? const Color(0xFF92400E) : AppColors.textLight,
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

  Widget _buildOrdersSection(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.slate400, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have no active deliveries in your queue to transfer.',
                style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final allSelected = _selectedOrderIds.length == orders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. Select Affected Deliveries',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedOrderIds.clear();
                  } else {
                    _selectedOrderIds.addAll(orders.map((o) => o.id));
                  }
                  if (_orderSelectionError != null) _orderSelectionError = null;
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                allSelected ? 'Deselect All' : 'Select All (${orders.length})',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primarySky,
                ),
              ),
            ),
          ],
        ),
        if (_orderSelectionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              _orderSelectionError!,
              style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.coralAlert),
            ),
          ),
        const SizedBox(height: 8),
        ...orders.map((order) {
          final isChecked = _selectedOrderIds.contains(order.id);
          final itemsCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isChecked) {
                    _selectedOrderIds.remove(order.id);
                  } else {
                    _selectedOrderIds.add(order.id);
                  }
                  if (_orderSelectionError != null) _orderSelectionError = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isChecked ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? AppColors.primarySky : AppColors.slate200,
                    width: isChecked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isChecked ? AppColors.primarySky : AppColors.slate400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${order.orderNumber}',
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${order.customerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryAddress ?? 'No address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$itemsCount gal',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesSection() {
    final isOther = _reason == 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '3. Situation Details',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOther ? '(Required)' : '(Optional)',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOther ? const Color(0xFFD97706) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          onChanged: (_) {
            if (_descError != null) setState(() => _descError = null);
          },
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: isOther
                ? 'Please explain the issue preventing delivery...'
                : 'Any extra details (e.g., flat rear tire, waiting at crossing)...',
            hintStyle: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            errorText: _descError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _descError != null ? AppColors.coralAlert : AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _descError != null ? AppColors.coralAlert : AppColors.primarySky),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required bool hasDeliveries,
    required String riderName,
    String? riderPhone,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slate200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || !hasDeliveries)
                  ? null
                  : () => _submitRequest(riderName, riderPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.slate200,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSubmitting ? 'Sending...' : 'Send Request',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}