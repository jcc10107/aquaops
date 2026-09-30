import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/custom_header.dart';
import '../delivery/delivery_queue_screen.dart';
import '../inventory/inventory_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/order_model.dart';
import '../../models/shift_model.dart';
import '../../services/firestore_service.dart';

class _AquaColors {
  static const Color primary = Color(0xFF006194);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color background = Color(0xFFFAF8FF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceIce = Color(0xFFF0F9FF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color textMain = Color(0xFF131B2E);
  static const Color textVariant = Color(0xFF3F4850);
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFBFC7D2);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color amber600 = Color(0xFFD97706);
}

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
      _tenderCtrl.text = amount == -1 ? _tot.toStringAsFixed(0) : amount.toStringAsFixed(0);
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
      final tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
      if (tendered < _tot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tendered cash is less than the total.'), backgroundColor: _AquaColors.coralAlert),
        );
        return;
      }
    } else if (_gcashRefCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the GCash reference number.'), backgroundColor: _AquaColors.coralAlert),
      );
      return;
    }

    final items = <OrderItem>[
      if (_round > 0) OrderItem(name: '5-Gal Round Refill', quantity: _round, unitPrice: _roundPrice),
      if (_slim > 0) OrderItem(name: '5-Gal Slim Alkaline Refill', quantity: _slim, unitPrice: _slimPrice),
      if (_newB > 0) OrderItem(name: 'New Bottle + Water (5-Gal)', quantity: _newB, unitPrice: _newBottlePrice),
      if (_bottle500 > 0) OrderItem(name: '500ml Bottled Water', quantity: _bottle500, unitPrice: _bottle500Price, requiresPackaging: false),
    ];

    setState(() => _isCheckingOut = true);
    try {
      final orderNumber = await _firestoreService.recordWalkInSale(
        items: items,
        totalAmount: _tot,
        paymentMethod: _pay,
        gcashReference: _pay == 'gcash' && _gcashRefCtrl.text.trim().isNotEmpty ? _gcashRefCtrl.text.trim() : null,
        // "New Bottle + Water" is a standard 5-Gal (round) fill, so it draws
        // from the same round water stock as a regular round refill.
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
        SnackBar(content: Text('Checkout failed: $e'), backgroundColor: _AquaColors.coralAlert),
      );
    }
  }

  void _onNavTapped(int index) {
    final isOwner = currentUserRoleNotifier.value == 'owner';

    Widget targetScreen;
    if (isOwner) {
      switch (index) {
        case 0:
          targetScreen = const OwnerDashboardScreen();
          break;
        case 1:
          return;
        case 2:
          targetScreen = const DeliveryQueueScreen();
          break;
        case 3:
          targetScreen = const InventoryScreen();
          break;
        case 4:
          targetScreen = const ProfileScreen();
          break;
        default:
          return;
      }
    } else {
      switch (index) {
        case 0:
          return;
        case 1:
          targetScreen = const DeliveryQueueScreen();
          break;
        case 2:
          targetScreen = const InventoryScreen();
          break;
        case 3:
          targetScreen = const ProfileScreen();
          break;
        default:
          return;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildFloatingBottomNav(bool isOwner) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: _AquaColors.surfaceLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: _AquaColors.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: isOwner ? 1 : 0,
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: _AquaColors.primary,
                      unselectedItemColor: _AquaColors.textVariant,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: isOwner
                          ? const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ]
                          : const [
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Station POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AquaColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _AquaColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _AquaColors.surfaceContainerHigh.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }

  Future<String> _currentUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
            const Text('Enter the starting cash float in the till.', style: TextStyle(fontSize: 13, color: _AquaColors.textVariant)),
            const SizedBox(height: 16),
            TextFormField(
              controller: cashCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₱ ',
                filled: true,
                fillColor: _AquaColors.surfaceCanvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final openingCash = double.tryParse(cashCtrl.text) ?? 0;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                final name = await _currentUserName();
                await _firestoreService.openShift(openedByName: name, openingCash: openingCash);
                messenger.showSnackBar(const SnackBar(content: Text('Shift opened.'), backgroundColor: _AquaColors.secondary));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed to open shift: $e'), backgroundColor: _AquaColors.coralAlert));
              }
            },
            child: const Text('Open Shift'),
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
            Text('Opened by ${shift.openedByName} with ₱${shift.openingCash.toStringAsFixed(2)} starting float.', style: const TextStyle(fontSize: 13, color: _AquaColors.textVariant)),
            const SizedBox(height: 16),
            const Text('Count the cash in the till now:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
            const SizedBox(height: 8),
            TextFormField(
              controller: cashCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₱ ',
                filled: true,
                fillColor: _AquaColors.surfaceCanvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final closingCash = double.tryParse(cashCtrl.text);
              if (closingCash == null) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                final name = await _currentUserName();
                final discrepancy = await _firestoreService.closeShift(
                  shiftId: shift.id,
                  openedAt: shift.openedAt,
                  openingCash: shift.openingCash,
                  closingCash: closingCash,
                  closedByName: name,
                );
                final isBalanced = discrepancy.abs() < 0.01;
                messenger.showSnackBar(SnackBar(
                  content: Text(isBalanced ? 'Shift closed. Balanced!' : 'Shift closed. Discrepancy: ₱${discrepancy.toStringAsFixed(2)}'),
                  backgroundColor: isBalanced ? _AquaColors.secondary : _AquaColors.coralAlert,
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed to close shift: $e'), backgroundColor: _AquaColors.coralAlert));
              }
            },
            child: const Text('Close Shift'),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    return StreamBuilder<ShiftModel?>(
      stream: _firestoreService.getOpenShiftStream(),
      builder: (context, snapshot) {
        final shift = snapshot.data;
        return _sectionCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shift != null ? _AquaColors.secondaryContainer.withValues(alpha: 0.4) : _AquaColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(shift != null ? Icons.point_of_sale : Icons.lock_clock, color: shift != null ? _AquaColors.secondary : _AquaColors.textVariant, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift != null ? 'Shift Open' : 'No Active Shift', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                    Text(
                      shift != null
                          ? 'Started ₱${shift.openingCash.toStringAsFixed(2)} by ${shift.openedByName}'
                          : 'Open a shift before counting cash at close-out',
                      style: const TextStyle(fontSize: 11, color: _AquaColors.textVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: shift != null ? () => _showCloseShiftDialog(shift) : _showOpenShiftDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: shift != null ? _AquaColors.coralAlert : _AquaColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: Text(
                  shift != null ? 'Close' : 'Open',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: shift != null ? _AquaColors.coralAlert : _AquaColors.primary),
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
    final isOwner = currentUserRoleNotifier.value == 'owner';

    return Scaffold(
      backgroundColor: _AquaColors.background,
      extendBody: true,
      appBar: const CustomHeader(),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 130, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _AquaColors.primary.withValues(alpha: 0.15),
                                  _AquaColors.cyanElectric.withValues(alpha: 0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _AquaColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.point_of_sale, color: _AquaColors.primary, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'Walk-in Register',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _AquaColors.textMain,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _AquaColors.secondaryContainer,
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: _AquaColors.secondary.withValues(alpha: 0.2)),
                                      ),
                                      child: const Text(
                                        'STATION 01',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _AquaColors.onSecondaryContainer,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tap presets for instant tally & checkout',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _AquaColors.textVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (Navigator.canPop(context)) Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: _AquaColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: _AquaColors.textVariant, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildShiftCard(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.water_drop, color: _AquaColors.primary, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Rapid Refill Presets',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _AquaColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _AquaColors.surfaceFrost,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _AquaColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'QUICK TAP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _AquaColors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                      children: [
                        _buildGridCard(
                          '5-Gal Round',
                          'Refill only',
                          _roundPrice,
                          'Purified',
                          Icons.water_drop_outlined,
                          _AquaColors.surfaceFrost,
                          _AquaColors.primary,
                          _AquaColors.surfaceFrost,
                          _AquaColors.primary,
                          _round,
                              () => setState(() => _round = _round > 0 ? _round - 1 : 0),
                              () => setState(() => _round++),
                        ),
                        _buildGridCard(
                          '5-Gal Slim',
                          'Alkaline Refill',
                          _slimPrice,
                          'pH 9.2',
                          Icons.eco,
                          _AquaColors.secondaryContainer.withValues(alpha: 0.3),
                          _AquaColors.tealAccent,
                          _AquaColors.secondaryContainer,
                          _AquaColors.onSecondaryContainer,
                          _slim,
                              () => setState(() => _slim = _slim > 0 ? _slim - 1 : 0),
                              () => setState(() => _slim++),
                        ),
                        _buildGridCard(
                          'New Bottle + Water',
                          '5-Gal Polycarbonate',
                          _newBottlePrice,
                          'New Jug',
                          Icons.inventory_2,
                          _AquaColors.surfaceContainer,
                          _AquaColors.primary,
                          _AquaColors.surfaceContainerHigh,
                          _AquaColors.textVariant,
                          _newB,
                              () => setState(() => _newB = _newB > 0 ? _newB - 1 : 0),
                              () => setState(() => _newB++),
                        ),
                        _buildGridCard(
                          '500ml Bottled',
                          'PET Grab-and-go',
                          _bottle500Price,
                          'Chilled',
                          Icons.sports_bar,
                          _AquaColors.surfaceFrost,
                          _AquaColors.cyanElectric,
                          _AquaColors.surfaceFrost,
                          _AquaColors.primary,
                          _bottle500,
                              () => setState(() => _bottle500 = _bottle500 > 0 ? _bottle500 - 1 : 0),
                              () => setState(() => _bottle500++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments, color: _AquaColors.primary, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _AquaColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _AquaColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: _AquaColors.outlineVariant.withValues(alpha: 0.2)),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    _payTab('Cash', Icons.payments, 'cash'),
                                    _payTab('GCash QR', Icons.qr_code_2, 'gcash'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_pay == 'cash') ...[
                            const Text(
                              'QUICK TENDER PRESETS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _AquaColors.textVariant,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildTenderBtn('Exact', -1),
                                const SizedBox(width: 6),
                                _buildTenderBtn('\u20b150', 50),
                                const SizedBox(width: 6),
                                _buildTenderBtn('\u20b1100', 100),
                                const SizedBox(width: 6),
                                _buildTenderBtn('\u20b1500', 500),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _AquaColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _AquaColors.outlineVariant.withValues(alpha: 0.3)),
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
                                          color: _AquaColors.textVariant,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            '\u20b1',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: _AquaColors.textMain,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 90,
                                            child: TextField(
                                              controller: _tenderCtrl,
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) => setState(() {}),
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: _AquaColors.textMain,
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
                                          color: _AquaColors.textVariant,
                                        ),
                                      ),
                                      Text(
                                        '\u20b1${_changeDue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _AquaColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _AquaColors.surfaceIce,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _AquaColors.cyanElectric.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _AquaColors.surfaceLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _AquaColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.account_balance_wallet, size: 20, color: _AquaColors.primary),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text('Station Owner (Aquaflow)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                            Text('0917 123 4567', style: TextStyle(fontSize: 13, color: _AquaColors.textVariant, letterSpacing: 1)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Have the customer send GCash to this account, then log the reference number below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _AquaColors.textVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'GCash 13-Digit Reference Number',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _AquaColors.textVariant.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: _AquaColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _AquaColors.outlineVariant.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.tag, color: _AquaColors.primary, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _gcashRefCtrl,
                                            maxLength: 16,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: _AquaColors.textMain,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              counterText: '',
                                              isDense: true,
                                              hintText: 'e.g. 1029 3847 1120',
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
                    const SizedBox(height: 16),
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
                                  color: _AquaColors.textMain,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _AquaColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '$_totalItems Item${_totalItems == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _AquaColors.textVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _orderBreakdown,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _AquaColors.textVariant,
                                  ),
                                ),
                              ),
                              Text(
                                '\u20b1${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _AquaColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: _AquaColors.surfaceContainer),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _AquaColors.textMain,
                                ),
                              ),
                              Text(
                                '\u20b1${_tot.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _AquaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isCheckingOut ? null : _triggerCheckout,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 4,
                          shadowColor: _AquaColors.primary.withValues(alpha: 0.4),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_AquaColors.primary, _AquaColors.cyanElectric],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isCheckingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _AquaColors.textMain,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _AquaColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sale Successfully Recorded',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Database record finalized & inventory updated',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _lastOrderNumber,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _AquaColors.cyanElectric,
                              letterSpacing: 0.4,
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
      ),
      bottomNavigationBar: _buildFloatingBottomNav(isOwner),
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
          color: selected ? _AquaColors.surfaceLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
              : const [],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: selected ? _AquaColors.primary : _AquaColors.textVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? _AquaColors.primary : _AquaColors.textVariant,
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
      String badgeText,
      IconData icon,
      Color iconBg,
      Color iconColor,
      Color badgeBg,
      Color badgeTextCol,
      int qty,
      VoidCallback onDec,
      VoidCallback onInc,
      ) {
    final bool selected = qty > 0;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _AquaColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? _AquaColors.primary.withValues(alpha: 0.4)
              : _AquaColors.surfaceContainerHigh.withValues(alpha: 0.8),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _AquaColors.primary.withValues(alpha: selected ? 0.08 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeTextCol,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _AquaColors.textMain,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: _AquaColors.textVariant),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\u20b1${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _AquaColors.primary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _AquaColors.surfaceIce,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: _AquaColors.primary.withValues(alpha: 0.15)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: onDec,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: _AquaColors.surfaceLowest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 14, color: _AquaColors.primary),
                          ),
                        ),
                        SizedBox(
                          width: 18,
                          child: Text(
                            '$qty',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _AquaColors.textMain,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onInc,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _AquaColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _AquaColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: _AquaColors.surfaceIce,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AquaColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _AquaColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
