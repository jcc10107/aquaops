import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/refund_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/aqua_bottom_nav.dart';
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

  // Transient, per-card, local-only UI state — mirrors the original mock's
  // "Under Review" toggle and in-progress decline form. None of this is
  // persisted; it only affects which sub-view of a still-pending claim is
  // shown before the owner commits a real Firestore status change.
  final Set<String> _underReviewIds = {};
  final Set<String> _showDeclineFormIds = {};
  final Map<String, TextEditingController> _declineControllers = {};

  static const Color _bgCanvas = Color(0xFFF6FAFC);
  static const Color _primary = Color(0xFF0284C7);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);

  static const Color _amber50 = Color(0xFFFFFBEB);
  static const Color _amber200 = Color(0xFFFDE68A);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _amber600 = Color(0xFFD97706);
  static const Color _amber700 = Color(0xFFB45309);
  static const Color _amber800 = Color(0xFF92400E);
  static const Color _amber900 = Color(0xFF78350F);

  static const Color _emerald50 = Color(0xFFECFDF5);
  static const Color _emerald200 = Color(0xFFA7F3D0);
  static const Color _emerald600 = Color(0xFF059669);
  static const Color _emerald700 = Color(0xFF047857);
  static const Color _emerald800 = Color(0xFF065F46);

  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose600 = Color(0xFFE11D48);

  static const Color _sky50 = Color(0xFFF0F9FF);
  static const Color _sky100 = Color(0xFFE0F2FE);
  static const Color _sky200 = Color(0xFFBAE6FD);

  TextStyle _ts({required double size, required FontWeight weight, required Color color, double? height, double? letterSpacing}) {
    return GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
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
    // category is 'pending' or 'under_review' — a sub-split of RefundStatus.pending.
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

  void _toast(String message, [IconData icon = Icons.check_circle]) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _slate900,
        duration: const Duration(milliseconds: 2400),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF34D399)),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: _ts(size: 12, weight: FontWeight.w600, color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _copy(String phone) {
    Clipboard.setData(ClipboardData(text: phone.replaceAll(' ', '')));
    _toast('Copied $phone to clipboard!', Icons.content_copy);
  }

  void _toggleUnderReview(String refundId) {
    setState(() {
      if (_underReviewIds.contains(refundId)) {
        _underReviewIds.remove(refundId);
      } else {
        _underReviewIds.add(refundId);
      }
    });
    _toast(_underReviewIds.contains(refundId) ? 'Marked as Under Review' : 'Reverted to Pending status');
  }

  Future<void> _confirmDecline(RefundModel r) async {
    final TextEditingController ctrl = _declineControllerFor(r.id);
    if (ctrl.text.trim().isEmpty) {
      _toast('Please provide a mandatory explanation for declining.', Icons.error_outline);
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
      _toast('Decline explanation logged to telematics');
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to log decline: $e', Icons.error_outline);
    }
  }

  Future<void> _openDecisionSheet(RefundModel r) async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99020617),
      constraints: const BoxConstraints(maxWidth: 450),
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
        _toast('Approved! Ready for manual GCash transfer.');
      } else {
        _toast('Scheduled free ${r.itemsSummary.isEmpty ? "gallon" : r.itemsSummary} redelivery', Icons.local_shipping);
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to record decision: $e', Icons.error_outline);
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
      _toast('Refund Settled! GCash Ref #$ref recorded.');
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to record settlement: $e', Icons.error_outline);
    }
  }

  void _openEvidence(String title, String subtitle, [String? photoUrl]) {
    showDialog(
      context: context,
      barrierColor: const Color(0xCC020617),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: _slate50, border: Border(bottom: BorderSide(color: _slate100))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title.toUpperCase(), style: _ts(size: 12, weight: FontWeight.w700, color: _slate900, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(subtitle, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _slate200)),
                            child: const Icon(Icons.close, size: 16, color: _slate500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 190,
                    width: double.infinity,
                    color: _slate900,
                    child: Stack(
                      children: [
                        if (photoUrl != null)
                          Positioned.fill(
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.image, size: 48, color: _slate400)),
                            ),
                          )
                        else
                          const Center(child: Icon(Icons.image, size: 48, color: _slate400)),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emergency, size: 12, color: Color(0xFFFB7185)),
                                const SizedBox(width: 4),
                                Text('Impact Damage Detected', style: _ts(size: 10, weight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate100)),
                          child: RichText(
                            text: TextSpan(
                              style: _ts(size: 11, weight: FontWeight.w500, color: _slate600, height: 1.5),
                              children: [
                                const TextSpan(text: 'Timestamp: '),
                                TextSpan(text: '10:42 AM Today', style: _ts(size: 11, weight: FontWeight.w700, color: _slate800)),
                                const TextSpan(text: ' • Geo-verified at customer delivery address.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slate100,
                            foregroundColor: _slate800,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text('Close Preview', style: _ts(size: 12, weight: FontWeight.w700, color: _slate800)),
                        ),
                      ],
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

  Widget _buildDecisionSheet(BuildContext ctx, RefundModel r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _slate100)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: _slate200, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _slate100))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: _sky100, shape: BoxShape.circle),
                          child: const Icon(Icons.gavel, size: 18, color: _primary),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OWNER REVIEW TERMINAL', style: _ts(size: 12, weight: FontWeight.w700, color: _slate900, letterSpacing: 0.5)),
                            Text('Order #${r.orderNumber} • ${r.customerName}', style: _ts(size: 10, weight: FontWeight.w500, color: _slate400)),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: _slate100, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 16, color: _slate500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _amber50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amber200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.report_problem, size: 18, color: _amber600),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.reason, style: _ts(size: 12, weight: FontWeight.w700, color: _amber900)),
                          const SizedBox(height: 2),
                          Text(r.description, style: _ts(size: 11, weight: FontWeight.w500, color: _amber800, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('SELECT OWNER RESOLUTION', style: _ts(size: 11, weight: FontWeight.w700, color: _slate500, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _decisionOption(
                ctx: ctx,
                value: 'refund',
                icon: Icons.account_balance_wallet,
                accent: _primary,
                bg: _sky50,
                border: _sky200,
                title: 'Approve Full GCash Refund',
                subtitle: 'Authorize ₱${r.amount.toStringAsFixed(2)} GCash manual remittance',
              ),
              _decisionOption(
                ctx: ctx,
                value: 'redelivery',
                icon: Icons.local_shipping,
                accent: _emerald600,
                bg: _emerald50,
                border: _emerald200,
                title: 'Approve Priority Redelivery',
                subtitle: 'Dispatch ${r.itemsSummary.isEmpty ? "replacement item" : r.itemsSummary} free tomorrow',
              ),
              _decisionOption(
                ctx: ctx,
                value: 'decline',
                icon: Icons.cancel,
                accent: _rose600,
                bg: _rose50,
                border: _rose200,
                title: 'Decline Dispute Request',
                subtitle: 'Provide formal rejection and rider proof',
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _slate100,
                  foregroundColor: _slate600,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text('Cancel', style: _ts(size: 12, weight: FontWeight.w700, color: _slate600)),
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
                    Text(title, style: _ts(size: 12, weight: FontWeight.w700, color: _slate900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _ts(size: 10.5, weight: FontWeight.w500, color: _slate500)),
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
      bg: _emerald50,
      border: _emerald200,
      leading: const Icon(Icons.check_circle, size: 12, color: _emerald700),
      text: 'Settled • GCash Remitted',
      fg: _emerald700,
    );
  }

  Widget _settledBox(String ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _emerald50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _emerald200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: _emerald600),
                const SizedBox(width: 6),
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: _ts(size: 12, weight: FontWeight.w500, color: _emerald800),
                      children: [
                        const TextSpan(text: 'Settled Ref: '),
                        TextSpan(text: ref, style: _ts(size: 12, weight: FontWeight.w700, color: _emerald800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('Store #41 Logged', style: _ts(size: 10, weight: FontWeight.w700, color: _emerald600)),
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
          backgroundColor: _bgCanvas,
          extendBody: true,
          bottomNavigationBar: AquaBottomNav(
            isOwner: true,
            currentIndex: 4,
            onTap: (index) {
              if (index != 4) {
                Navigator.pop(context);
              }
            },
          ),
          body: Column(
            children: [
              const CustomHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
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
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.assignment_late, color: Color(0xFF0284C7), size: 22)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text('OWNER DISPUTE HUB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Owner Complaints & Refunds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2)),
      ],
    );
  }

  Widget _buildMetricsBar(List<RefundModel> refunds) {
    final int pending = _count(refunds, 'pending') + _count(refunds, 'under_review');
    final double settled = _settledAmount(refunds);
    return Row(
      children: [
        _buildMetricBox('Pending', Icons.hourglass_top, '$pending', 'Needs Action', _amber600, _amber700, _amber50),
        const SizedBox(width: 10),
        _buildMetricBox('Awaiting', Icons.account_balance_wallet, '${_awaitingCount(refunds)}', 'Ready GCash', _primary, _primary, _sky100),
        const SizedBox(width: 10),
        _buildMetricBox('Settled', Icons.check_circle, '₱${settled.toStringAsFixed(2)}', 'This Cycle', _emerald600, _emerald700, _emerald50),
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
          border: Border.all(color: _slate100),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title.toUpperCase(), style: _ts(size: 10.5, weight: FontWeight.w700, color: _slate500, letterSpacing: 0.5)),
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
        color: _slate100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _slate200.withValues(alpha: 0.7)),
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
                    color: isActive ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isActive ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1))] : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        f['label']!,
                        style: _ts(size: 12, weight: isActive ? FontWeight.w700 : FontWeight.w600, color: isActive ? Colors.white : _slate600),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.25) : _slate200,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_count(refunds, f['key']!)}',
                          style: _ts(size: 10, weight: FontWeight.w700, color: isActive ? Colors.white : _slate600),
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
        border: Border.all(color: _slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: _sky50, shape: BoxShape.circle),
            child: const Icon(Icons.inbox, size: 26, color: _primary),
          ),
          const SizedBox(height: 8),
          Text('No Dispute Items', style: _ts(size: 14, weight: FontWeight.w700, color: _slate800)),
          const SizedBox(height: 4),
          Text('There are no records matching this category.', style: _ts(size: 12, weight: FontWeight.w400, color: _slate400)),
        ],
      ),
    );
  }

  Widget _claimReasonChip(RefundModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: _rose50, border: Border.all(color: _rose200.withValues(alpha: 0.7)), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.broken_image, size: 13, color: _rose600),
          const SizedBox(width: 4),
          Text(r.reason, style: _ts(size: 10.5, weight: FontWeight.w700, color: _rose600)),
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
    return 'Priority Redelivery dispatched for $dateStr • $hour12:$minute $ampm';
  }

  Widget _buildApprovedCard(RefundModel r) {
    final bool isRedelivery = r.resolutionType == 'redelivery';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('₱${r.amount.toStringAsFixed(2)}', _primary),
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
                      Text(r.customerName, style: _ts(size: 15, weight: FontWeight.w700, color: _slate900)),
                      const SizedBox(width: 8),
                      Text('#${r.orderNumber}', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.itemsSummary.isEmpty ? '—' : r.itemsSummary, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                ],
              ),
              if (isRedelivery)
                _pill(bg: _emerald50, border: _emerald200, leading: const Icon(Icons.local_shipping, size: 12, color: _emerald700), text: 'Redelivery Queued', fg: _emerald700)
              else if (r.status == RefundStatus.processed)
                _settledPill()
              else
                _pill(bg: _sky100, leading: _dot(_primary), text: 'Approved • Ready GCash', fg: _primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
              _claimReasonChip(r),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate100)),
            child: Text('"${r.description}"', style: _ts(size: 12, weight: FontWeight.w500, color: _slate700, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _sky50.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: _sky100)),
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
                        decoration: BoxDecoration(color: _slate100, borderRadius: BorderRadius.circular(8), border: Border.all(color: _sky200.withValues(alpha: 0.6))),
                        child: r.photoUrl != null
                            ? Image.network(
                                r.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: _slate400, size: 20),
                              )
                            : const Icon(Icons.image, color: _slate400, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 14, color: _emerald600),
                            const SizedBox(width: 4),
                            Text('Evidence Verified', style: _ts(size: 11, weight: FontWeight.w700, color: _slate800)),
                          ],
                        ),
                        Text('Claim Proof (1 Photo)', style: _ts(size: 10, weight: FontWeight.w500, color: _slate500)),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _openEvidence('${r.reason} Proof', '${r.customerName} (#${r.orderNumber})', r.photoUrl),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: _sky200)),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: _primary),
                        const SizedBox(width: 4),
                        Text('View', style: _ts(size: 12, weight: FontWeight.w700, color: _primary)),
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
              decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate200.withValues(alpha: 0.7))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 14, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(999))),
                          const SizedBox(width: 6),
                          Text('BENEFICIARY ACCOUNT', style: _ts(size: 10, weight: FontWeight.w700, color: _slate700, letterSpacing: 0.5)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _emerald50, borderRadius: BorderRadius.circular(999), border: Border.all(color: _emerald200)),
                        child: Text('Manual GCash Transfer', style: _ts(size: 10, weight: FontWeight.w700, color: _emerald700)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.gcashName.isEmpty ? r.customerName : r.gcashName, style: _ts(size: 12, weight: FontWeight.w500, color: _slate500)),
                      Row(
                        children: [
                          Text(r.gcashNumber, style: _ts(size: 12, weight: FontWeight.w700, color: _slate900)),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _copy(r.gcashNumber),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _slate200)),
                              child: const Icon(Icons.content_copy, size: 13, color: _primary),
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
            _noticeBox(_redeliveryNoticeText(r.redeliveryScheduledAt), Icons.check_circle, _emerald50, _emerald200, _emerald800)
          else if (r.status == RefundStatus.processed)
            _settledBox(r.gcashRefNumber ?? '')
          else
            ElevatedButton(
              onPressed: () => _processApproved(r),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
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
      ),
    );
  }

  Widget _buildPendingCard(RefundModel r) {
    final bool underReview = _underReviewIds.contains(r.id);
    final Widget badge = underReview
        ? _pill(bg: _sky50, border: _sky200, leading: _dot(_primary), text: 'Under Review', fg: _primary)
        : _pill(bg: _amber50, border: _amber200.withValues(alpha: 0.8), leading: _dot(_amber500), text: 'Pending Review', fg: _amber700);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('₱${r.amount.toStringAsFixed(2)}', _amber700),
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
                      Text(r.customerName, style: _ts(size: 15, weight: FontWeight.w700, color: _slate900)),
                      const SizedBox(width: 8),
                      Text('#${r.orderNumber}', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.itemsSummary.isEmpty ? '—' : r.itemsSummary, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                ],
              ),
              badge,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: _amber50, border: Border.all(color: _amber200.withValues(alpha: 0.7)), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 13, color: _amber700),
                    const SizedBox(width: 4),
                    Text(r.reason, style: _ts(size: 10.5, weight: FontWeight.w700, color: _amber700)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate100)),
            child: Text('"${r.description}"', style: _ts(size: 12, weight: FontWeight.w500, color: _slate700, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate200.withValues(alpha: 0.7))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_iphone, size: 16, color: _primary),
                    const SizedBox(width: 8),
                    Text('GCash: ${r.gcashName.isEmpty ? r.customerName : r.gcashName}', style: _ts(size: 12, weight: FontWeight.w500, color: _slate600)),
                  ],
                ),
                Text(r.gcashNumber, style: _ts(size: 12, weight: FontWeight.w700, color: _slate900)),
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
                    backgroundColor: underReview ? _emerald50 : _sky50,
                    foregroundColor: underReview ? _emerald700 : _primary,
                    elevation: 0,
                    side: BorderSide(color: underReview ? _emerald200 : _sky200),
                    textStyle: _ts(size: 12, weight: FontWeight.w700, color: underReview ? _emerald700 : _primary),
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
                    backgroundColor: _primary,
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
      ),
    );
  }

  Widget _buildDeclineFormCard(RefundModel r) {
    final TextEditingController ctrl = _declineControllerFor(r.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('₱${r.amount.toStringAsFixed(2)}', _slate900),
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
                      Text(r.customerName, style: _ts(size: 15, weight: FontWeight.w700, color: _slate900)),
                      const SizedBox(width: 8),
                      Text('#${r.orderNumber}', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.itemsSummary.isEmpty ? '—' : r.itemsSummary, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _rose50, border: Border.all(color: _rose200), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, size: 13, color: _rose600),
                    const SizedBox(width: 4),
                    Text('Decline Workspace', style: _ts(size: 10, weight: FontWeight.w700, color: _rose600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLAIM: ${r.reason.toUpperCase()}', style: _ts(size: 11, weight: FontWeight.w700, color: _slate500, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(r.description, style: _ts(size: 12, weight: FontWeight.w500, color: _slate600, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.edit_note, size: 14, color: _rose600),
              const SizedBox(width: 4),
              Text('MANDATORY EXPLANATION', style: _ts(size: 11, weight: FontWeight.w700, color: _rose600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: 2,
            style: _ts(size: 12, weight: FontWeight.w500, color: _slate900),
            decoration: InputDecoration(
              hintText: 'E.g., Delivery attempted 3x with rider call logs...',
              hintStyle: _ts(size: 12, weight: FontWeight.w500, color: _slate400),
              filled: true,
              fillColor: _slate50,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _confirmDecline(r),
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Confirm Decline'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose600,
              foregroundColor: Colors.white,
              elevation: 1,
              textStyle: _ts(size: 12, weight: FontWeight.w700, color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDeclinedCard(RefundModel r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate100),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('₱${r.amount.toStringAsFixed(2)}', _slate900),
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
                      Text(r.customerName, style: _ts(size: 15, weight: FontWeight.w700, color: _slate900)),
                      const SizedBox(width: 8),
                      Text('#${r.orderNumber}', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.itemsSummary.isEmpty ? '—' : r.itemsSummary, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _rose50, border: Border.all(color: _rose200), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, size: 13, color: _rose600),
                    const SizedBox(width: 4),
                    Text('Declined', style: _ts(size: 10, weight: FontWeight.w700, color: _rose600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLAIM: ${r.reason.toUpperCase()}', style: _ts(size: 11, weight: FontWeight.w700, color: _slate500, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(r.description, style: _ts(size: 12, weight: FontWeight.w500, color: _slate600, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.edit_note, size: 14, color: _rose600),
              const SizedBox(width: 4),
              Text('MANDATORY EXPLANATION', style: _ts(size: 11, weight: FontWeight.w700, color: _rose600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _slate200)),
            child: Text(
              r.rejectionReason ?? '—',
              style: _ts(size: 12, weight: FontWeight.w500, color: _slate900),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Decline Audit Updated'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _slate800,
              disabledBackgroundColor: _slate800,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 1,
              textStyle: _ts(size: 12, weight: FontWeight.w700, color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardHeader(String amount, Color amountColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _slate100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: _primary),
              const SizedBox(width: 6),
              Text('ORDER DETAILS', style: _ts(size: 11, weight: FontWeight.w800, color: _primary, letterSpacing: 0.5)),
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
        const Icon(Icons.lock, size: 14, color: _slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Encrypted AquaOps Telematics audit entry logged to Store #41',
            textAlign: TextAlign.center,
            style: _ts(size: 10, weight: FontWeight.w500, color: _slate400),
          ),
        ),
      ],
    );
  }
}
