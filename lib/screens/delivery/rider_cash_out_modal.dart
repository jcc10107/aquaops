import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/rider_cash_out_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class RiderCashOutModal extends StatefulWidget {
  const RiderCashOutModal({super.key});

  @override
  State<RiderCashOutModal> createState() => _RiderCashOutModalState();
}

class _RiderCashOutModalState extends State<RiderCashOutModal> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _cashHandedOverCtrl = TextEditingController();
  final TextEditingController _verifiedByCtrl = TextEditingController();

  String? _selectedRiderId;
  bool _certified = true;
  bool _isSubmitting = false;
  bool _isDone = false;
  double? _lastDiscrepancy;

  @override
  void initState() {
    super.initState();
    _cashHandedOverCtrl.addListener(() => setState(() {}));
    _prefillVerifierName();
  }

  Future<void> _prefillVerifierName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted && profile != null) {
      _verifiedByCtrl.text = profile.name;
    }
  }

  @override
  void dispose() {
    _cashHandedOverCtrl.dispose();
    _verifiedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _closeCashOut(UserModel rider, DateTime since) async {
    if (!_certified) return;
    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
    if (handedOver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the counted cash amount.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_verifiedByCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the verifying staff name.'), backgroundColor: AppColors.error),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close cash-out: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textMain = isDark ? Colors.white : AppColors.textLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 390,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 16)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.vividGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.currency_exchange, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CASH RECONCILIATION', style: TextStyle(fontSize: 10, color: AppColors.surfaceFrost, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Rider Cash-Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: StreamBuilder<List<UserModel>>(
                      stream: _firestoreService.getRidersStream(),
                      builder: (context, ridersSnapshot) {
                        final riders = ridersSnapshot.data ?? const <UserModel>[];
                        if (riders.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No rider accounts found.', style: TextStyle(color: AppColors.textSecondary)),
                          );
                        }
                        _selectedRiderId ??= riders.first.id;
                        final rider = riders.firstWhere((r) => r.id == _selectedRiderId, orElse: () => riders.first);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  const CircleAvatar(radius: 22, backgroundColor: AppColors.surfaceFrost, child: Icon(Icons.person, color: AppColors.primaryLight)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: rider.id,
                                        items: riders.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain)))).toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedRiderId = v;
                                            _isDone = false;
                                            _cashHandedOverCtrl.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: AppColors.cyanElectric),
                                  const SizedBox(width: 4),
                                  Text(rider.assignedArea == null || rider.assignedArea!.isEmpty ? 'No area assigned' : 'Zone: ${rider.assignedArea}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<RiderCashOutModel?>(
                              stream: _firestoreService.getLatestRiderCashOutStream(rider.id),
                              builder: (context, lastCashOutSnapshot) {
                                final since = lastCashOutSnapshot.data?.closedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                                return StreamBuilder<List<OrderModel>>(
                                  stream: _firestoreService.getAllOrdersStream(),
                                  builder: (context, ordersSnapshot) {
                                    final orders = (ordersSnapshot.data ?? const <OrderModel>[])
                                        .where((o) => o.assignedRiderId == rider.id && o.status == OrderStatus.delivered && o.revenueDate.isAfter(since))
                                        .toList();

                                    final stopsCompleted = orders.length;
                                    final gallonsDelivered = orders.fold<int>(0, (s, o) => s + o.gallonsDelivered);
                                    final emptiesReturned = orders.fold<int>(0, (s, o) => s + o.emptyGallonsReturned);
                                    final cashCollected = orders.where((o) => o.paymentMethod == PaymentMethod.cash).fold<double>(0, (s, o) => s + o.totalAmount);
                                    final gcashCollected = orders.where((o) => o.paymentMethod == PaymentMethod.gcash).fold<double>(0, (s, o) => s + o.totalAmount);
                                    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
                                    final variance = handedOver == null ? null : handedOver - cashCollected;

                                    if (_isDone) {
                                      final isBalanced = (_lastDiscrepancy ?? 0).abs() < 0.01;
                                      return Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(color: isBalanced ? AppColors.secondaryContainer.withValues(alpha: 0.4) : AppColors.errorContainer, borderRadius: BorderRadius.circular(16)),
                                        child: Column(
                                          children: [
                                            Icon(isBalanced ? Icons.check_circle : Icons.warning_amber, size: 40, color: isBalanced ? AppColors.secondaryLight : AppColors.error),
                                            const SizedBox(height: 12),
                                            Text(isBalanced ? 'Cash-out recorded — balanced!' : 'Cash-out recorded with a discrepancy of ₱${_lastDiscrepancy!.toStringAsFixed(2)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain)),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('DELIVERIES SINCE LAST CASH-OUT', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _statTile(Icons.local_shipping, AppColors.primaryLight, 'Completed Routes', '$stopsCompleted', 'stops', textMain)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _statTile(Icons.water_drop, AppColors.cyanElectric, 'Gallons Delivered', '$gallonsDelivered', 'units', textMain)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _statTile(Icons.autorenew, AppColors.accentTeal, 'Empties Retrieved', '$emptiesReturned', 'units', textMain)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _statTile(Icons.qr_code_2, AppColors.tertiary, 'GCash Drop-Offs', '₱${gcashCollected.toStringAsFixed(0)}', '', textMain)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(16)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('CASH COLLECTED (COD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1)),
                                              const SizedBox(height: 4),
                                              Text('₱${cashCollected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.secondary, fontFamily: 'monospace')),
                                              const Text('Net physical currency collected directly from residential and store drops.', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.point_of_sale, size: 20, color: AppColors.primaryLight),
                                                  SizedBox(width: 8),
                                                  Text('Physical Turnover', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              const Text('Physical Cash Handed to Station (₱)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _cashHandedOverCtrl,
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.textLight),
                                                decoration: InputDecoration(
                                                  prefixText: '₱ ',
                                                  prefixStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                                  hintText: cashCollected.toStringAsFixed(2),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (variance != null)
                                                Text(
                                                  variance.abs() < 0.01 ? 'Exact match: Balanced' : '${variance > 0 ? 'Over' : 'Short'} by ₱${variance.abs().toStringAsFixed(2)}',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: variance.abs() < 0.01 ? AppColors.secondaryLight : AppColors.error),
                                                ),
                                              const SizedBox(height: 12),
                                              const Text('Verifying Station Staff Name', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _verifiedByCtrl,
                                                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(Icons.badge, color: AppColors.primaryLight, size: 20),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        InkWell(
                                          onTap: () => setState(() => _certified = !_certified),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(_certified ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.primaryLight, size: 20),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: TextStyle(fontSize: 12, color: textMain, height: 1.4),
                                                      children: [
                                                        const TextSpan(text: 'I certify that physical cash of '),
                                                        TextSpan(text: '₱${(handedOver ?? cashCollected).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                                        const TextSpan(text: ' and '),
                                                        TextSpan(text: '$emptiesReturned empty containers', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                                        const TextSpan(text: ' have been physically handed over.'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing isn\'t available in this demo.'))),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(double.infinity, 52),
                                            side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                          ),
                                          icon: const Icon(Icons.print, size: 18, color: AppColors.primaryLight),
                                          label: const Text('Print Shift Summary (Thermal BT)', style: TextStyle(fontSize: 13, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 12),
                                        Opacity(
                                          opacity: _certified ? 1.0 : 0.5,
                                          child: ElevatedButton.icon(
                                            onPressed: (_certified && !_isSubmitting) ? () => _closeCashOut(rider, since) : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.secondaryLight,
                                              minimumSize: const Size(double.infinity, 56),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                            ),
                                            icon: _isSubmitting
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                : const Icon(Icons.verified_user, size: 22, color: Colors.white),
                                            label: Text(
                                              _isSubmitting ? 'Reconciling & Closing...' : 'Verify & Close Cash-Out',
                                              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.surfaceContainerLow,
                                            foregroundColor: AppColors.textSecondary,
                                            minimumSize: const Size(double.infinity, 48),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                            elevation: 0,
                                          ),
                                          child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
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

  Widget _statTile(IconData icon, Color color, String label, String value, String unit, Color textMain) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$value ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
              TextSpan(text: unit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }
}
