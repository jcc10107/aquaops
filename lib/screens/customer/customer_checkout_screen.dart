import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart'; // Added centralized layout constants
import '../../core/constants/zones.dart';
import '../../core/utils/validators.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> products;
  final String currentAddress;
  final double? currentLat;
  final double? currentLng;
  final VoidCallback onBack;
  final VoidCallback onChangeAddress;
  final VoidCallback onOrderSuccess;

  const CustomerCheckoutScreen({
    super.key,
    required this.cart,
    required this.products,
    required this.currentAddress,
    this.currentLat,
    this.currentLng,
    required this.onBack,
    required this.onChangeAddress,
    required this.onOrderSuccess,
  });

  @override
  State<CustomerCheckoutScreen> createState() =>
      _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  int _emptyGallonsReturning = 0;
  String _paymentMethod = 'gcash';
  bool _isPlacingOrder = false;
  final TextEditingController _gcashRefController =
  TextEditingController(text: '1002938475632');
  final TextEditingController _notesController =
  TextEditingController(text: 'Ring the bell twice, gate is unlocked...');

  bool _hasUploadedReceipt = false;
  Uint8List? _receiptBytes;
  String? _receiptUrl;
  bool _isUploadingReceipt = false;
  String? _gcashRefError;
  String? _receiptError;

  double _deliveryFee = 0;
  ({double baseFee, double ratePerKm})? _deliveryFeeConfig;
  double? _deliveryDistanceKm;
  bool _distanceResolved = false;
  StreamSubscription<({double baseFee, double ratePerKm})>?
  _deliveryFeeConfigSub;

  ({String accountName, String accountNumber, String? qrImageUrl})
  _gcashAccount = (
  accountName: 'Station Owner (Aquaflow)',
  accountNumber: '09171234567',
  qrImageUrl: null,
  );
  StreamSubscription<
      ({String accountName, String accountNumber, String? qrImageUrl})>?
  _gcashAccountSub;

  bool get _calculatingDeliveryFee =>
      _deliveryFeeConfig == null || !_distanceResolved;

  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _emptyGallonsReturning =
    _orderedRefillsCount > 0 ? (_orderedRefillsCount) : 0;

    _deliveryFeeConfigSub =
        _firestoreService.getDeliveryFeeConfigStream().listen((config) {
          _deliveryFeeConfig = config;
          _recomputeDeliveryFee();
        });

    _gcashAccountSub =
        _firestoreService.getGcashAccountStream().listen((account) {
          if (!mounted) return;
          setState(() => _gcashAccount = account);
        });

    _resolveDeliveryDistance();
  }

  @override
  void dispose() {
    _gcashRefController.dispose();
    _notesController.dispose();
    _deliveryFeeConfigSub?.cancel();
    _gcashAccountSub?.cancel();
    super.dispose();
  }

  Future<void> _resolveDeliveryDistance() async {
    try {
      final destination = await _locationService.resolveDestination(
        lat: widget.currentLat,
        lng: widget.currentLng,
        address: widget.currentAddress,
      );
      if (destination != null) {
        _deliveryDistanceKm = await _locationService.getRoadDistanceKm(
          destLat: destination.latitude,
          destLng: destination.longitude,
        );
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _distanceResolved = true);
    _recomputeDeliveryFee();
  }

  void _recomputeDeliveryFee() {
    final config = _deliveryFeeConfig;
    if (config == null || !mounted) return;
    setState(() {
      _deliveryFee =
          config.baseFee + (config.ratePerKm * (_deliveryDistanceKm ?? 0));
    });
  }

  double get _cartSubtotal {
    double total = 0;
    widget.cart.forEach((id, qty) {
      final product = widget.products.firstWhere((p) => p['id'] == id);
      total += (product['price'] as double) * qty;
    });
    return total;
  }

  int get _orderedRefillsCount {
    int count = 0;
    widget.cart.forEach((id, qty) {
      final product = widget.products.firstWhere((p) => p['id'] == id);
      if (product['id'] == 'r_slim' || product['id'] == 'r_round') count += qty;
    });
    return count;
  }

  int get _missingContainersCount {
    int missing = _orderedRefillsCount - _emptyGallonsReturning;
    return missing > 0 ? missing : 0;
  }

  double get _missingContainerDeposit {
    return _missingContainersCount * 200.0;
  }

  double get _checkoutTotal =>
      _cartSubtotal + _missingContainerDeposit + _deliveryFee;

  Widget _buildCheckoutCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _placeOrder() async {
    if (widget.cart.isEmpty) return;
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    if (_calculatingDeliveryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Still calculating your delivery fee — please wait a moment.',
          ),
        ),
      );
      return;
    }

    final sanitizedRef = Validators.sanitizePhone(_gcashRefController.text);
    setState(() {
      _gcashRefError =
      (_paymentMethod == 'gcash' && sanitizedRef.length != 13)
          ? 'Enter the 13-digit GCash reference number.'
          : null;
      _receiptError = (_paymentMethod == 'gcash' && _receiptUrl == null)
          ? 'Please upload your GCash payment screenshot.'
          : null;
    });
    if (_gcashRefError != null || _receiptError != null) return;

    setState(() => _isPlacingOrder = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final profile = await _firestoreService.getUser(uid);
      final items = widget.cart.entries.map((e) {
        final product = widget.products.firstWhere((p) => p['id'] == e.key);
        return OrderItem(
          name: product['name'] as String,
          quantity: e.value,
          unitPrice: product['price'] as double,
        );
      }).toList();

      await _firestoreService.placeOrder(
        customerId: uid,
        customerName: profile?.name ?? 'Customer',
        customerPhone: profile?.phone ?? '',
        deliveryAddress: widget.currentAddress,
        areaZone: zoneGroupOf(widget.currentAddress),
        deliveryLat: widget.currentLat,
        deliveryLng: widget.currentLng,
        items: items,
        totalAmount: _checkoutTotal,
        deliveryFee: _deliveryFee,
        paymentMethod: _paymentMethod,
        gcashReference:
        _paymentMethod == 'gcash' &&
            _gcashRefController.text.trim().isNotEmpty
            ? _gcashRefController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        gcashScreenshotUrl: _paymentMethod == 'gcash' ? _receiptUrl : null,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order Placed Successfully!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      widget.onOrderSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickAndUploadReceipt() async {
    if (_isUploadingReceipt) return;
    setState(() => _isUploadingReceipt = true);
    try {
      final shot = await _picker
          .pickImage(source: ImageSource.gallery)
          .timeout(const Duration(seconds: 20));
      if (shot == null) {
        if (!mounted) return;
        setState(() => _isUploadingReceipt = false);
        return;
      }
      final bytes =
      await shot.readAsBytes().timeout(const Duration(seconds: 20));
      final url = await _cloudinary
          .uploadImage(
        bytes,
        filename: 'receipt_gcash.jpg',
        folder: 'gcash_screenshots',
      )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptUrl = url;
        _hasUploadedReceipt = true;
        _isUploadingReceipt = false;
        _receiptError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshot attached!'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingReceipt = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to attach screenshot: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatGcashNumber(String number) {
    final clean = Validators.sanitizePhone(number);
    if (clean.length != 11) return number;
    return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}';
  }

  void _copyGcashNumber() {
    Clipboard.setData(ClipboardData(text: _gcashAccount.accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GCash number copied to clipboard!'),
        backgroundColor: AppColors.primarySky,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalItemCount = widget.cart.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas.withValues(alpha: 0.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Material(
                          color: AppColors.surfaceIce,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onBack,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.arrow_back,
                                color: AppColors.primarySky,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.17,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              'ORDER SUMMARY & REFILL DISPATCH',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.primarySky,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 40,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeliveryCard(),
                        const SizedBox(height: 16),
                        _buildOrderSummaryCard(totalItemCount),
                        const SizedBox(height: 16),
                        if (_orderedRefillsCount > 0) ...[
                          _buildContainerExchangeCard(),
                          const SizedBox(height: 16),
                        ],
                        _buildPaymentMethodCard(),
                        const SizedBox(height: 16),
                        _buildDeliveryNotesCard(),
                        const SizedBox(height: 16),
                        _buildTotalsCard(),
                        const SizedBox(height: 16),
                        _buildConfirmButton(),
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

  Widget _buildDeliveryCard() {
    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceIce,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primarySky,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DELIVERING TO',
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.primarySky,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text(
                                  'Home',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.17,
                              color: AppColors.textLight,
                            ),
                          ),
                          const Text(
                            'San Pablo City, Laguna 4000',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.surfaceIce,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: widget.onChangeAddress,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primarySky,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.pin_drop, size: 18, color: AppColors.outline),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Near Blue Gate, Landmark: Water Station Alpha',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(int totalItemCount) {
    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_drink, color: AppColors.primarySky, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.17,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceIce,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$totalItemCount Items • $_orderedRefillsCount Gals',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.cart.entries.map((e) {
            final p = widget.products.firstWhere((prod) => prod['id'] == e.key);
            final double itemTotal = (p['price'] as double) * e.value;
            final bool isSlim = (p['id'] as String).contains('slim');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceIce,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSlim ? Icons.water_drop : Icons.local_drink,
                            color: AppColors.primarySky,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                'Qty: ${e.value} • ₱${(p['price'] as double).toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₱${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContainerExchangeCard() {
    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horizontal_circle,
                      color: AppColors.primarySky,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Container Exchange',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.17,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            'Total containers ordered: $_orderedRefillsCount',
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Standard 1:1',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empty Gallons Returning',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        'Handing over to rider at door',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Material(
                      color: AppColors.surfaceLowest,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (_emptyGallonsReturning > 0) {
                            setState(() => _emptyGallonsReturning--);
                          }
                        },
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$_emptyGallonsReturning',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Material(
                      color: AppColors.surfaceLowest,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (_emptyGallonsReturning < _orderedRefillsCount) {
                            setState(() => _emptyGallonsReturning++);
                          }
                        },
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_missingContainersCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: AppColors.coralAlert, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONTAINER DEFICIT NOTICE',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.coralAlert,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Missing $_missingContainersCount container(s). A refundable deposit of ₱${_missingContainerDeposit.toStringAsFixed(2)} (₱200/gal) has been added.',
                          style: const TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
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
    );
  }

  Widget _buildPaymentMethodCard() {
    final bool isGcash = _paymentMethod == 'gcash';

    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primarySky,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.17,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Text(
                'INSTANT VERIFY',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: AppColors.primarySky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _paymentMethod = 'cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      !isGcash ? AppColors.primarySky : AppColors.surfaceCanvas,
                      foregroundColor:
                      !isGcash ? Colors.white : AppColors.textSecondary,
                      elevation: !isGcash ? 4 : 0,
                      shadowColor: const Color(0x400284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    icon: Icon(
                      Icons.payments,
                      size: 18,
                      color: !isGcash ? Colors.white : AppColors.textSecondary,
                    ),
                    label: const Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _paymentMethod = 'gcash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGcash ? AppColors.primarySky : AppColors.surfaceCanvas,
                      foregroundColor:
                      isGcash ? Colors.white : AppColors.textSecondary,
                      elevation: isGcash ? 4 : 0,
                      shadowColor: const Color(0x400284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    icon: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: isGcash ? Colors.white : AppColors.textSecondary,
                    ),
                    label: const Text(
                      'GCash Transfer',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isGcash) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GCASH ACCOUNT NAME',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primarySky,
                            ),
                          ),
                          Text(
                            _gcashAccount.accountName,
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            _formatGcashNumber(_gcashAccount.accountNumber),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: AppColors.surfaceLowest,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _copyGcashNumber,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.content_copy,
                              size: 18,
                              color: AppColors.primarySky,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_gcashAccount.qrImageUrl != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Or scan with the GCash app:',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _gcashAccount.qrImageUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    '13-Digit Ref Number',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _gcashRefError != null
                            ? AppColors.coralAlert
                            : Colors.transparent,
                        width: _gcashRefError != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tag,
                          color: _gcashRefError != null
                              ? AppColors.coralAlert
                              : AppColors.primarySky,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _gcashRefController,
                            maxLength: 13,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_gcashRefError != null) {
                                setState(() => _gcashRefError = null);
                              }
                            },
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              color: AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter reference number',
                              hintStyle: TextStyle(color: Color(0xFFC0C7D3)),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                            ),
                          ),
                        ),
                        Icon(
                          Validators.sanitizePhone(
                            _gcashRefController.text,
                          ).length ==
                              13
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color:
                          Validators.sanitizePhone(
                            _gcashRefController.text,
                          ).length ==
                              13
                              ? AppColors.secondary
                              : AppColors.outline,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (_gcashRefError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        _gcashRefError!,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.coralAlert,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Screenshot Proof',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _hasUploadedReceipt ? 'Uploaded' : 'Not uploaded',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _hasUploadedReceipt
                              ? AppColors.secondary
                              : AppColors.coralAlert,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingReceipt
                          ? null
                          : _pickAndUploadReceipt,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceIce,
                        side: BorderSide(
                          color: _receiptError != null
                              ? AppColors.coralAlert
                              : AppColors.primarySky.withValues(alpha: 0.4),
                          width: _receiptError != null ? 1.5 : 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isUploadingReceipt
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primarySky,
                        ),
                      )
                          : const Icon(
                        Icons.add_photo_alternate,
                        size: 20,
                        color: AppColors.primarySky,
                      ),
                      label: Text(
                        _isUploadingReceipt
                            ? 'Loading...'
                            : 'Upload Screenshot from Gallery',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primarySky,
                        ),
                      ),
                    ),
                  ),
                  if (_receiptError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        _receiptError!,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.coralAlert,
                        ),
                      ),
                    ),
                  if (_hasUploadedReceipt) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceIce,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _receiptBytes != null
                                ? Image.memory(
                              _receiptBytes!,
                              fit: BoxFit.cover,
                            )
                                : const Icon(
                              Icons.image,
                              color: AppColors.primarySky,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'receipt_gcash.jpg',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  'Verified Attachment • 1.4 MB',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isUploadingReceipt
                                  ? null
                                  : _pickAndUploadReceipt,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.sync,
                                  size: 18,
                                  color: AppColors.primarySky,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() {
                                _hasUploadedReceipt = false;
                                _receiptBytes = null;
                                _receiptUrl = null;
                              }),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryNotesCard() {
    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speaker_notes, color: AppColors.primarySky, size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Notes',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.17,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _notesController,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                color: AppColors.textLight,
              ),
              decoration: const InputDecoration(
                hintText: 'Provide instructions for rider...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return _buildCheckoutCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Refills Total ($_orderedRefillsCount Gallons)',
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '₱${_cartSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (_missingContainersCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, size: 16, color: AppColors.coralAlert),
                    const SizedBox(width: 6),
                    Text(
                      'Container Deposit (${_missingContainersCount}x)',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.coralAlert,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${_missingContainerDeposit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coralAlert,
                  ),
                ),
              ],
            ),
          ],
          if (_calculatingDeliveryFee || _deliveryFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Delivery Fee',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_calculatingDeliveryFee)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    '₱${_deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PAY AMOUNT',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primarySky,
                      ),
                    ),
                    Text(
                      'Includes fully refundable bottle deposit',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${_checkoutTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    color: AppColors.primarySky,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySky,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.primarySky.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: _isPlacingOrder
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Confirm Order',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.17,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}