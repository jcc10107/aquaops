import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_toast.dart';
import '../../models/refund_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_sheet_chrome.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import 'owner_refund_processing_screen.dart';

class OwnerRequestScreen extends StatefulWidget {
  const OwnerRequestScreen({super.key});

  @override
  State<OwnerRequestScreen> createState() => _OwnerRequestScreenState();
}

class _OwnerRequestScreenState extends State<OwnerRequestScreen> {
  String _activeFilter = 'all';
  final FirestoreService _firestoreService = FirestoreService();
  String _currentUserName = 'Owner';

  final Set<String> _underReviewIds = {};
  final Set<String> _showDeclineFormIds = {};
  final Map<String, TextEditingController> _declineControllers = {};

  TextStyle _ts({
    required double size,
    FontWeight weight = FontWeight.w500,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      AppTypography.ts(
        size: size,
        weight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final String? uid = AuthService().currentUserId;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted && profile != null) setState(() => _currentUserName = profile.name);
  }

  @override
  void dispose() {
    for (final c in _declineControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _declineControllerFor(String id) {
    return _declineControllers.putIfAbsent(id, () => TextEditingController());
  }

  bool _isPendingVisible(RefundModel r, String category) {
    final bool underReview = _underReviewIds.contains(r.id);
    return category == 'pending' ? !underReview : underReview;
  }

  int _count(List<RefundModel> refunds, String key) {
    if (key == 'all') return refunds.length;
    if (key == 'pending') return refunds.where((r) => r.status == RefundStatus.pending && _isPendingVisible(r, 'pending')).length;
    if (key == 'under_review') return refunds.where((r) => r.status == RefundStatus.pending && _isPendingVisible(r, 'under_review')).length;
    if (key == 'approved') return refunds.where((r) => r.status == RefundStatus.approved || r.status == RefundStatus.processed).length;
    if (key == 'declined') return refunds.where((r) => r.status == RefundStatus.rejected).length;
    return 0;
  }

  bool _visible(RefundModel r) {
    if (_activeFilter == 'all') return true;
    if (r.status == RefundStatus.pending) return _isPendingVisible(r, _activeFilter);
    if (_activeFilter == 'approved') return r.status == RefundStatus.approved || r.status == RefundStatus.processed;
    if (_activeFilter == 'declined') return r.status == RefundStatus.rejected;
    return false;
  }

  int _awaitingCount(List<RefundModel> refunds) {
    return refunds.where((r) => r.status == RefundStatus.approved && r.resolutionType != 'redelivery').length;
  }

  double _settledAmount(List<RefundModel> refunds) {
    return refunds.where((r) => r.status == RefundStatus.processed).fold(0.0, (sum, r) => sum + r.amount);
  }

  void _copy(String phone) {
    Clipboard.setData(ClipboardData(text: phone.replaceAll(' ', '')));
    AppToast.showInfo(context, 'Copied $phone to clipboard!');
  }

  void _toggleUnderReview(String refundId) {
    setState(() {
      if (_underReviewIds.contains(refundId)) {
        _underReviewIds.remove(refundId);
      } else {
        _underReviewIds.add(refundId);
      }
    });
    AppToast.showInfo(
      context,
      _underReviewIds.contains(refundId)
          ? 'Marked as Under Review'
          : 'Reverted to Pending status',
    );
  }

  Future<void> _confirmDecline(RefundModel r, [StateSetter? setModalState]) async {
    final TextEditingController ctrl = _declineControllerFor(r.id);
    if (ctrl.text.trim().isEmpty) {
      AppToast.showError(context, 'Please provide a mandatory explanation for declining.');
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      await _firestoreService.processRefundRequest(
        refundId: r.id,
        status: 'rejected',
        processedByName: _currentUserName,
        rejectionReason: ctrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _showDeclineFormIds.remove(r.id);
        _underReviewIds.remove(r.id);
      });
      if (setModalState != null) {
        setModalState(() {
          _showDeclineFormIds.remove(r.id);
        });
      }
      Navigator.of(context, rootNavigator: true).pop();
      AppToast.showSuccess(context, 'Decline explanation logged.');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to log decline: $e');
    }
  }

  Future<void> _executeDecision(RefundModel r, String type) async {
    if (type == 'decline') {
      setState(() => _showDeclineFormIds.add(r.id));
      _openRefundDetails(r);
      return;
    }
    DateTime? redeliveryScheduledAt;
    if (type == 'redelivery') {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (pickedDate == null || !mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 30),
      );
      if (pickedTime == null || !mounted) return;
      redeliveryScheduledAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    }
    try {
      await _firestoreService.processRefundRequest(
        refundId: r.id,
        status: 'approved',
        processedByName: _currentUserName,
        resolutionType: type,
        redeliveryScheduledAt: redeliveryScheduledAt,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (type == 'refund') {
        AppToast.showSuccess(context, 'Approved! Ready for manual GCash transfer.');
      } else {
        AppToast.showSuccess(
          context,
          'Scheduled free ${r.itemsSummary.isEmpty ? "gallon" : r.itemsSummary} redelivery',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to record decision: $e');
    }
  }

  Future<void> _processApproved(RefundModel r) async {
    Navigator.of(context, rootNavigator: true).pop();
    final String? ref = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerRefundProcessingScreen(
          customerName: r.customerName,
          orderNumber: r.orderNumber,
          orderMeta: 'Claim filed ${r.requestedAt.month}/${r.requestedAt.day}/${r.requestedAt.year}',
          itemsSummary: r.itemsSummary.isEmpty ? '—' : r.itemsSummary,
          claimReason: r.reason,
          claimIcon: Icons.broken_image,
          amount: '₱${r.amount.toStringAsFixed(2)}',
          gcashNumber: r.gcashNumber,
        ),
      ),
    );
    if (ref == null || !mounted) return;
    try {
      await _firestoreService.processRefundRequest(
        refundId: r.id,
        status: 'processed',
        processedByName: _currentUserName,
        gcashRefNumber: ref,
      );
      if (!mounted) return;
      AppToast.showSuccess(context, 'Refund Settled! GCash Ref #$ref recorded.');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to record settlement: $e');
    }
  }

  void _openEvidence(String title, String subtitle, [String? photoUrl]) {
    showDialog(
      context: context,
      barrierColor: AppColors.backgroundDark.withValues(alpha: 0.6),
      builder: (ctx) => ProofOfDeliveryDialog(
        title: title,
        subtitle: subtitle,
        imageUrl: photoUrl,
        chromeHeight: 210,
        badgeIcon: Icons.emergency,
        badgeIconColor: AppColors.coralAlert,
        badgeText: 'Damage Evidence Attached',
        detailsChild: RichText(
          text: TextSpan(
            style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate600, height: 1.5),
            children: [
              const TextSpan(text: 'Audit Log: '),
              TextSpan(text: 'Filed by customer', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.textLight)),
              const TextSpan(text: ' • Geo-verified delivery item proof.'),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // PROGRESSIVE DISCLOSURE: FULL DETAILS SHEET
  // ========================================================
  void _openRefundDetails(RefundModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.backgroundDark.withValues(alpha: 0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool underReview = _underReviewIds.contains(r.id);
            final bool showDecline = _showDeclineFormIds.contains(r.id);
            final bool isRedelivery = r.resolutionType == 'redelivery';

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${r.orderNumber}',
                                  style: _ts(size: 17, weight: FontWeight.bold, color: AppColors.textLight),
                                ),
                                Text(
                                  r.customerName,
                                  style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const Spacer(),
                            _buildStatusBadge(r),
                            const SizedBox(width: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.slate200),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Amount & Summary Bar
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('REQUESTED AMOUNT', style: _ts(size: 10, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₱${r.amount.toStringAsFixed(2)}',
                                          style: _ts(size: 22, weight: FontWeight.w800, color: AppColors.primarySky),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('ITEMS CLAIMED', style: _ts(size: 10, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                                        const SizedBox(height: 2),
                                        Text(
                                          r.itemsSummary.isEmpty ? 'General item' : r.itemsSummary,
                                          style: _ts(size: 13, weight: FontWeight.w700, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 2. Complaint & Customer Description
                              Text('DISPUTE REASON', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.report_problem, size: 16, color: AppColors.amber600),
                                        const SizedBox(width: 6),
                                        Text(r.reason, style: _ts(size: 13, weight: FontWeight.w700, color: AppColors.textLight)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r.description.isEmpty ? 'No additional comments provided.' : '"${r.description}"',
                                      style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 3. Evidence / Photo
                              Text('CUSTOMER EVIDENCE', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.slate200),
                                          ),
                                          child: r.photoUrl != null
                                              ? Image.network(
                                            r.photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: AppColors.slate400, size: 20),
                                          )
                                              : const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.photoUrl != null ? 'Photo Attached (1 item)' : 'No Photo Uploaded',
                                              style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.textLight),
                                            ),
                                            Text(
                                              'Delivery claim proof',
                                              style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (r.photoUrl != null)
                                      OutlinedButton.icon(
                                        onPressed: () => _openEvidence('${r.reason} Proof', '${r.customerName} (#${r.orderNumber})', r.photoUrl),
                                        icon: const Icon(Icons.visibility, size: 14),
                                        label: const Text('Inspect'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primarySky,
                                          side: const BorderSide(color: AppColors.sky200),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 4. Beneficiary GCash Details
                              Text('GCASH ACCOUNT NUMBER', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.gcashName.isEmpty ? r.customerName : r.gcashName,
                                          style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          r.gcashNumber.isEmpty ? 'No GCash provided' : r.gcashNumber,
                                          style: _ts(size: 14, weight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                    if (r.gcashNumber.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () => _copy(r.gcashNumber),
                                        icon: const Icon(Icons.content_copy, size: 13),
                                        label: const Text('Copy'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primarySky,
                                          side: const BorderSide(color: AppColors.slate200),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 5. Decision & Resolution Controls
                              if (r.status == RefundStatus.pending) ...[
                                if (showDecline) ...[
                                  Text('MANDATORY DECLINE REASON', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.rose600, letterSpacing: 0.5)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _declineControllerFor(r.id),
                                    maxLines: 2,
                                    style: _ts(size: 13, weight: FontWeight.w500, color: AppColors.textLight),
                                    decoration: InputDecoration(
                                      hintText: 'Provide explanation for rejection...',
                                      hintStyle: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate400),
                                      filled: true,
                                      fillColor: AppColors.slate50,
                                      contentPadding: const EdgeInsets.all(12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.rose600)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setModalState(() => _showDeclineFormIds.remove(r.id)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.slate200),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text('Cancel', style: _ts(size: 12, weight: FontWeight.w600, color: AppColors.slate600)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _confirmDecline(r, setModalState),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.rose600,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text('Confirm Decline', style: _ts(size: 12, weight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _toggleUnderReview(r.id);
                                            setModalState(() {});
                                          },
                                          icon: Icon(underReview ? Icons.check_circle : Icons.visibility, size: 14),
                                          label: Text(underReview ? 'Under Review ✓' : 'Mark Review'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: underReview ? AppColors.emerald700 : AppColors.primarySky,
                                            side: BorderSide(color: underReview ? AppColors.emerald200 : AppColors.slate200),
                                            backgroundColor: underReview ? AppColors.emerald50 : Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setModalState(() => _showDeclineFormIds.add(r.id)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.rose600,
                                            side: const BorderSide(color: AppColors.rose200),
                                            backgroundColor: AppColors.rose50,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Decline Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _executeDecision(r, 'redelivery'),
                                          icon: const Icon(Icons.local_shipping, size: 15),
                                          label: const Text('Approve Redelivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.emerald700,
                                            side: const BorderSide(color: AppColors.emerald200),
                                            backgroundColor: AppColors.emerald50,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _executeDecision(r, 'refund'),
                                          icon: const Icon(Icons.check, size: 15),
                                          label: const Text('Approve GCash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primarySky,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ] else if (r.status == RefundStatus.approved) ...[
                                if (isRedelivery)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.emerald200)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_shipping, size: 18, color: AppColors.emerald700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _redeliveryNoticeText(r.redeliveryScheduledAt),
                                            style: _ts(size: 12, weight: FontWeight.w600, color: AppColors.emerald800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: () => _processApproved(r),
                                    icon: const Icon(Icons.account_balance_wallet, size: 16),
                                    label: const Text('Process Manual GCash Refund', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primarySky,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                              ] else if (r.status == RefundStatus.processed) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.emerald200)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, size: 18, color: AppColors.emerald700),
                                      const SizedBox(width: 8),
                                      Text('Settled via GCash: Ref #${r.gcashRefNumber ?? '—'}', style: _ts(size: 12, weight: FontWeight.bold, color: AppColors.emerald800)),
                                    ],
                                  ),
                                ),
                              ] else if (r.status == RefundStatus.rejected) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.rose50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.rose200)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.cancel, size: 16, color: AppColors.rose600),
                                          const SizedBox(width: 6),
                                          Text('Decline Reason Logged:', style: _ts(size: 12, weight: FontWeight.bold, color: AppColors.rose600)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.rejectionReason ?? 'No reason stated.',
                                        style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
      },
    );
  }

  // ========================================================
  // COMPACT SUMMARY LIST CARD
  // ========================================================
  Widget _buildCompactRequestCard(RefundModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRefundDetails(r),
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
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.sky50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primarySky),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${r.orderNumber}',
                                style: _ts(size: 13, weight: FontWeight.w800, color: AppColors.textLight),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  r.customerName,
                                  style: _ts(size: 13, weight: FontWeight.bold, color: AppColors.textLight),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(r),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        r.reason,
                        style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.requestedAt.month}/${r.requestedAt.day}/${r.requestedAt.year}',
                      style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    if (r.photoUrl != null) ...[
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 13, color: AppColors.slate400),
                          const SizedBox(width: 2),
                          Text('Evidence', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '₱${r.amount.toStringAsFixed(2)} ',
                            style: _ts(size: 16, weight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          TextSpan(
                            text: r.status == RefundStatus.processed ? 'settled' : 'requested',
                            style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: _ts(size: 12, weight: FontWeight.bold, color: AppColors.primarySky),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primarySky),
                      ],
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

  Widget _buildStatusBadge(RefundModel r) {
    final bool underReview = _underReviewIds.contains(r.id);
    if (r.status == RefundStatus.rejected) {
      return _statusPill(bg: AppColors.rose50, border: AppColors.rose200, fg: AppColors.rose600, label: 'Declined');
    }
    if (r.status == RefundStatus.processed) {
      return _statusPill(bg: AppColors.emerald50, border: AppColors.emerald200, fg: AppColors.emerald700, label: 'Settled');
    }
    if (r.status == RefundStatus.approved) {
      return r.resolutionType == 'redelivery'
          ? _statusPill(bg: AppColors.emerald50, border: AppColors.emerald200, fg: AppColors.emerald700, label: 'Redelivery')
          : _statusPill(bg: AppColors.sky50, border: AppColors.sky200, fg: AppColors.primarySky, label: 'Approved');
    }
    if (underReview) {
      return _statusPill(bg: AppColors.sky50, border: AppColors.sky200, fg: AppColors.primarySky, label: 'Under Review');
    }
    return _statusPill(bg: AppColors.amber50, border: AppColors.amber200, fg: AppColors.amber700, label: 'Pending');
  }

  Widget _statusPill({required Color bg, required Color border, required Color fg, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
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
    return 'Priority Redelivery for $dateStr at $hour12:$minute $ampm';
  }

  // ========================================================
  // MAIN BUILD
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<List<RefundModel>>(
      stream: _firestoreService.getRefundRequestsStream(),
      builder: (context, snapshot) {
        final List<RefundModel> refunds = snapshot.data ?? [];
        final List<RefundModel> visible = refunds.where(_visible).toList();

        return Scaffold(
          backgroundColor: AppColors.surfaceBackground,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 130 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clean Header without redundant eyebrow text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.sky50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment_late,
                              color: AppColors.primarySky,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Complaints & Refunds',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Metrics Summary
                      _buildMetricsBar(refunds),
                      const SizedBox(height: 16),

                      // Filter Rail
                      _buildFilterRail(refunds),
                      const SizedBox(height: 20),

                      // Section Title
                      Row(
                        children: [
                          const Text(
                            'Dispute Requests',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${visible.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cards List or Empty State
                      if (visible.isEmpty)
                        _buildEmptyState()
                      else
                        ...visible.map((r) => _buildCompactRequestCard(r)),

                      const SizedBox(height: 16),
                      _buildAuditFootnote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsBar(List<RefundModel> refunds) {
    final int pending = _count(refunds, 'pending') + _count(refunds, 'under_review');
    final double settled = _settledAmount(refunds);
    return Row(
      children: [
        _buildMetricBox('Pending', Icons.hourglass_top, '$pending', 'Needs Action', AppColors.amber700, AppColors.amber50),
        const SizedBox(width: 10),
        _buildMetricBox('Awaiting', Icons.account_balance_wallet, '${_awaitingCount(refunds)}', 'Ready GCash', AppColors.primarySky, AppColors.sky50),
        const SizedBox(width: 10),
        _buildMetricBox('Settled', Icons.check_circle, '₱${settled.toStringAsFixed(0)}', 'Remitted', AppColors.emerald700, AppColors.emerald50),
      ],
    );
  }

  Widget _buildMetricBox(String title, IconData icon, String value, String pill, Color valColor, Color pillBg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Text(title.toUpperCase(), style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 0.5)),
                Icon(icon, size: 15, color: valColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: _ts(size: 18, weight: FontWeight.w800, color: valColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
              child: Text(pill, style: _ts(size: 9.5, weight: FontWeight.w700, color: valColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRail(List<RefundModel> refunds) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'under_review', 'label': 'Under Review'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'declined', 'label': 'Declined'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isActive = _activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primarySky : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isActive ? AppColors.primarySky : AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Text(
                      f['label']!,
                      style: _ts(
                        size: 12,
                        weight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white.withValues(alpha: 0.25) : AppColors.slate100,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${_count(refunds, f['key']!)}',
                        style: _ts(size: 10, weight: FontWeight.w700, color: isActive ? Colors.white : AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.sky50, shape: BoxShape.circle),
            child: const Icon(Icons.inbox, size: 24, color: AppColors.primarySky),
          ),
          const SizedBox(height: 10),
          Text('No Dispute Items', style: _ts(size: 14, weight: FontWeight.w700, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text('There are no requests matching this filter.', style: _ts(size: 12, weight: FontWeight.w400, color: AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _buildAuditFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 13, color: AppColors.slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'AquaOps encrypted telematics audit entry logged to Store #41',
            textAlign: TextAlign.center,
            style: _ts(size: 10, weight: FontWeight.w500, color: AppColors.slate400),
          ),
        ),
      ],
    );
  }
}