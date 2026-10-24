import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart'; // Added centralized layout constants
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_toast.dart';
import '../../models/refund_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_sheet_chrome.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import '../../widgets/screen_title_block.dart';
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
    required FontWeight weight,
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

  Future<void> _confirmDecline(RefundModel r) async {
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
      _showDeclineFormIds.remove(r.id);
      _underReviewIds.remove(r.id);
      AppToast.showSuccess(context, 'Decline explanation logged to telematics');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to log decline: $e');
    }
  }

  Future<void> _openDecisionSheet(RefundModel r) async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99020617),
      constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
      builder: (ctx) => _buildDecisionSheet(ctx, r),
    );
    if (choice != null && mounted) _executeDecision(r, choice);
  }

  Future<void> _executeDecision(RefundModel r, String type) async {
    if (type == 'decline') {
      setState(() => _showDeclineFormIds.add(r.id));
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
      barrierColor: const Color(0xCC020617),
      builder: (ctx) => ProofOfDeliveryDialog(
        title: title,
        subtitle: subtitle,
        imageUrl: photoUrl,
        chromeHeight: 210,
        badgeIcon: Icons.emergency,
        badgeIconColor: const Color(0xFFFB7185),
        badgeText: 'Impact Damage Detected',
        detailsChild: RichText(
          text: TextSpan(
            style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate600, height: 1.5),
            children: [
              const TextSpan(text: 'Timestamp: '),
              TextSpan(text: '10:42 AM Today', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.surfaceDark)),
              const TextSpan(text: ' • Geo-verified at customer delivery address.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionSheet(BuildContext ctx, RefundModel r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BottomSheetDragHandle(),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate100))),
                child: BottomSheetHeader(
                  title: 'OWNER REVIEW TERMINAL',
                  subtitle: 'Order #${r.orderNumber}\n${r.customerName}',
                  onClose: () => Navigator.pop(ctx),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
                    child: const Icon(Icons.gavel, size: 18, color: AppColors.primarySky),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.amber200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.report_problem, size: 18, color: AppColors.amber600),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.reason, style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.amber900)),
                          const SizedBox(height: 2),
                          Text(r.description, style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.amber800, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('SELECT OWNER RESOLUTION', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _decisionOption(
                ctx: ctx,
                value: 'refund',
                icon: Icons.account_balance_wallet,
                accent: AppColors.primarySky,
                bg: AppColors.surfaceIce,
                border: AppColors.sky200,
                title: 'Approve Full GCash Refund',
                subtitle: 'Authorize ₱${r.amount.toStringAsFixed(2)} GCash manual remittance',
              ),
              _decisionOption(
                ctx: ctx,
                value: 'redelivery',
                icon: Icons.local_shipping,
                accent: AppColors.emerald600,
                bg: AppColors.emerald50,
                border: AppColors.emerald200,
                title: 'Approve Priority Redelivery',
                subtitle: 'Dispatch ${r.itemsSummary.isEmpty ? "replacement item" : r.itemsSummary} free tomorrow',
              ),
              _decisionOption(
                ctx: ctx,
                value: 'decline',
                icon: Icons.cancel,
                accent: AppColors.rose600,
                bg: AppColors.rose50,
                border: AppColors.rose200,
                title: 'Decline Dispute Request',
                subtitle: 'Provide formal rejection and rider proof',
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate100,
                  foregroundColor: AppColors.slate600,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text('Cancel', style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.slate600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decisionOption({
    required BuildContext ctx,
    required String value,
    required IconData icon,
    required Color accent,
    required Color bg,
    required Color border,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.pop(ctx, value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.backgroundDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _ts(size: 10.5, weight: FontWeight.w500, color: AppColors.slate500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required Color bg, Color? border, required Widget leading, required String text, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, border: border == null ? null : Border.all(color: border), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(text, style: _ts(size: 10, weight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _settledPill() {
    return _pill(
      bg: AppColors.emerald50,
      border: AppColors.emerald200,
      leading: const Icon(Icons.check_circle, size: 12, color: AppColors.emerald700),
      text: 'Settled • GCash Remitted',
      fg: AppColors.emerald700,
    );
  }

  Widget _settledBox(String ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.emerald200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: AppColors.emerald600),
                const SizedBox(width: 6),
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.emerald800),
                      children: [
                        const TextSpan(text: 'Settled Ref: '),
                        TextSpan(text: ref, style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.emerald800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('Store #41 Logged', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.emerald600)),
        ],
      ),
    );
  }

  Widget _noticeBox(String text, IconData icon, Color bg, Color border, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(text, style: _ts(size: 12, weight: FontWeight.w600, color: fg))),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: fg),
        ],
      ),
    );
  }

  Widget _buildRequestCardShell({
    required RefundModel refund,
    required Color amountColor,
    required Widget badge,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('₱${refund.amount.toStringAsFixed(2)}', amountColor),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(refund.customerName, style: _ts(size: 15, weight: FontWeight.w700, color: AppColors.backgroundDark)),
                      const SizedBox(width: 8),
                      Text('#${refund.orderNumber}', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(refund.itemsSummary.isEmpty ? '—' : refund.itemsSummary, style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate500)),
                ],
              ),
              badge,
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<List<RefundModel>>(
      stream: _firestoreService.getRefundRequestsStream(),
      builder: (context, snapshot) {
        final List<RefundModel> refunds = snapshot.data ?? [];
        final List<RefundModel> visible = refunds.where(_visible).toList();
        final List<Widget> cards = visible.map(_buildCardFor).toList();

        return Scaffold(
          backgroundColor: AppColors.surfaceBackground,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 130 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleBlock(),
                      const SizedBox(height: 16),
                      _buildMetricsBar(refunds),
                      const SizedBox(height: 14),
                      _buildFilterRail(refunds),
                      const SizedBox(height: 16),
                      if (cards.isEmpty) _buildEmptyState(),
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        cards[i],
                      ],
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

  Widget _buildCardFor(RefundModel r) {
    if (r.status == RefundStatus.rejected) return _buildDeclinedCard(r);
    if (r.status == RefundStatus.approved || r.status == RefundStatus.processed) return _buildApprovedCard(r);
    if (_showDeclineFormIds.contains(r.id)) return _buildDeclineFormCard(r);
    return _buildPendingCard(r);
  }

  Widget _buildTitleBlock() {
    return const ScreenTitleBlock(
      badgeText: 'OWNER DISPUTE HUB',
      title: 'Owner Complaints & Refunds',
      icon: Icons.assignment_late,
    );
  }

  Widget _buildMetricsBar(List<RefundModel> refunds) {
    final int pending = _count(refunds, 'pending') + _count(refunds, 'under_review');
    final double settled = _settledAmount(refunds);
    return Row(
      children: [
        _buildMetricBox('Pending', Icons.hourglass_top, '$pending', 'Needs Action', AppColors.amber600, AppColors.amber700, AppColors.amber50),
        const SizedBox(width: 10),
        _buildMetricBox('Awaiting', Icons.account_balance_wallet, '${_awaitingCount(refunds)}', 'Ready GCash', AppColors.primarySky, AppColors.primarySky, AppColors.surfaceFrost),
        const SizedBox(width: 10),
        _buildMetricBox('Settled', Icons.check_circle, '₱${settled.toStringAsFixed(2)}', 'This Cycle', AppColors.emerald600, AppColors.emerald700, AppColors.emerald50),
      ],
    );
  }

  Widget _buildMetricBox(String title, IconData icon, String value, String pill, Color titleColor, Color valColor, Color pillBg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title.toUpperCase(), style: _ts(size: 10.5, weight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 0.5)),
                Icon(icon, size: 15, color: titleColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: _ts(size: 20, weight: FontWeight.w800, color: valColor), maxLines: 1, overflow: TextOverflow.ellipsis),
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

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = _activeFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() => _activeFilter = f['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primarySky : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isActive ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1))] : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        f['label']!,
                        style: _ts(size: 12, weight: isActive ? FontWeight.w700 : FontWeight.w600, color: isActive ? Colors.white : AppColors.slate600),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.25) : AppColors.slate200,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_count(refunds, f['key']!)}',
                          style: _ts(size: 10, weight: FontWeight.w700, color: isActive ? Colors.white : AppColors.slate600),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.surfaceIce, shape: BoxShape.circle),
            child: const Icon(Icons.inbox, size: 26, color: AppColors.primarySky),
          ),
          const SizedBox(height: 8),
          Text('No Dispute Items', style: _ts(size: 14, weight: FontWeight.w700, color: AppColors.surfaceDark)),
          const SizedBox(height: 4),
          Text('There are no records matching this category.', style: _ts(size: 12, weight: FontWeight.w400, color: AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _claimReasonChip(RefundModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: AppColors.rose50, border: Border.all(color: AppColors.rose200.withValues(alpha: 0.7)), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.broken_image, size: 13, color: AppColors.rose600),
          const SizedBox(width: 4),
          Text(r.reason, style: _ts(size: 10.5, weight: FontWeight.w700, color: AppColors.rose600)),
        ],
      ),
    );
  }

  String _redeliveryNoticeText(DateTime? scheduledAt) {
    if (scheduledAt == null) return 'Priority Redelivery scheduled';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour24 = scheduledAt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    final dateStr = '${months[scheduledAt.month - 1]} ${scheduledAt.day}, ${scheduledAt.year}';
    return 'Priority Redelivery dispatched for $dateStr at $hour12:$minute $ampm';
  }

  Widget _buildApprovedCard(RefundModel r) {
    final bool isRedelivery = r.resolutionType == 'redelivery';
    final Widget badge = isRedelivery
        ? _pill(bg: AppColors.emerald50, border: AppColors.emerald200, leading: const Icon(Icons.local_shipping, size: 12, color: AppColors.emerald700), text: 'Redelivery Queued', fg: AppColors.emerald700)
        : (r.status == RefundStatus.processed
        ? _settledPill()
        : _pill(bg: AppColors.surfaceFrost, leading: _dot(AppColors.primarySky), text: 'Approved • Ready GCash', fg: AppColors.primarySky));

    return _buildRequestCardShell(
      refund: r,
      amountColor: AppColors.primarySky,
      badge: badge,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate400)),
            _claimReasonChip(r),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate100)),
          child: Text('"${r.description}"', style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.borderDark, height: 1.4)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceIce.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceFrost)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _openEvidence('${r.reason} Proof', '${r.customerName} (#${r.orderNumber})', r.photoUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.sky200.withValues(alpha: 0.6))),
                      child: r.photoUrl != null
                          ? Image.network(
                        r.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: AppColors.slate400, size: 20),
                      )
                          : const Icon(Icons.image, color: AppColors.slate400, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 14, color: AppColors.emerald600),
                          const SizedBox(width: 4),
                          Text('Evidence Verified', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.surfaceDark)),
                        ],
                      ),
                      Text('Claim Proof (1 Photo)', style: _ts(size: 10, weight: FontWeight.w500, color: AppColors.slate500)),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openEvidence('${r.reason} Proof', '${r.customerName} (#${r.orderNumber})', r.photoUrl),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.sky200)),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 14, color: AppColors.primarySky),
                      const SizedBox(width: 4),
                      Text('View', style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.primarySky)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        if (!isRedelivery) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200.withValues(alpha: 0.7))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 14, decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(999))),
                        const SizedBox(width: 6),
                        Text('BENEFICIARY ACCOUNT', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.borderDark, letterSpacing: 0.5)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.emerald200)),
                      child: Text('Manual GCash Transfer', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.emerald700)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.gcashName.isEmpty ? r.customerName : r.gcashName, style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate500)),
                    Row(
                      children: [
                        Text(r.gcashNumber, style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.backgroundDark)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _copy(r.gcashNumber),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.slate200)),
                            child: const Icon(Icons.content_copy, size: 13, color: AppColors.primarySky),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (isRedelivery)
          _noticeBox(_redeliveryNoticeText(r.redeliveryScheduledAt), Icons.check_circle, AppColors.emerald50, AppColors.emerald200, AppColors.emerald800)
        else if (r.status == RefundStatus.processed)
          _settledBox(r.gcashRefNumber ?? '')
        else
          ElevatedButton(
            onPressed: () => _processApproved(r),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySky,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x330284C7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments, size: 18),
                const SizedBox(width: 8),
                Text('Process Manual GCash Refund', style: _ts(size: 12, weight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPendingCard(RefundModel r) {
    final bool underReview = _underReviewIds.contains(r.id);
    final Widget badge = underReview
        ? _pill(bg: AppColors.surfaceIce, border: AppColors.sky200, leading: _dot(AppColors.primarySky), text: 'Under Review', fg: AppColors.primarySky)
        : _pill(bg: AppColors.amber50, border: AppColors.amber200.withValues(alpha: 0.8), leading: _dot(AppColors.amber500), text: 'Pending Review', fg: AppColors.amber700);

    return _buildRequestCardShell(
      refund: r,
      amountColor: AppColors.amber700,
      badge: badge,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate400)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: AppColors.amber50, border: Border.all(color: AppColors.amber200.withValues(alpha: 0.7)), borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 13, color: AppColors.amber700),
                  const SizedBox(width: 4),
                  Text(r.reason, style: _ts(size: 10.5, weight: FontWeight.w700, color: AppColors.amber700)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate100)),
          child: Text('"${r.description}"', style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.borderDark, height: 1.4)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200.withValues(alpha: 0.7))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_iphone, size: 16, color: AppColors.primarySky),
                  const SizedBox(width: 8),
                  Text('GCash: ${r.gcashName.isEmpty ? r.customerName : r.gcashName}', style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate600)),
                ],
              ),
              Text(r.gcashNumber, style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.backgroundDark)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _toggleUnderReview(r.id),
                icon: const Icon(Icons.visibility, size: 15),
                label: Text(underReview ? 'Under Review ✓' : 'Mark Under Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: underReview ? AppColors.emerald50 : AppColors.surfaceIce,
                  foregroundColor: underReview ? AppColors.emerald700 : AppColors.primarySky,
                  elevation: 0,
                  side: BorderSide(color: underReview ? AppColors.emerald200 : AppColors.sky200),
                  textStyle: _ts(size: 12, weight: FontWeight.w700, color: underReview ? AppColors.emerald700 : AppColors.primarySky),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openDecisionSheet(r),
                icon: const Icon(Icons.gavel, size: 15),
                label: const Text('Review & Decide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySky,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  textStyle: _ts(size: 12, weight: FontWeight.w700, color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeclineFormCard(RefundModel r) {
    final TextEditingController ctrl = _declineControllerFor(r.id);
    final Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.rose50, border: Border.all(color: AppColors.rose200), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.cancel, size: 13, color: AppColors.rose600),
          const SizedBox(width: 4),
          Text('Decline Workspace', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.rose600)),
        ],
      ),
    );

    return _buildRequestCardShell(
      refund: r,
      amountColor: AppColors.backgroundDark,
      badge: badge,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate100)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CLAIM: ${r.reason.toUpperCase()}', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(r.description, style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate600, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.edit_note, size: 14, color: AppColors.rose600),
            const SizedBox(width: 4),
            Text('MANDATORY EXPLANATION', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.rose600, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 2,
          style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.backgroundDark),
          decoration: InputDecoration(
            hintText: 'E.g., Delivery attempted 3x with rider call logs...',
            hintStyle: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.surfaceCanvas,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _confirmDecline(r),
          icon: const Icon(Icons.block, size: 16),
          label: const Text('Confirm Decline'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rose600,
            foregroundColor: Colors.white,
            elevation: 1,
            textStyle: _ts(size: 12, weight: FontWeight.w700, color: Colors.white),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeclinedCard(RefundModel r) {
    final Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.rose50, border: Border.all(color: AppColors.rose200), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.cancel, size: 13, color: AppColors.rose600),
          const SizedBox(width: 4),
          Text('Declined', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.rose600)),
        ],
      ),
    );

    return _buildRequestCardShell(
      refund: r,
      amountColor: AppColors.backgroundDark,
      badge: badge,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate100)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CLAIM: ${r.reason.toUpperCase()}', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(r.description, style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate600, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.edit_note, size: 14, color: AppColors.rose600),
            const SizedBox(width: 4),
            Text('MANDATORY EXPLANATION', style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.rose600, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
          child: Text(
            r.rejectionReason ?? '—',
            style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.backgroundDark),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Decline Audit Updated'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceDark,
            disabledBackgroundColor: AppColors.surfaceDark,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 1,
            textStyle: _ts(size: 12, weight: FontWeight.w700, color: Colors.white),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader(String amount, Color amountColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: AppColors.primarySky),
              const SizedBox(width: 6),
              Text('ORDER DETAILS', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.primarySky, letterSpacing: 0.5)),
            ],
          ),
          Text(amount, style: _ts(size: 20, weight: FontWeight.w800, color: amountColor, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildAuditFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 14, color: AppColors.slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Encrypted AquaOps Telematics audit entry logged to Store #41',
            textAlign: TextAlign.center,
            style: _ts(size: 10, weight: FontWeight.w500, color: AppColors.slate400),
          ),
        ),
      ],
    );
  }
}