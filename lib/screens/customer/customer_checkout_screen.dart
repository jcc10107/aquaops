import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
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
        gcashReference: _paymentMethod == 'gcash' &&
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
      backgroundColor: AppColors.surfaceBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Exactly matches POS screen
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeliveryCard(),
                        const SizedBox(height: 14),
                        _buildOrderSummaryCard(totalItemCount),
                        const SizedBox(height: 14),
                        if (_orderedRefillsCount > 0) ...[
                          _buildContainerExchangeCard(),
                          const SizedBox(height: 14),
                        ],
                        _buildPaymentMethodCard(),
                        const SizedBox(height: 14),
                        _buildDeliveryNotesCard(),
                        const SizedBox(height: 14),
                        _buildTotalsCard(),
                        const SizedBox(height: 18),
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

  Widget _buildHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: AppColors.sky50,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onBack,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.primarySky,
                  size: 20,
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
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Order Summary & Refill Dispatch',
                style: TextStyle(
                  fontFamily: _fontFamily,
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

  Widget _buildDeliveryCard() {
    return _buildCheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.sky50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primarySky,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
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
                            letterSpacing: 0.5,
                            color: AppColors.primarySky,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Home',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald700,
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const Text(
                      'San Pablo City, Laguna',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onChangeAddress,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primarySky,
                  side: const BorderSide(color: AppColors.slate200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
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
                  Icon(Icons.receipt_long, color: AppColors.primarySky, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Order Items',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalItemCount Items',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),
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
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.sky50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSlim ? Icons.water_drop : Icons.local_drink,
                            color: AppColors.primarySky,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                'Qty: ${e.value} • ₱${(p['price'] as double).toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11,
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
                  Text(
                    '₱${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Container Exchange (1:1)',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            'Total refills ordered: $_orderedRefillsCount',
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
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
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        'Handing over to rider at door',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Material(
                      color: Colors.white,
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
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$_emptyGallonsReturning',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white,
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
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.add,
                            size: 16,
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rose50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.rose200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.rose600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Missing $_missingContainersCount container(s). A refundable deposit of ₱${_missingContainerDeposit.toStringAsFixed(2)} (₱200/gal) has been added.',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.rose600,
                      ),
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
          const Text(
            'Payment Method',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _paymentMethod = 'cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      !isGcash ? AppColors.primarySky : AppColors.slate100,
                      foregroundColor:
                      !isGcash ? Colors.white : AppColors.slate600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.payments,
                      size: 16,
                      color: !isGcash ? Colors.white : AppColors.slate600,
                    ),
                    label: const Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _paymentMethod = 'gcash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isGcash ? AppColors.primarySky : AppColors.slate100,
                      foregroundColor:
                      isGcash ? Colors.white : AppColors.slate600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isGcash ? Colors.white : AppColors.slate600,
                    ),
                    label: const Text(
                      'GCash Transfer',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isGcash) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
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
                            'GCASH ACCOUNT',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.primarySky,
                            ),
                          ),
                          Text(
                            _gcashAccount.accountName,
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            _formatGcashNumber(_gcashAccount.accountNumber),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _copyGcashNumber,
                        icon: const Icon(Icons.content_copy, size: 14),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primarySky,
                          side: const BorderSide(color: AppColors.slate200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                  if (_gcashAccount.qrImageUrl != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                    '13-Digit Reference Number',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _gcashRefError != null
                            ? AppColors.coralAlert
                            : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag, color: AppColors.primarySky, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _gcashRefController,
                            maxLength: 13,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) {
                              if (_gcashRefError != null) setState(() => _gcashRefError = null);
                            },
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter reference number',
                              hintStyle: TextStyle(color: AppColors.slate400),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                            ),
                          ),
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _hasUploadedReceipt ? 'Attached ✓' : 'Required',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _hasUploadedReceipt
                              ? AppColors.emerald700
                              : AppColors.coralAlert,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingReceipt ? null : _pickAndUploadReceipt,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _receiptError != null ? AppColors.coralAlert : AppColors.slate200,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isUploadingReceipt
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                      )
                          : const Icon(Icons.add_photo_alternate, size: 16, color: AppColors.primarySky),
                      label: Text(
                        _isUploadingReceipt ? 'Uploading...' : 'Upload Screenshot',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _receiptBytes != null
                                ? Image.memory(_receiptBytes!, width: 36, height: 36, fit: BoxFit.cover)
                                : const Icon(Icons.image, color: AppColors.primarySky, size: 20),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Receipt attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                Text('Verified payment proof', style: TextStyle(fontSize: 10, color: AppColors.emerald700)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.slate400),
                            onPressed: () => setState(() {
                              _hasUploadedReceipt = false;
                              _receiptBytes = null;
                              _receiptUrl = null;
                            }),
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
              Icon(Icons.notes, color: AppColors.primarySky, size: 18),
              SizedBox(width: 8),
              Text(
                'Delivery Notes',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: TextField(
              controller: _notesController,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                color: AppColors.textLight,
              ),
              decoration: const InputDecoration(
                hintText: 'Provide instructions for the delivery rider...',
                hintStyle: TextStyle(color: AppColors.slate400, fontSize: 13),
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
                'Subtotal ($_orderedRefillsCount Gallons)',
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                    const Icon(Icons.shield, size: 14, color: AppColors.rose600),
                    const SizedBox(width: 6),
                    Text(
                      'Bottle Deposit (${_missingContainersCount}x)',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.rose600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${_missingContainerDeposit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.rose600,
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
                      size: 15,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    'Inclusive of taxes & fees',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11,
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
                  fontWeight: FontWeight.w800,
                  color: AppColors.primarySky,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySky,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPlacingOrder
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
            Text(
              'Confirm Order',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}