import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../core/utils/app_toast.dart';
import '../../models/order_model.dart';
import '../../models/shift_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/product_illustration.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<ZoneOption> _zoneOptions = buildZoneOptions();

  // Live catalog — the same owner-managed products shown in the customer
  // app's Store screen (Owner Settings > Manage Products), so walk-in
  // pricing/items never drift from what customers see.
  List<Map<String, dynamic>> _products = [];
  Map<String, String> _productImages = {};
  final Map<String, int> _quantities = {};
  StreamSubscription<List<Map<String, dynamic>>>? _productsSub;
  StreamSubscription<Map<String, String>>? _productImagesSub;

  String _pay = 'cash';
  bool _isCheckingOut = false;
  bool _deliveryMode = false;
  String _deliveryPay = 'cash';
  String _deliveryPaymentTiming = 'rider';
  String? _zoneValue;
  String? _deliveryNameError;
  String? _deliveryPhoneError;
  String? _deliveryAddressError;
  String? _deliveryZoneError;
  // Per-order choice, decided by whoever is taking this walk-in/phone order
  // — not an owner-wide setting, since staff need to switch per customer
  // without leaving this screen.
  bool _zoneSanPabloOnly = true;

  final TextEditingController _tenderCtrl = TextEditingController(text: '35');
  final TextEditingController _gcashRefCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _zoneFreeTextCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  double _deliveryFee = 0;
  ({double baseFee, double ratePerKm})? _deliveryFeeConfig;
  StreamSubscription<({double baseFee, double ratePerKm})>? _deliveryFeeConfigSub;
  bool _resolvingDeliveryFee = false;

  @override
  void initState() {
    super.initState();
    _deliveryFeeConfigSub = _firestoreService.getDeliveryFeeConfigStream().listen((config) {
      _deliveryFeeConfig = config;
      if (mounted) setState(() => _deliveryFee = config.baseFee);
    });
    _productsSub = _firestoreService.getProductsStream().listen((products) {
      if (mounted) setState(() => _products = products);
    });
    _productImagesSub = _firestoreService.getProductImagesStream().listen((images) {
      if (mounted) setState(() => _productImages = images);
    });
  }

  Future<void> _resolveDeliveryFeeForSubmit(String address, String zone) async {
    final config = _deliveryFeeConfig;
    if (config == null) return;
    if (config.ratePerKm == 0) {
      if (mounted) setState(() => _deliveryFee = config.baseFee);
      return;
    }
    setState(() => _resolvingDeliveryFee = true);
    try {
      final destination = await _locationService.resolveDestination(
        address: '$address, $zone, San Pablo City, Laguna',
      );
      double? distanceKm;
      if (destination != null) {
        distanceKm = await _locationService.getRoadDistanceKm(
          destLat: destination.latitude,
          destLng: destination.longitude,
        );
      }
      if (!mounted) return;
      setState(() {
        _deliveryFee = config.baseFee + (config.ratePerKm * (distanceKm ?? 0));
        _resolvingDeliveryFee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryFee = config.baseFee;
        _resolvingDeliveryFee = false;
      });
    }
  }

  int get _totalItems => _quantities.values.fold(0, (a, b) => a + b);

  double get _subtotal {
    double total = 0;
    for (final product in _products) {
      final qty = _quantities[product['id']] ?? 0;
      if (qty > 0) total += (product['price'] as double) * qty;
    }
    return total;
  }

  double get _tot => _subtotal + (_deliveryMode ? _deliveryFee : 0);

  double get _changeDue {
    final double tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
    final double change = tendered - _tot;
    return change > 0 ? change : 0.0;
  }

  String get _orderBreakdown {
    final List<String> parts = [];
    for (final product in _products) {
      final qty = _quantities[product['id']] ?? 0;
      if (qty > 0) parts.add('${product['name']} x$qty');
    }
    return parts.isEmpty ? 'No items selected' : parts.join(', ');
  }

  @override
  void dispose() {
    _deliveryFeeConfigSub?.cancel();
    _productsSub?.cancel();
    _productImagesSub?.cancel();
    _tenderCtrl.dispose();
    _gcashRefCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _zoneFreeTextCtrl.dispose();
    super.dispose();
  }

  void _setTender(double amount) {
    setState(() {
      _tenderCtrl.text = amount == -1 ? _tot.toStringAsFixed(0) : amount.toStringAsFixed(0);
    });
  }

  // 500ml is pre-sealed and never needs a cap/seal from packaging stock —
  // every other catalog item does. productKey is left unset on purpose:
  // FirestoreService._waterInventoryKeyFor already infers the right water
  // SKU from the item name (same as the customer app's own checkout), so
  // this stays correct automatically as the owner renames/adds products.
  List<OrderItem> _orderItems() {
    return [
      for (final product in _products)
        if ((_quantities[product['id']] ?? 0) > 0)
          OrderItem(
            name: product['name'] as String,
            quantity: _quantities[product['id']]!,
            unitPrice: product['price'] as double,
            requiresPackaging: product['id'] != 'bottle500',
          ),
    ];
  }

  // Walk-in sales decrement inventory immediately (recordWalkInSale), unlike
  // delivery orders which go through fulfillDelivery later — so unlike
  // _orderItems above, these aggregates have to be computed up front here.
  int _slimGallonsSelected() {
    int total = 0;
    for (final id in const ['r_slim', 'n_slim']) {
      total += _quantities[id] ?? 0;
    }
    return total;
  }

  int _roundGallonsSelected() {
    int total = 0;
    for (final id in const ['r_round', 'n_round']) {
      total += _quantities[id] ?? 0;
    }
    return total;
  }

  int _packagingUnitsSelected() {
    int total = 0;
    _quantities.forEach((id, qty) {
      if (id != 'bottle500') total += qty;
    });
    return total;
  }

  Future<void> _triggerCheckout() async {
    if (_totalItems == 0) {
      AppToast.showInfo(context, 'Add at least one item before checkout.');
      return;
    }
    if (_pay == 'cash') {
      final double tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
      if (tendered < _tot) {
        AppToast.showError(context, 'Tendered cash is less than the total.');
        return;
      }
    } else if (_gcashRefCtrl.text.trim().length != 13) {
      AppToast.showError(context, 'Enter the 13-digit GCash reference number.');
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final String orderNumber = await _firestoreService.recordWalkInSale(
        items: _orderItems(),
        totalAmount: _tot,
        paymentMethod: _pay,
        gcashReference: _pay == 'gcash' && _gcashRefCtrl.text.trim().isNotEmpty
            ? _gcashRefCtrl.text.trim()
            : null,
        roundGallons: _roundGallonsSelected(),
        slimGallons: _slimGallonsSelected(),
        packagingUnits: _packagingUnitsSelected(),
      );
      if (!mounted) return;
      setState(() {
        _isCheckingOut = false;
        _quantities.clear();
        _tenderCtrl.text = '0';
        _gcashRefCtrl.clear();
      });
      AppToast.showSuccess(
        context,
        'Database record finalized & inventory updated ($orderNumber)',
        title: 'Sale Successfully Recorded',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
      AppToast.showError(context, 'Checkout failed: $e');
    }
  }

  Future<void> _submitDelivery() async {
    if (_totalItems == 0) {
      AppToast.showInfo(context, 'Add at least one item before dispatching.');
      return;
    }
    final String name = _nameCtrl.text.trim();
    final String phone = _phoneCtrl.text.trim();
    final String address = _addressCtrl.text.trim();

    setState(() {
      _deliveryNameError = name.isEmpty ? 'Customer name is required.' : null;
      _deliveryPhoneError = phone.isEmpty ? 'Mobile phone is required.' : null;
      _deliveryAddressError = address.isEmpty ? 'Delivery address is required.' : null;
      _deliveryZoneError = _zoneValue == null ? 'Please select a barangay/zone.' : null;
    });

    if (_deliveryNameError != null ||
        _deliveryPhoneError != null ||
        _deliveryAddressError != null ||
        _deliveryZoneError != null) {
      return;
    }

    await _resolveDeliveryFeeForSubmit(address, zoneLabel(_zoneValue!));
    if (!mounted) return;

    final bool isCounterPaid = _deliveryPaymentTiming == 'counter';
    String? gcashRef;

    if (isCounterPaid) {
      if (_pay == 'cash') {
        final double tendered = double.tryParse(_tenderCtrl.text) ?? 0.0;
        if (tendered < _tot) {
          AppToast.showError(context, 'Tendered cash is less than the total.');
          return;
        }
      } else if (_gcashRefCtrl.text.trim().length != 13) {
        AppToast.showError(context, 'Enter the 13-digit GCash reference number.');
        return;
      } else {
        gcashRef = _gcashRefCtrl.text.trim();
      }

      final shift = await _firestoreService.getOpenShiftStream().first;
      if (shift == null && mounted) {
        AppToast.showInfo(context, 'No shift is open — this sale will still go through.');
      }
    }

    setState(() => _isCheckingOut = true);
    try {
      final String orderNumber = await _firestoreService.placeCounterDeliveryOrder(
        customerName: name,
        customerPhone: phone,
        deliveryAddress: address,
        zone: _zoneValue!,
        items: _orderItems(),
        totalAmount: _tot,
        deliveryFee: _deliveryFee,
        paymentChoice: _deliveryPaymentTiming,
        paymentMethod: isCounterPaid ? _pay : _deliveryPay,
        gcashReference: gcashRef,
      );
      if (!mounted) return;
      setState(() {
        _isCheckingOut = false;
        _quantities.clear();
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _addressCtrl.clear();
        _zoneValue = null;
        _deliveryPaymentTiming = 'rider';
        _gcashRefCtrl.clear();
      });
      AppToast.showSuccess(
        context,
        'Queued for rider assignment in Dispatch ($orderNumber)',
        title: 'Delivery Order Dispatched',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
      AppToast.showError(context, 'Failed to dispatch delivery: $e');
    }
  }

  Future<String> _currentUserName() async {
    final String? uid = AuthService().currentUserId;
    if (uid == null) return 'Staff';
    final profile = await _firestoreService.getUser(uid);
    return profile?.name ?? 'Staff';
  }

  Future<void> _showOpenShiftDialog() async {
    final TextEditingController cashCtrl = TextEditingController(text: '0');
    double? confirmedAmount;
    try {
      confirmedAmount = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surfaceIce,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Open Shift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the starting cash float in the till.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primarySky, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final double? openingCash = double.tryParse(cashCtrl.text.trim());
                if (openingCash == null || openingCash < 0) {
                  AppToast.showError(dialogContext, 'Enter a valid non-negative cash amount.');
                  return;
                }
                Navigator.pop(dialogContext, openingCash);
              },
              child: const Text('Open Shift', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } finally {
      cashCtrl.dispose();
    }

    if (confirmedAmount == null || !mounted) return;

    try {
      final String name = await _currentUserName();
      await _firestoreService.openShift(
        openedByName: name,
        openingCash: confirmedAmount,
      );
      if (mounted) AppToast.showSuccess(context, 'Shift opened.');
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Failed to open shift: $e');
    }
  }

  Future<void> _showCloseShiftDialog(ShiftModel shift) async {
    final TextEditingController cashCtrl = TextEditingController();
    double? confirmedAmount;
    try {
      confirmedAmount = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surfaceIce,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Close Shift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opened by ${shift.openedByName} with ₱${shift.openingCash.toStringAsFixed(2)} starting float.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Count the cash in the till now:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primarySky, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final double? closingCash = double.tryParse(cashCtrl.text.trim());
                if (closingCash == null || closingCash < 0) {
                  AppToast.showError(dialogContext, 'Enter a valid non-negative cash amount.');
                  return;
                }
                Navigator.pop(dialogContext, closingCash);
              },
              child: const Text('Close Shift', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } finally {
      cashCtrl.dispose();
    }

    if (confirmedAmount == null || !mounted) return;

    try {
      final String name = await _currentUserName();
      final double discrepancy = await _firestoreService.closeShift(
        shiftId: shift.id,
        openedAt: shift.openedAt,
        openingCash: shift.openingCash,
        closingCash: confirmedAmount,
        closedByName: name,
      );
      final bool isBalanced = discrepancy.abs() < 0.01;
      if (mounted) {
        if (isBalanced) {
          AppToast.showSuccess(context, 'Shift closed. Balanced!');
        } else {
          AppToast.showError(
            context,
            'Shift closed. Discrepancy: ₱${discrepancy.toStringAsFixed(2)}',
          );
        }
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Failed to close shift: $e');
    }
  }

  Widget _buildFlatCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: child,
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('Walk-in', Icons.storefront, false),
          _modeButton('Delivery', Icons.local_shipping, true),
        ],
      ),
    );
  }

  Widget _modeButton(String label, IconData icon, bool delivery) {
    final bool selected = _deliveryMode == delivery;
    return InkWell(
      onTap: () => setState(() => _deliveryMode = delivery),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primarySky : AppColors.slate500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AppColors.primarySky : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard() {
    return StreamBuilder<ShiftModel?>(
      stream: _firestoreService.getOpenShiftStream(),
      builder: (context, snapshot) {
        final ShiftModel? shift = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: shift != null ? AppColors.sky50 : AppColors.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: shift != null ? AppColors.primarySky.withValues(alpha: 0.3) : AppColors.slate200),
          ),
          child: Row(
            children: [
              Icon(
                shift != null ? Icons.point_of_sale : Icons.lock_clock,
                color: shift != null ? AppColors.primarySky : AppColors.slate500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift != null ? 'Shift Open' : 'No Active Shift',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: shift != null ? AppColors.primarySky : AppColors.slate600,
                      ),
                    ),
                    Text(
                      shift != null
                          ? 'Float: ₱${shift.openingCash.toStringAsFixed(2)} • ${shift.openedByName}'
                          : 'Open a shift before transacting',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: shift != null ? () => _showCloseShiftDialog(shift) : _showOpenShiftDialog,
                style: TextButton.styleFrom(
                  foregroundColor: shift != null ? AppColors.rose600 : AppColors.primarySky,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: shift != null ? AppColors.rose200 : AppColors.primarySky.withValues(alpha: 0.3)),
                  ),
                ),
                child: Text(
                  shift != null ? 'Close Shift' : 'Open Shift',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridCard(String productId, String title, String subtitle, double price, String? imageUrl, int qty, VoidCallback onDec, VoidCallback onInc) {
    final bool selected = qty > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? AppColors.sky50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primarySky : AppColors.slate200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIce,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AppColors.primarySky.withValues(alpha: 0.2) : AppColors.slate200),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => ProductIllustration(productId: productId),
                      )
                    : ProductIllustration(productId: productId),
              ),
              Text(
                '₱${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primarySky : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onDec,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                    child: const Center(child: Icon(Icons.remove, size: 18, color: AppColors.primarySky)),
                  ),
                ),
                Container(width: 1, color: AppColors.slate200),
                Expanded(
                  child: Center(
                    child: Text(
                      '$qty',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.slate200),
                Expanded(
                  child: InkWell(
                    onTap: onInc,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                    child: const Center(child: Icon(Icons.add, size: 18, color: AppColors.primarySky)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization capitalization = TextCapitalization.none,
    String? errorText,
    VoidCallback? onChanged,
  }) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: capitalization,
          onChanged: (_) => onChanged?.call(),
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? AppColors.rose400 : AppColors.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? AppColors.rose400 : AppColors.primarySky, width: 2)),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(errorText, style: const TextStyle(fontSize: 12, color: AppColors.rose600)),
          ),
      ],
    );
  }

  Widget _zoneChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.sky50 : AppColors.slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primarySky : AppColors.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.primarySky : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.primarySky, size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _deliveryField(
                  controller: _nameCtrl,
                  label: 'Customer Name',
                  hint: 'Full Name',
                  capitalization: TextCapitalization.words,
                  errorText: _deliveryNameError,
                  onChanged: () {
                    if (_deliveryNameError != null) setState(() => _deliveryNameError = null);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _deliveryField(
                  controller: _phoneCtrl,
                  label: 'Mobile Phone',
                  hint: '09XX XXX XXXX',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                  errorText: _deliveryPhoneError,
                  onChanged: () {
                    if (_deliveryPhoneError != null) setState(() => _deliveryPhoneError = null);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Area Zone / Barangay (San Pablo City)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _zoneChoiceChip(
                  label: 'San Pablo City',
                  selected: _zoneSanPabloOnly,
                  onTap: () => setState(() => _zoneSanPabloOnly = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _zoneChoiceChip(
                  label: 'Outside San Pablo',
                  selected: !_zoneSanPabloOnly,
                  onTap: () => setState(() {
                    _zoneSanPabloOnly = false;
                    _zoneValue = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final restricted = _zoneSanPabloOnly;
              return restricted
                  ? LayoutBuilder(
                builder: (context, menuConstraints) {
                  return DropdownMenu<String>(
                    initialSelection: _zoneValue,
                    width: menuConstraints.maxWidth,
                    menuHeight: 300,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    hintText: 'Search barangay / zone',
                    textStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(AppColors.surfaceIce),
                      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _deliveryZoneError != null ? AppColors.rose400 : AppColors.slate200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
                    ),
                    dropdownMenuEntries: _zoneOptions.map((z) => DropdownMenuEntry<String>(value: z.value, label: z.label)).toList(),
                    onSelected: (val) {
                      if (val != null) setState(() { _zoneValue = val; _deliveryZoneError = null; });
                    },
                  );
                },
              )
                  : TextField(
                controller: _zoneFreeTextCtrl,
                style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'Enter city/barangay...',
                  filled: true,
                  fillColor: AppColors.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _deliveryZoneError != null ? AppColors.rose400 : AppColors.slate200)),
                ),
                onChanged: (v) => setState(() { _zoneValue = v.trim().isEmpty ? null : v.trim(); _deliveryZoneError = null; }),
              );
            },
          ),
          if (_deliveryZoneError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(_deliveryZoneError!, style: const TextStyle(fontSize: 12, color: AppColors.rose600)),
            ),
          const SizedBox(height: 16),
          _deliveryField(
            controller: _addressCtrl,
            label: 'Complete Address & Landmark',
            hint: 'Street name, house/unit #, nearest landmark',
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            capitalization: TextCapitalization.sentences,
            errorText: _deliveryAddressError,
            onChanged: () {
              if (_deliveryAddressError != null) setState(() => _deliveryAddressError = null);
            },
          ),
          const SizedBox(height: 24),
          const Text('Delivery Payment Collection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 8),
          Row(
            children: [
              _radioChoice(
                label: 'Pay on Delivery',
                selected: _deliveryPaymentTiming == 'rider',
                onTap: () => setState(() => _deliveryPaymentTiming = 'rider'),
              ),
              const SizedBox(width: 12),
              _radioChoice(
                label: 'Paid at Counter',
                selected: _deliveryPaymentTiming == 'counter',
                onTap: () => setState(() => _deliveryPaymentTiming = 'counter'),
              ),
            ],
          ),
          if (_deliveryPaymentTiming == 'rider') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _segmentedOption('Cash', 'cash', _deliveryPay, (val) => setState(() => _deliveryPay = val)),
                const SizedBox(width: 8),
                _segmentedOption('GCash', 'gcash', _deliveryPay, (val) => setState(() => _deliveryPay = val)),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _radioChoice({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.sky50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primarySky : AppColors.slate200),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? AppColors.primarySky : AppColors.slate400,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primarySky : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segmentedOption(String label, String value, String groupValue, ValueChanged<String> onChanged) {
    final bool selected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.slate800 : AppColors.slate100,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.slate600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final bool showTender = !_deliveryMode || _deliveryPaymentTiming == 'counter';

    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primarySky, size: 20),
              SizedBox(width: 8),
              Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(_orderBreakdown, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
              Text('₱${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ],
          ),
          if (_deliveryMode && _deliveryFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                Text('₱${_deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.slate200),
          ),
          if (showTender) ...[
            const Row(
              children: [
                Icon(Icons.payments, color: AppColors.primarySky, size: 20),
                SizedBox(width: 8),
                Text('Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _segmentedOption('Cash', 'cash', _pay, (val) => setState(() => _pay = val)),
                const SizedBox(width: 12),
                _segmentedOption('GCash QR', 'gcash', _pay, (val) => setState(() => _pay = val)),
              ],
            ),
            const SizedBox(height: 16),
            if (_pay == 'cash') ...[
              Row(
                children: [
                  _tenderBtn('Exact', -1), const SizedBox(width: 8),
                  _tenderBtn('₱50', 50), const SizedBox(width: 8),
                  _tenderBtn('₱100', 100), const SizedBox(width: 8),
                  _tenderBtn('₱500', 500),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tendered', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _tenderCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          decoration: InputDecoration(
                            prefixText: '₱ ',
                            prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.slate200)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.emerald200),
                          ),
                          child: Text(
                            '₱${_changeDue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emerald700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              StreamBuilder<({String accountName, String accountNumber, String? qrImageUrl})>(
                stream: _firestoreService.getGcashAccountStream(),
                builder: (context, snapshot) {
                  final accountName = snapshot.data?.accountName ?? 'Station Owner (Aquaflow)';
                  final accountNumber = snapshot.data?.accountNumber ?? '09171234567';
                  final qrImageUrl = snapshot.data?.qrImageUrl;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceIce,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primarySky.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slate200),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: qrImageUrl == null
                              ? const Center(
                            child: Text(
                              'No GCash QR uploaded yet. Use the reference number below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(qrImageUrl, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          qrImageUrl == null ? 'GCash Account Details' : 'Scan with the GCash App to Pay',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$accountName\n$accountNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('13-Digit Reference Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _gcashRefCtrl,
                          maxLength: 13,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 1.5),
                          decoration: InputDecoration(
                            hintText: '0000000000000',
                            hintStyle: const TextStyle(letterSpacing: 1.5, color: AppColors.slate400),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: AppColors.slate200),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              Text(
                '₱${_tot.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primarySky, letterSpacing: -1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_isCheckingOut || _resolvingDeliveryFee)
                  ? null
                  : (_deliveryMode ? _submitDelivery : _triggerCheckout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: (_isCheckingOut || _resolvingDeliveryFee)
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : Text(
                _deliveryMode ? 'DISPATCH ORDER' : 'COMPLETE SALE',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tenderBtn(String label, double amount) {
    return Expanded(
      child: InkWell(
        onTap: () => _setTender(amount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate200),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header without redundant eyebrow text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.sky50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.point_of_sale, color: AppColors.primarySky, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _deliveryMode ? 'Delivery Dispatch' : 'Walk-in Register',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight, height: 1.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildModeToggle(),
                ],
              ),
              const SizedBox(height: 24),
              _buildShiftCard(),
              const SizedBox(height: 24),
              const Text('Select Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = constraints.maxWidth > 500 ? 4 : 2;
                  const double gap = 12;
                  final double itemWidth = (constraints.maxWidth - (gap * (columns - 1))) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final product in _products)
                        SizedBox(
                          width: itemWidth,
                          child: _buildGridCard(
                            product['id'] as String,
                            product['name'] as String,
                            product['type'] as String,
                            product['price'] as double,
                            _productImages[product['id']],
                            _quantities[product['id']] ?? 0,
                            () => setState(() {
                              final id = product['id'] as String;
                              final current = _quantities[id] ?? 0;
                              if (current > 1) {
                                _quantities[id] = current - 1;
                              } else {
                                _quantities.remove(id);
                              }
                            }),
                            () => setState(() {
                              final id = product['id'] as String;
                              _quantities[id] = (_quantities[id] ?? 0) + 1;
                            }),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_deliveryMode) ...[
                _buildDeliverySection(),
                const SizedBox(height: 24),
              ],
              _buildCheckoutSection(),
            ],
          ),
        ),
      ),
    );
  }
}