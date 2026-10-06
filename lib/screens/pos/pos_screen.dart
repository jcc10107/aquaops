import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/shift_model.dart';
import '../../services/firestore_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  static const double _roundPrice = 35.0;
  static const double _slimPrice = 50.0;
  static const double _newBottlePrice = 250.0;
  static const double _bottle500Price = 15.0;

  int _round = 1;
  int _slim = 0;
  int _newB = 0;
  int _bottle500 = 0;
  String _pay = 'cash';
  bool _showToast = false;
  bool _isCheckingOut = false;
  String _lastOrderNumber = '';
  Timer? _toastTimer;
  final TextEditingController _tenderCtrl = TextEditingController(text: '35');
  final TextEditingController _gcashRefCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  int get _totalItems => _round + _slim + _newB + _bottle500;

  double get _subtotal =>
      (_round * _roundPrice) +
          (_slim * _slimPrice) +
          (_newB * _newBottlePrice) +
          (_bottle500 * _bottle500Price);

  double get _tot => _subtotal;

  double get _changeDue {
    final double tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
    final double change = tendered - _tot;
    return change > 0 ? change : 0.0;
  }

  String get _orderBreakdown {
    final List<String> parts = [];
    if (_round > 0) parts.add('Round Refill x$_round');
    if (_slim > 0) parts.add('Slim Refill x$_slim');
    if (_newB > 0) parts.add('New Jug x$_newB');
    if (_bottle500 > 0) parts.add('500ml x$_bottle500');
    return parts.isEmpty ? 'No items selected' : parts.join(', ');
  }

  @override
  void dispose() {
    _tenderCtrl.dispose();
    _gcashRefCtrl.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _setTender(double amount) {
    setState(() {
      _tenderCtrl.text =
      amount == -1 ? _tot.toStringAsFixed(0) : amount.toStringAsFixed(0);
    });
  }

  Future<void> _triggerCheckout() async {
    if (_totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item before checkout.')),
      );
      return;
    }
    if (_pay == 'cash') {
      final double tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
      if (tendered < _tot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tendered cash is less than the total.'),
            backgroundColor: AppColors.coralAlert,
          ),
        );
        return;
      }
    } else if (_gcashRefCtrl.text.trim().length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 13-digit GCash reference number.'),
          backgroundColor: AppColors.coralAlert,
        ),
      );
      return;
    }

    final List<OrderItem> items = [
      if (_round > 0)
        OrderItem(
          name: '5-Gal Round Refill',
          quantity: _round,
          unitPrice: _roundPrice,
        ),
      if (_slim > 0)
        OrderItem(
          name: '5-Gal Slim Alkaline Refill',
          quantity: _slim,
          unitPrice: _slimPrice,
        ),
      if (_newB > 0)
        OrderItem(
          name: 'New Bottle + Water (5-Gal)',
          quantity: _newB,
          unitPrice: _newBottlePrice,
        ),
      if (_bottle500 > 0)
        OrderItem(
          name: '500ml Bottled Water',
          quantity: _bottle500,
          unitPrice: _bottle500Price,
          requiresPackaging: false,
        ),
    ];

    setState(() => _isCheckingOut = true);
    try {
      final String orderNumber = await _firestoreService.recordWalkInSale(
        items: items,
        totalAmount: _tot,
        paymentMethod: _pay,
        gcashReference: _pay == 'gcash' && _gcashRefCtrl.text.trim().isNotEmpty
            ? _gcashRefCtrl.text.trim()
            : null,
        roundGallons: _round + _newB,
        slimGallons: _slim,
        packagingUnits: _round + _slim + _newB,
      );
      if (!mounted) return;
      setState(() {
        _isCheckingOut = false;
        _lastOrderNumber = orderNumber;
        _round = 0;
        _slim = 0;
        _newB = 0;
        _bottle500 = 0;
        _tenderCtrl.text = '0';
        _gcashRefCtrl.clear();
        _showToast = true;
      });
      _toastTimer?.cancel();
      _toastTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showToast = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: AppColors.coralAlert,
        ),
      );
    }
  }

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }

  Future<String> _currentUserName() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Staff';
    final profile = await _firestoreService.getUser(uid);
    return profile?.name ?? 'Staff';
  }

  void _showOpenShiftDialog() {
    final TextEditingController cashCtrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Open Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the starting cash float in the till.',
              style: TextStyle(fontSize: 13, color: AppColors.textVariant),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cashCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₱ ',
                filled: true,
                fillColor: AppColors.surfaceCanvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cashCtrl.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
            ),
            onPressed: () async {
              final double openingCash = double.tryParse(cashCtrl.text) ?? 0;
              final ScaffoldMessengerState messenger =
              ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                final String name = await _currentUserName();
                await _firestoreService.openShift(
                  openedByName: name,
                  openingCash: openingCash,
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Shift opened.'),
                    backgroundColor: Color(0xFF0284C7),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to open shift: $e'),
                    backgroundColor: AppColors.coralAlert,
                  ),
                );
              }
            },
            child: const Text(
              'Open Shift',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(ShiftModel shift) {
    final TextEditingController cashCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opened by ${shift.openedByName} with ₱${shift.openingCash.toStringAsFixed(2)} starting float.',
              style: const TextStyle(fontSize: 13, color: AppColors.textVariant),
            ),
            const SizedBox(height: 16),
            const Text(
              'Count the cash in the till now:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: cashCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₱ ',
                filled: true,
                fillColor: AppColors.surfaceCanvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cashCtrl.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
            ),
            onPressed: () async {
              final double? closingCash = double.tryParse(cashCtrl.text);
              if (closingCash == null) return;
              final ScaffoldMessengerState messenger =
              ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                final String name = await _currentUserName();
                final double discrepancy = await _firestoreService.closeShift(
                  shiftId: shift.id,
                  openedAt: shift.openedAt,
                  openingCash: shift.openingCash,
                  closingCash: closingCash,
                  closedByName: name,
                );
                final bool isBalanced = discrepancy.abs() < 0.01;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isBalanced
                          ? 'Shift closed. Balanced!'
                          : 'Shift closed. Discrepancy: ₱${discrepancy.toStringAsFixed(2)}',
                    ),
                    backgroundColor:
                    isBalanced ? const Color(0xFF0284C7) : AppColors.coralAlert,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to close shift: $e'),
                    backgroundColor: AppColors.coralAlert,
                  ),
                );
              }
            },
            child: const Text(
              'Close Shift',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    return StreamBuilder<ShiftModel?>(
      stream: _firestoreService.getOpenShiftStream(),
      builder: (context, snapshot) {
        final ShiftModel? shift = snapshot.data;
        return _sectionCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: shift != null
                      ? const Color(0xFFE0F2FE)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  shift != null ? Icons.point_of_sale : Icons.lock_clock,
                  color: shift != null
                      ? const Color(0xFF0284C7)
                      : AppColors.textVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift != null ? 'Shift Open' : 'No Active Shift',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                        letterSpacing: -0.17,
                      ),
                    ),
                    Text(
                      shift != null
                          ? 'Started ₱${shift.openingCash.toStringAsFixed(2)} by ${shift.openedByName}'
                          : 'Open a shift before counting cash at close-out',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: shift != null
                    ? () => _showCloseShiftDialog(shift)
                    : _showOpenShiftDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: shift != null
                        ? AppColors.coralAlert
                        : const Color(0xFF0284C7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  shift != null ? 'Close' : 'Open',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: shift != null
                        ? AppColors.coralAlert
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 130,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.surfaceContainerHigh
                            .withValues(alpha: 0.6),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F0284C7),
                          blurRadius: 30,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0284C7).withValues(alpha: 0.15),
                                AppColors.cyanHighlight.withValues(alpha: 0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.point_of_sale,
                            color: Color(0xFF0284C7),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Walk-in Register',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            letterSpacing: -0.17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShiftCard(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Color(0xFF0284C7),
                              size: 22,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Rapid Refill Presets',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                                letterSpacing: -0.17,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceFrost,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Text(
                            'QUICK TAP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _buildGridCard(
                              '5-Gal Round',
                              'Refill only',
                              _roundPrice,
                              Icons.local_drink,
                              _round,
                                  () => setState(
                                      () => _round = _round > 0 ? _round - 1 : 0),
                                  () => setState(() => _round++),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildGridCard(
                              '5-Gal Slim',
                              'Alkaline Refill',
                              _slimPrice,
                              Icons.eco,
                              _slim,
                                  () => setState(
                                      () => _slim = _slim > 0 ? _slim - 1 : 0),
                                  () => setState(() => _slim++),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildGridCard(
                              'New Bottle + Water',
                              '5-Gal Polycarbonate',
                              _newBottlePrice,
                              Icons.inventory_2,
                              _newB,
                                  () => setState(
                                      () => _newB = _newB > 0 ? _newB - 1 : 0),
                                  () => setState(() => _newB++),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildGridCard(
                              '500ml Bottled',
                              'PET Grab-and-go',
                              _bottle500Price,
                              Icons.sports_bar,
                              _bottle500,
                                  () => setState(() => _bottle500 =
                              _bottle500 > 0 ? _bottle500 - 1 : 0),
                                  () => setState(() => _bottle500++),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  color: Color(0xFF0284C7),
                                  size: 22,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                    letterSpacing: -0.17,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _payTab('Cash', Icons.payments, 'cash'),
                                  _payTab('GCash QR', Icons.qr_code_2, 'gcash'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_pay == 'cash') ...[
                          Row(
                            children: [
                              _buildTenderBtn('Exact', -1),
                              const SizedBox(width: 8),
                              _buildTenderBtn('₱50', 50),
                              const SizedBox(width: 8),
                              _buildTenderBtn('₱100', 100),
                              const SizedBox(width: 8),
                              _buildTenderBtn('₱500', 500),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tendered Cash',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textVariant,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          '₱',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: TextField(
                                            controller: _tenderCtrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            onChanged: (val) =>
                                                setState(() {}),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textMain,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Customer Change',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textVariant,
                                      ),
                                    ),
                                    Text(
                                      '₱${_changeDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                        letterSpacing: -0.44,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceIce,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cyanElectric
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 144,
                                  height: 144,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLowest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.surfaceContainerHigh
                                          .withValues(alpha: 0.6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2,
                                    size: 100,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Scan to Pay Station Merchant',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const Text(
                                  'AquaOps • Merchant ID: AQ-88219',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'GCash 13-Digit Reference Number',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textVariant
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tag,
                                        color: Color(0xFF0284C7),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _gcashRefCtrl,
                                          maxLength: 13,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textMain,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            counterText: '',
                                            isDense: true,
                                            hintText: '1029384711200',
                                            hintStyle: TextStyle(
                                              color: AppColors.outlineVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$_totalItems Item${_totalItems == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textVariant,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _orderBreakdown,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textVariant,
                                ),
                              ),
                            ),
                            Text(
                              '₱${_subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 1,
                            color: AppColors.surfaceContainer,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                                letterSpacing: -0.17,
                              ),
                            ),
                            Text(
                              '₱${_tot.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                                letterSpacing: -0.9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCheckingOut ? null : _triggerCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 10,
                        shadowColor:
                        const Color(0xFF0284C7).withValues(alpha: 0.4),
                      ),
                      child: _isCheckingOut
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'COMPLETE SALE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: 16,
                  right: 16,
                  bottom: _showToast ? 100 : -150,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textMain,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sale Successfully Recorded',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Database record finalized & inventory updated',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              if (_lastOrderNumber.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _lastOrderNumber,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.cyanElectric,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _payTab(String label, IconData icon, String value) {
    final bool selected = _pay == value;
    return InkWell(
      onTap: () => setState(() => _pay = value),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
            ),
          ]
              : const [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? const Color(0xFF0284C7) : AppColors.textVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF0284C7) : AppColors.textVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(
      String title,
      String subtitle,
      double price,
      IconData icon,
      int qty,
      VoidCallback onDec,
      VoidCallback onInc,
      ) {
    final bool selected = qty > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? const Color(0xFF0284C7).withValues(alpha: 0.4)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: Color(0x0F0284C7),
              blurRadius: 20,
              offset: Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surfaceFrost, AppColors.surfaceIce],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0284C7), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
              height: 1.2,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                  letterSpacing: -0.16,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceIce,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: onDec,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLowest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onInc,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenderBtn(String label, double value) {
    return Expanded(
      child: InkWell(
        onTap: () => _setTender(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceIce,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0284C7),
            ),
          ),
        ),
      ),
    );
  }
}