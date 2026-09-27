import 'dart:async';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/custom_header.dart';
import '../delivery/delivery_queue_screen.dart';
import '../inventory/inventory_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../profile/profile_screen.dart';

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
  Timer? _toastTimer;
  final TextEditingController _tenderCtrl = TextEditingController(text: '35');
  final TextEditingController _gcashRefCtrl = TextEditingController();

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

  void _triggerCheckout() {
    setState(() => _showToast = true);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _showToast = false);
    });
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
          targetScreen = const InventoryScreen();
          break;
        case 2:
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
                                    width: 120,
                                    height: 120,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _AquaColors.surfaceLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      border: Border.all(color: _AquaColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                                    ),
                                    child: const Icon(Icons.qr_code_2, size: 90, color: _AquaColors.primary),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Scan to Pay Station Merchant',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _AquaColors.textMain,
                                    ),
                                  ),
                                  const Text(
                                    'AquaOps \u2022 Merchant ID: AQ-88219',
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
                        onPressed: _triggerCheckout,
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
                            child: const Row(
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
                          const Text(
                            'POS #4092',
                            style: TextStyle(
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

class EmergencyTransferModal extends StatefulWidget {
  final String sourceRider;
  final String sourceZone;
  final int pendingStops;
  final String codAmount;

  const EmergencyTransferModal({
    super.key,
    this.sourceRider = 'Arnel Bautista',
    this.sourceZone = 'Barangay San Antonio • Sector 4',
    this.pendingStops = 2,
    this.codAmount = '₱190.00',
  });

  @override
  State<EmergencyTransferModal> createState() => _EmergencyTransferModalState();
}

class _EmergencyTransferModalState extends State<EmergencyTransferModal> {
  String _reason = 'Bike Breakdown';
  String _scope = 'all';
  bool _notify = true;
  bool _isTransferring = false;
  bool _isDone = false;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm},
    {'label': 'Rider Medical', 'icon': Icons.medical_services},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2},
  ];

  void _confirmTransfer() {
    setState(() => _isTransferring = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isTransferring = false;
        _isDone = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 450,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _AquaColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _AquaColors.primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_AquaColors.coralAlert, _AquaColors.cyanElectric, _AquaColors.secondaryContainer],
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: _AquaColors.coralAlert.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.swap_horiz, color: _AquaColors.coralAlert, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emergency Route Transfer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _AquaColors.textMain, letterSpacing: -0.5)),
                                  SizedBox(height: 4),
                                  Text('Reassign an active delivery queue in real time without resetting progress (e.g. bike breakdown, heavy rainfall, flat tire).', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('TRIGGER REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _AquaColors.textVariant, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _reasons.map((r) {
                            final bool active = _reason == r['label'];
                            return InkWell(
                              onTap: () => setState(() => _reason = r['label']),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active ? _AquaColors.coralAlert : _AquaColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(r['icon'] as IconData, size: 14, color: active ? _AquaColors.surfaceLowest : _AquaColors.textMain),
                                    const SizedBox(width: 4),
                                    Text(r['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? _AquaColors.surfaceLowest : _AquaColors.textMain)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Source Rider (Current Queue)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: _AquaColors.coralAlert.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                              child: const Text('Stalled', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.coralAlert)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _AquaColors.surfaceCanvas, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)]),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: _AquaColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.two_wheeler, size: 20, color: _AquaColors.primary)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.sourceRider, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                        Text(widget.sourceZone, style: const TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 20, color: _AquaColors.outline),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: _AquaColors.surfaceLowest, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_shipping, size: 16, color: _AquaColors.primary),
                                        const SizedBox(width: 6),
                                        Text('${widget.pendingStops} Pending Stops', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.primary)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('5 Gallons • ', style: TextStyle(fontSize: 10, color: _AquaColors.textVariant)),
                                        Text('${widget.codAmount} COD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(height: 24, width: 2, color: _AquaColors.cyanElectric.withValues(alpha: 0.4)),
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(color: _AquaColors.cyanElectric.withValues(alpha: 0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                                  child: const Icon(Icons.south, size: 18, color: _AquaColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Target Rider (New Assignee)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: _AquaColors.secondaryContainer, borderRadius: BorderRadius.circular(100)),
                              child: const Text('Optimal Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.secondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _AquaColors.surfaceIce, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)]),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(width: 32, height: 32, decoration: BoxDecoration(color: _AquaColors.secondaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle), child: const Icon(Icons.directions_bike, size: 20, color: _AquaColors.secondary)),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Jun Soriano', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                        Text('Barangay San Isidro • Available', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.expand_circle_down, size: 20, color: _AquaColors.outline),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: _AquaColors.surfaceLowest, borderRadius: BorderRadius.circular(6)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.near_me, size: 15, color: _AquaColors.secondary),
                                        SizedBox(width: 4),
                                        Text('1.2 km away (4 mins)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.secondary)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.water_drop, size: 14, color: _AquaColors.textVariant),
                                        SizedBox(width: 4),
                                        Text('Load: ', style: TextStyle(fontSize: 10, color: _AquaColors.textVariant)),
                                        Text('4 / 20 jugs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('QUEUE TRANSFER SCOPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _AquaColors.textVariant, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _scope = 'all'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _scope == 'all' ? _AquaColors.surfaceFrost : _AquaColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(_scope == 'all' ? Icons.radio_button_checked : Icons.radio_button_off, color: _scope == 'all' ? _AquaColors.primary : _AquaColors.outlineVariant, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('All Stops (${widget.pendingStops})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                            const Text('Full queue handoff', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
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
                                onTap: () => setState(() => _scope = 'split'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _scope == 'split' ? _AquaColors.surfaceFrost : _AquaColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(_scope == 'split' ? Icons.radio_button_checked : Icons.radio_button_off, color: _scope == 'split' ? _AquaColors.primary : _AquaColors.outlineVariant, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Split Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                            Text('Transfer only stop #2', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
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
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => setState(() => _notify = !_notify),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _AquaColors.surfaceCanvas, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(_notify ? Icons.check_box : Icons.check_box_outline_blank, color: _AquaColors.secondary, size: 18),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Instant Dispatch Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                          SizedBox(width: 4),
                                          Icon(Icons.bolt, size: 14, color: _AquaColors.secondary),
                                        ],
                                      ),
                                      Text('In-app alert & push ping only (no SMS/WhatsApp)', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: TextButton(
                                onPressed: _isTransferring ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: _AquaColors.surfaceContainer,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: _AquaColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 15,
                              child: ElevatedButton(
                                onPressed: _isTransferring || _isDone ? null : _confirmTransfer,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  elevation: 0,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: _isDone ? null : const LinearGradient(colors: [_AquaColors.coralAlert, _AquaColors.amber600]),
                                    color: _isDone ? _AquaColors.secondary : null,
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: _isDone ? [] : [BoxShadow(color: _AquaColors.coralAlert.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    alignment: Alignment.center,
                                    child: _isTransferring
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_isDone ? Icons.check : Icons.swap_horiz, size: 18, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(_isDone ? 'Queue Transferred!' : 'Transfer Queue Now', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, size: 15, color: _AquaColors.tealAccent),
                            SizedBox(width: 6),
                            Text('Live tracking handoff verified by AquaOps Dispatch Telematics', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}