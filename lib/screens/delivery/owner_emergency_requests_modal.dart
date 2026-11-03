import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/emergency_request_model.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import 'emergency_transfer_modal.dart';

class OwnerEmergencyRequestsModal extends StatefulWidget {
  final String? initialRequestId;

  const OwnerEmergencyRequestsModal({super.key, this.initialRequestId});

  @override
  State<OwnerEmergencyRequestsModal> createState() => _OwnerEmergencyRequestsModalState();
}

class _OwnerEmergencyRequestsModalState extends State<OwnerEmergencyRequestsModal> {
  static const String _font = 'Plus Jakarta Sans';
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = 'pending';
  EmergencyRequestModel? _selectedRequest;

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _showDeclineDialog(EmergencyRequestModel req) {
    final reasonCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (builderCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceIce,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.coralAlert, size: 22),
              SizedBox(width: 8),
              Text(
                'Decline Help Request',
                style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please supply a reason for declining ${req.riderName}\'s request. This will be sent directly to the rider.',
                style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'e.g., Assistance en route, please stand by for mechanical check...',
                  hintStyle: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.coralAlert),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Back', style: TextStyle(fontFamily: _font, color: AppColors.slate600)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Please enter a decline reason.')),
                  );
                  return;
                }

                setDialogState(() => isSubmitting = true);
                try {
                  await _firestoreService.declineEmergencyRequest(
                    requestId: req.id,
                    declineReason: reason,
                  );

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);

                  if (!mounted) return;
                  setState(() => _selectedRequest = null);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Request from ${req.riderName} declined.')),
                  );
                } catch (e) {
                  if (dialogCtx.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.coralAlert),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coralAlert,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Decline', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReassignmentModal(EmergencyRequestModel req) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => EmergencyTransferModal(request: req),
    );

    if (!mounted) return;
    if (result == true) {
      setState(() => _selectedRequest = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<List<EmergencyRequestModel>>(
                  stream: _firestoreService.getEmergencyRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading requests: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.coralAlert)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allRequests = snapshot.data!;

                    if (_selectedRequest != null) {
                      final liveReq = allRequests.firstWhere(
                            (r) => r.id == _selectedRequest!.id,
                        orElse: () => _selectedRequest!,
                      );
                      return _buildRequestDetailView(liveReq);
                    }

                    final filteredRequests = allRequests.where((r) {
                      if (_selectedFilter == 'pending') return r.status == EmergencyRequestStatus.pending;
                      if (_selectedFilter == 'resolved') return r.status == EmergencyRequestStatus.resolved;
                      if (_selectedFilter == 'declined') return r.status == EmergencyRequestStatus.declined;
                      return true;
                    }).toList();

                    final pendingCount = allRequests.where((r) => r.status == EmergencyRequestStatus.pending).length;

                    return Column(
                      children: [
                        _buildFilterTabs(pendingCount),
                        Expanded(
                          child: filteredRequests.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final req = filteredRequests[index];
                              return _buildRequestCard(req);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      height: 64 + topInset,
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCanvas,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (_selectedRequest != null) {
                  setState(() => _selectedRequest = null);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Icon(
                  _selectedRequest != null ? Icons.arrow_back : Icons.close,
                  color: AppColors.slate600,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedRequest != null ? 'Request Details' : 'Rider Emergency Requests',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedRequest != null ? 'Station Dispatch Review' : 'Live Road Assistance Queue',
                style: const TextStyle(
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

  Widget _buildFilterTabs(int pendingCount) {
    Widget tab(String key, String label, {int count = 0}) {
      final isSelected = _selectedFilter == key;
      return InkWell(
        onTap: () => setState(() => _selectedFilter = key),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySky : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isSelected ? AppColors.primarySky : AppColors.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.slate600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primarySky : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            tab('pending', 'Pending', count: pendingCount),
            const SizedBox(width: 8),
            tab('resolved', 'Resolved'),
            const SizedBox(width: 8),
            tab('declined', 'Declined'),
            const SizedBox(width: 8),
            tab('all', 'All Requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(EmergencyRequestModel req) {
    Color badgeBg;
    Color badgeText;
    switch (req.status) {
      case EmergencyRequestStatus.pending:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        break;
      case EmergencyRequestStatus.approved:
      case EmergencyRequestStatus.resolved:
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF047857);
        break;
      case EmergencyRequestStatus.declined:
      case EmergencyRequestStatus.cancelled:
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.status == EmergencyRequestStatus.pending ? const Color(0xFFFCD34D) : AppColors.slate200,
          width: req.status == EmergencyRequestStatus.pending ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedRequest = req),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.riderName,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            req.reason,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        req.status.displayName,
                        style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    ),
                  ],
                ),
                if (req.description != null && req.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    req.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate600),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Text(
                          '${req.affectedOrderIds.length} stops affected',
                          style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    Text(
                      _formatTime(req.createdAt),
                      style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
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

  Widget _buildRequestDetailView(EmergencyRequestModel req) {
    final isPending = req.status == EmergencyRequestStatus.pending;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.sky50, shape: BoxShape.circle),
                      child: const Icon(Icons.two_wheeler, color: AppColors.primarySky, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.riderName,
                            style: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          if (req.riderPhone != null)
                            Text(
                              req.riderPhone!,
                              style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        req.reason,
                        style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
                if (req.description != null && req.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Text(
                      req.description!,
                      style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'AFFECTED DELIVERIES',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<OrderModel>>(
            stream: _firestoreService.getActiveOrdersStream(),
            builder: (context, ordersSnap) {
              if (!ordersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final affectedOrders = ordersSnap.data!
                  .where((o) => req.affectedOrderIds.contains(o.id))
                  .toList();

              if (affectedOrders.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Text(
                    'No active orders remaining for this request (already completed or cancelled).',
                    style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                  ),
                );
              }

              return Column(
                children: affectedOrders.map((order) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order.orderNumber} • ${order.customerName}',
                                style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress ?? 'No address',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₱${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => _showDeclineDialog(req),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.coralAlert),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.coralAlert),
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
                      onPressed: () => _openReassignmentModal(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text(
                        'Approve & Reassign',
                        style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (req.status == EmergencyRequestStatus.declined) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Decline Reason:', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert)),
                  const SizedBox(height: 2),
                  Text(req.declineReason ?? 'No reason provided.', style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
          ] else if (req.status == EmergencyRequestStatus.resolved) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                'Transferred successfully to ${req.replacementRiderName ?? 'replacement rider'}.',
                style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined, color: AppColors.primarySky, size: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Emergency Requests',
              style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFilter == 'pending'
                  ? 'All riders are operating normally with no pending help requests.'
                  : 'No requests matching this filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}