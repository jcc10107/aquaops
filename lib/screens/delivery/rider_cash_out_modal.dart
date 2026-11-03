import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/rider_cash_out_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_sheet_chrome.dart';

class RiderCashOutModal extends StatefulWidget {
  const RiderCashOutModal({super.key});

  @override
  State<RiderCashOutModal> createState() => _RiderCashOutModalState();
}

class _RiderCashOutModalState extends State<RiderCashOutModal> {
  static const double _headerHeight = 64;
  static const String _font = 'Plus Jakarta Sans';

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _cashHandedOverCtrl = TextEditingController();
  final TextEditingController _verifiedByCtrl = TextEditingController();
  final FocusNode _cashFocus = FocusNode();

  String? _selectedRiderId;
  bool _certified = true;
  bool _isSubmitting = false;
  bool _isDone = false;
  double? _lastDiscrepancy;

  int _ownerTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cashHandedOverCtrl.addListener(() => setState(() {}));
    _prefillVerifierName();
  }

  @override
  void dispose() {
    _cashHandedOverCtrl.dispose();
    _verifiedByCtrl.dispose();
    _cashFocus.dispose();
    super.dispose();
  }

  Future<void> _prefillVerifierName() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted && profile != null) {
      _verifiedByCtrl.text = profile.name;
    }
  }

  Future<void> _submitRiderTurnover(
      UserModel rider,
      double expectedCash,
      double gcashCollected,
      int stopsCompleted,
      int gallonsDelivered,
      int emptiesReturned,
      List<String> orderIds,
      DateTime since,
      ) async {
    if (!_certified) return;
    final reported = double.tryParse(_cashHandedOverCtrl.text);
    if (reported == null) {
      AppToast.showError(context, 'Please enter the physical cash amount you are turning over.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _firestoreService.submitRiderCashOutRequest(
        riderId: rider.id,
        riderName: rider.name,
        reportedCash: reported,
        expectedCash: expectedCash,
        gcashCollected: gcashCollected,
        stopsCompleted: stopsCompleted,
        gallonsDelivered: gallonsDelivered,
        emptiesReturned: emptiesReturned,
        orderIds: orderIds,
        since: since,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      AppToast.showSuccess(context, 'Turnover submitted. Please hand cash to dispatch for counting.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, 'Failed to submit turnover: $e');
    }
  }

  Future<void> _verifyPendingCashOut(Map<String, dynamic> pendingReq) async {
    final cashOutId = pendingReq['id'] as String;
    final actualCash = double.tryParse(_cashHandedOverCtrl.text);
    if (actualCash == null) {
      AppToast.showError(context, 'Please enter the counted cash amount received.');
      return;
    }

    final verifierName = _verifiedByCtrl.text.trim();
    if (verifierName.isEmpty) {
      AppToast.showError(context, 'Please enter the verifying staff name.');
      return;
    }

    final verifierId = AuthService().currentUserId ?? '';

    setState(() => _isSubmitting = true);
    try {
      final discrepancy = await _firestoreService.verifyAndCloseRiderCashOut(
        cashOutId: cashOutId,
        actualCashReceived: actualCash,
        verifiedByName: verifierName,
        verifiedById: verifierId,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isDone = true;
        _lastDiscrepancy = discrepancy;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, 'Failed to verify cash-out: $e');
    }
  }

  Future<void> _closeCashOutDirect(UserModel rider, DateTime since) async {
    if (!_certified) return;
    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
    if (handedOver == null) {
      AppToast.showError(context, 'Please enter the counted cash amount.');
      return;
    }
    if (_verifiedByCtrl.text.trim().isEmpty) {
      AppToast.showError(context, 'Please enter the verifying staff name.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final discrepancy = await _firestoreService.closeRiderCashOut(
        riderId: rider.id,
        riderName: rider.name,
        since: since,
        cashHandedOver: handedOver,
        verifiedByName: _verifiedByCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isDone = true;
        _lastDiscrepancy = discrepancy;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, 'Failed to close cash-out: $e');
    }
  }

  TextStyle _mono(double size, {FontWeight weight = FontWeight.w700, Color color = AppColors.textLight, double letterSpacing = 0}) {
    return GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = UserRole.fromString(currentUserRoleNotifier.value);
    final isRider = currentRole == UserRole.rider;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildHeader(isRider),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(isRider),
                        const SizedBox(height: 14),
                        if (isRider)
                          _buildRiderWorkflow()
                        else
                          _buildOwnerWorkflow(),
                      ],
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

  Widget _buildHeader(bool isRider) {
    return Container(
      height: _headerHeight,
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
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.primarySky),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRider ? 'Turn Over Shift Cash' : 'Rider Cash-Out',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRider ? 'Physical Collection Hand-Off' : 'Shift Cash Reconciliation Protocol',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
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

  Widget _buildHero(bool isRider) {
    return _buildCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange, size: 22, color: AppColors.emerald700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRider ? 'RIDER TURN-OVER' : 'CASH RECONCILIATION',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.emerald700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRider ? 'Submit Shift COD Collections' : 'Rider Turn-Over & Shift Close',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isRider
                      ? 'Count your physical COD cash and submit for dispatch verification.'
                      : 'Verify physical COD cash collections and container returns.',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderWorkflow() {
    final currentUserId = AuthService().currentUserId ?? '';
    if (currentUserId.isEmpty) {
      return _buildCard(child: const Text('Authentication required.'));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firestoreService.getActiveRiderPendingCashOutStream(currentUserId),
      builder: (context, pendingSnapshot) {
        final pendingData = pendingSnapshot.data;

        if (pendingData != null) {
          return _buildRiderPendingWaitingCard(pendingData);
        }

        return StreamBuilder<UserModel?>(
          stream: _firestoreService.getUserStream(currentUserId),
          builder: (context, userSnap) {
            // FIX: Added required phone: '' parameter to UserModel
            final rider = userSnap.data ?? UserModel(
              id: currentUserId,
              email: '',
              name: 'Rider',
              phone: '',
              role: UserRole.rider,
            );

            return StreamBuilder<RiderCashOutModel?>(
              stream: _firestoreService.getLatestRiderCashOutStream(currentUserId),
              builder: (context, lastCashOutSnap) {
                final since = lastCashOutSnap.data?.closedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                return StreamBuilder<List<OrderModel>>(
                  stream: _firestoreService.getAllOrdersStream(),
                  builder: (context, ordersSnap) {
                    final allOrders = ordersSnap.data ?? const <OrderModel>[];

                    // FIX: Uses revenueDate.isAfter(since)
                    final orders = allOrders.where((o) {
                      return o.assignedRiderId == currentUserId &&
                          o.status == OrderStatus.delivered &&
                          o.revenueDate.isAfter(since);
                    }).toList();

                    return _buildRiderTurnoverSubmission(rider, since, orders);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRiderPendingWaitingCard(Map<String, dynamic> data) {
    final reportedCash = (data['reportedCash'] as num?)?.toDouble() ?? 0.0;
    final expectedCash = (data['cashCollected'] as num?)?.toDouble() ?? 0.0;
    final stops = data['stopsCompleted'] as int? ?? 0;
    final cashOutId = data['id'] as String;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Turnover Submitted', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    Text('Awaiting Station Dispatch Verification', style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.slate200),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reported Physical Cash:', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
              Text('₱${reportedCash.toStringAsFixed(2)}', style: _mono(14, color: AppColors.emerald700, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expected COD Total:', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
              Text('₱${expectedCash.toStringAsFixed(2)}', style: _mono(14, color: AppColors.textLight, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Completed Stops:', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
              Text('$stops stops', style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () async {
                try {
                  await _firestoreService.cancelRiderCashOutRequest(cashOutId, AuthService().currentUserId!);
                  // FIX: Guarded context with mounted check
                  if (!mounted) return;
                  AppToast.showSuccess(context, 'Turnover request cancelled.');
                } catch (e) {
                  // FIX: Guarded context with mounted check
                  if (!mounted) return;
                  AppToast.showError(context, 'Failed to cancel: $e');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.coralAlert),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel & Recount Cash', style: TextStyle(fontFamily: _font, color: AppColors.coralAlert, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderTurnoverSubmission(UserModel rider, DateTime since, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.emerald600, size: 36),
                SizedBox(height: 10),
                Text('All Deliveries Reconciled', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                SizedBox(height: 2),
                Text('You have no unremitted COD collections for this shift.', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final summary = summarizeRiderCashOut(orders);
    final stopsCompleted = summary.stopsCompleted;
    final gallonsDelivered = summary.gallonsDelivered;
    final emptiesReturned = summary.emptiesReturned;
    final cashCollected = summary.cashCollected;
    final gcashCollected = summary.gcashCollected;
    final orderIds = orders.map((o) => o.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DELIVERIES READY FOR TURN-OVER',
          style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.local_shipping_outlined, '$stopsCompleted stops', 'Completed Routes')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(Icons.water_drop_outlined, '$gallonsDelivered units', 'Gallons Delivered')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.autorenew, '$emptiesReturned units', 'Empties Retrieved')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(Icons.qr_code_2, '₱${gcashCollected.toStringAsFixed(2)}', 'GCash Drop-Offs')),
          ],
        ),
        const SizedBox(height: 14),
        _buildCashCollectedCard(cashCollected),
        const SizedBox(height: 14),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PHYSICAL CASH TURNOVER', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              const Text('Counted Cash Being Handed Over (₱)', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Text('₱ ', style: _mono(17, color: AppColors.emerald700, weight: FontWeight.bold)),
                    Expanded(
                      child: TextFormField(
                        controller: _cashHandedOverCtrl,
                        focusNode: _cashFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: _mono(17, weight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                          hintText: cashCollected.toStringAsFixed(2),
                          hintStyle: _mono(17, color: AppColors.slate400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCertifyCard(
          double.tryParse(_cashHandedOverCtrl.text) ?? cashCollected,
          emptiesReturned,
          isRider: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_certified && !_isSubmitting)
                ? () => _submitRiderTurnover(rider, cashCollected, gcashCollected, stopsCompleted, gallonsDelivered, emptiesReturned, orderIds, since)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.slate200,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isSubmitting ? 'Submitting Turnover...' : 'Submit Cash-Out Request',
              style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerWorkflow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _ownerTabIndex = 0),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _ownerTabIndex == 0 ? AppColors.emerald600 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ownerTabIndex == 0 ? AppColors.emerald600 : AppColors.slate200),
                  ),
                  child: Center(
                    child: Text(
                      'Pending Reviews',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _ownerTabIndex == 0 ? Colors.white : AppColors.slate600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _ownerTabIndex = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _ownerTabIndex == 1 ? AppColors.emerald600 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ownerTabIndex == 1 ? AppColors.emerald600 : AppColors.slate200),
                  ),
                  child: Center(
                    child: Text(
                      'Direct Reconcile',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _ownerTabIndex == 1 ? Colors.white : AppColors.slate600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_ownerTabIndex == 0)
          _buildOwnerPendingReviewsList()
        else
          _buildOwnerDirectReconcileFlow(),
      ],
    );
  }

  Widget _buildOwnerPendingReviewsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getPendingRiderCashOutsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;

        if (list.isEmpty) {
          return _buildCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, color: AppColors.slate400, size: 36),
                    SizedBox(height: 10),
                    Text('No Pending Turnovers', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    SizedBox(height: 2),
                    Text('All riders are operating normally with no unverified cash-outs.', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: list.map((item) {
            final riderName = item['riderName'] as String? ?? 'Rider';
            final reportedCash = (item['reportedCash'] as num?)?.toDouble() ?? 0.0;
            final expectedCash = (item['cashCollected'] as num?)?.toDouble() ?? 0.0;
            final stops = item['stopsCompleted'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFFD97706), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(riderName, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                            Text('$stops stops completed', style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₱${reportedCash.toStringAsFixed(2)}', style: _mono(14, color: AppColors.emerald700, weight: FontWeight.bold)),
                          const Text('Rider Reported', style: TextStyle(fontFamily: _font, fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.slate200),
                  const SizedBox(height: 12),
                  _buildTurnoverCard(expectedCash, (double.tryParse(_cashHandedOverCtrl.text) ?? reportedCash) - expectedCash),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(item),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.coralAlert),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Return', style: TextStyle(fontFamily: _font, color: AppColors.coralAlert, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () => _verifyPendingCashOut(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Verify & Close', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showRejectDialog(Map<String, dynamic> item) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Return Turnover to Rider', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason for returning (e.g., Cash count mismatch, short by ₱100)...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _firestoreService.rejectRiderCashOut(
                  cashOutId: item['id'] as String,
                  rejectionReason: reasonCtrl.text.trim(),
                  rejectedByName: _verifiedByCtrl.text.trim(),
                );
                // FIX: Guarded context with mounted check
                if (!mounted) return;
                AppToast.showSuccess(context, 'Returned turnover to rider.');
              } catch (e) {
                // FIX: Guarded context with mounted check
                if (!mounted) return;
                AppToast.showError(context, 'Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAlert, foregroundColor: Colors.white),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDirectReconcileFlow() {
    if (_isDone) return _buildDoneCard();

    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getRidersStream(),
      builder: (context, ridersSnapshot) {
        final riders = ridersSnapshot.data ?? const <UserModel>[];
        if (riders.isEmpty) {
          return _buildCard(child: const Text('No rider accounts found.'));
        }
        _selectedRiderId ??= riders.first.id;
        final rider = riders.firstWhere((r) => r.id == _selectedRiderId, orElse: () => riders.first);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourierCard(riders, rider),
            const SizedBox(height: 14),
            StreamBuilder<RiderCashOutModel?>(
              stream: _firestoreService.getLatestRiderCashOutStream(rider.id),
              builder: (context, lastCashOutSnapshot) {
                final since = lastCashOutSnapshot.data?.closedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                return StreamBuilder<List<OrderModel>>(
                  stream: _firestoreService.getAllOrdersStream(),
                  builder: (context, ordersSnapshot) {
                    final allOrders = ordersSnapshot.data ?? const <OrderModel>[];

                    // FIX: Uses revenueDate.isAfter(since)
                    final orders = allOrders.where((o) {
                      return o.assignedRiderId == rider.id &&
                          o.status == OrderStatus.delivered &&
                          o.revenueDate.isAfter(since);
                    }).toList();

                    return _buildRiderSection(rider, since, orders);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showCourierSheet(List<UserModel> riders, UserModel rider) {
    String pendingId = rider.id;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(sheetContext).padding.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BottomSheetDragHandle(),
                      const SizedBox(height: 12),
                      BottomSheetHeader(
                        title: 'Select Courier',
                        subtitle: 'Choose delivery rider to reconcile shift collections',
                        onClose: () => Navigator.pop(sheetContext),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: riders.map((r) {
                              final isSelected = r.id == pendingId;
                              final zone = (r.assignedArea != null && r.assignedArea!.isNotEmpty)
                                  ? r.assignedArea!
                                  : 'No specific area assigned';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setSheetState(() => pendingId = r.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.emerald50 : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.emerald600 : AppColors.slate200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.emerald100 : AppColors.slate100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.two_wheeler,
                                            size: 20,
                                            color: isSelected ? AppColors.emerald700 : AppColors.slate600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r.name, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                              Text(zone, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        if (isSelected) const Icon(Icons.check_circle, size: 20, color: AppColors.emerald600),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            if (pendingId != rider.id) {
                              setState(() {
                                _selectedRiderId = pendingId;
                                _isDone = false;
                                _cashHandedOverCtrl.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Confirm Courier Selection', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildCourierCard(List<UserModel> riders, UserModel rider) {
    final hasArea = rider.assignedArea != null && rider.assignedArea!.isNotEmpty;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE COURIER', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary)),
              OutlinedButton(
                onPressed: () => _showCourierSheet(riders, rider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald700,
                  side: const BorderSide(color: AppColors.slate200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Switch', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                child: const Icon(Icons.two_wheeler, color: AppColors.emerald700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.name, style: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    const SizedBox(height: 1),
                    Text(hasArea ? rider.assignedArea! : 'No assigned delivery zone', style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String value, String label) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: AppColors.emerald700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCashCollectedCard(double cashCollected) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EXPECTED CASH COLLECTED (COD)', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('₱${cashCollected.toStringAsFixed(2)}', style: _mono(28, weight: FontWeight.w800, color: AppColors.emerald700, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildVarianceBanner(double variance) {
    final balanced = variance.abs() < 0.01;
    final isOver = variance > 0;
    final color = balanced ? AppColors.emerald700 : AppColors.amber700;
    final bg = balanced ? AppColors.emerald50 : AppColors.amber50;
    final border = balanced ? AppColors.emerald200 : AppColors.amber200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(balanced ? Icons.check_circle : Icons.swap_horiz, size: 18, color: color),
              const SizedBox(width: 8),
              Text(balanced ? 'Balanced' : (isOver ? 'Cash Over' : 'Cash Short'), style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Text('${isOver ? "+" : (balanced ? "" : "-")}₱${variance.abs().toStringAsFixed(2)} Variance', style: _mono(12, color: color, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTurnoverCard(double cashCollected, double? variance) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PHYSICAL TURNOVER', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Text('Counted Cash Received (₱)', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Text('₱ ', style: _mono(17, color: AppColors.emerald700, weight: FontWeight.bold)),
                Expanded(
                  child: TextFormField(
                    controller: _cashHandedOverCtrl,
                    focusNode: _cashFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: _mono(17, weight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                      hintText: cashCollected.toStringAsFixed(2),
                      hintStyle: _mono(17, color: AppColors.slate400),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (variance != null) ...[
            const SizedBox(height: 12),
            _buildVarianceBanner(variance),
          ],
          const SizedBox(height: 14),
          const Text('Verifying Staff Name', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _verifiedByCtrl,
            style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCanvas,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.emerald600, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifyCard(double amount, int emptiesReturned, {bool isRider = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _certified = !_certified),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _certified ? AppColors.emerald50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _certified ? AppColors.emerald200 : AppColors.slate200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _certified ? AppColors.emerald600 : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: _certified ? null : Border.all(color: AppColors.slate400),
              ),
              child: _certified ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: isRider ? 'I certify that I am turning over ' : 'I certify that counted cash of '),
                    TextSpan(text: '₱${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald700)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: '$emptiesReturned empty container(s)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald700)),
                    TextSpan(text: isRider ? ' to station dispatch for verification.' : ' have been physically received and reconciled for this shift.'),
                  ],
                ),
                style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textLight, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneCard() {
    final isBalanced = (_lastDiscrepancy ?? 0).abs() < 0.01;

    return _buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isBalanced ? AppColors.emerald50 : AppColors.rose50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBalanced ? Icons.check_circle : Icons.warning_amber,
              size: 24,
              color: isBalanced ? AppColors.emerald700 : AppColors.rose600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBalanced
                ? 'Cash-Out Recorded: Balanced!'
                : 'Cash-Out Recorded with Discrepancy of ₱${_lastDiscrepancy!.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSection(UserModel rider, DateTime since, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.emerald600, size: 36),
                SizedBox(height: 10),
                Text('All Deliveries Reconciled', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                SizedBox(height: 2),
                Text('No unremitted COD collections for this rider.', style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final summary = summarizeRiderCashOut(orders);
    final stopsCompleted = summary.stopsCompleted;
    final gallonsDelivered = summary.gallonsDelivered;
    final emptiesReturned = summary.emptiesReturned;
    final cashCollected = summary.cashCollected;
    final gcashCollected = summary.gcashCollected;
    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
    final variance = handedOver == null ? null : handedOver - cashCollected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DELIVERIES SINCE LAST CASH-OUT', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.local_shipping_outlined, '$stopsCompleted stops', 'Completed Routes')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(Icons.water_drop_outlined, '$gallonsDelivered units', 'Gallons Delivered')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.autorenew, '$emptiesReturned units', 'Empties Retrieved')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(Icons.qr_code_2, '₱${gcashCollected.toStringAsFixed(2)}', 'GCash Drop-Offs')),
          ],
        ),
        const SizedBox(height: 14),
        _buildCashCollectedCard(cashCollected),
        const SizedBox(height: 14),
        _buildTurnoverCard(cashCollected, variance),
        const SizedBox(height: 14),
        _buildCertifyCard(handedOver ?? cashCollected, emptiesReturned),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_certified && !_isSubmitting) ? () => _closeCashOutDirect(rider, since) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.slate200,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _isSubmitting ? 'Reconciling & Closing...' : 'Verify & Close Cash-Out',
              style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}