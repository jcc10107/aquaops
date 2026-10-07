import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> products;
  final String currentAddress;
  final VoidCallback onBack;
  final VoidCallback onChangeAddress;
  final VoidCallback onOrderSuccess;

  const CustomerCheckoutScreen({
    super.key,
    required this.cart,
    required this.products,
    required this.currentAddress,
    required this.onBack,
    required this.onChangeAddress,
    required this.onOrderSuccess,
  });

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  int _emptyGallonsReturning = 0;
  String _paymentMethod = 'gcash';
  bool _isPlacingOrder = false;
  final TextEditingController _gcashRefController = TextEditingController(text: '1002938475632');
  final TextEditingController _notesController = TextEditingController(text: 'Ring the bell twice, gate is unlocked...');
  bool _hasUploadedReceipt = true;

  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const String _fontFamily = 'Plus Jakarta Sans';
  static const Color _primaryBlue = Color(0xFF0284C7);
  static const Color _surfaceCanvas = Color(0xFFF8FAFC);
  static const Color _surfaceLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _surfaceIce = Color(0xFFF0F9FF);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _secondaryContainer = Color(0xFF6CF8BB);
  static const Color _coralAlert = Color(0xFFF43F5E);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _outline = Color(0xFF707881);

  static const Map<String, String> _areaZoneKeywords = {
    'san isidro': 'si',
    'del remedio': 'dr',
    'san roque': 'sr',
    'san marcos': 'sm',
  };

  // Addresses are now free text from the customer's real Saved Addresses
  // (not a fixed list), so match by keyword instead of exact string.
  String _resolveAreaZone(String address) {
    final lower = address.toLowerCase();
    for (final entry in _areaZoneKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'other';
  }

  @override
  void initState() {
    super.initState();
    _emptyGallonsReturning = _orderedRefillsCount > 0 ? (_orderedRefillsCount - 1) : 0;
  }

  @override
  void dispose() {
    _gcashRefController.dispose();
    _notesController.dispose();
    super.dispose();
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

  double get _checkoutTotal => _cartSubtotal + _missingContainerDeposit;

  Future<void> _placeOrder() async {
    if (widget.cart.isEmpty) return;
    final uid = _uid;
    if (uid == null) return;

    if (_paymentMethod == 'gcash' && _gcashRefController.text.trim().length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 13-digit GCash reference number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
        areaZone: _resolveAreaZone(widget.currentAddress),
        items: items,
        totalAmount: _checkoutTotal,
        paymentMethod: _paymentMethod,
        gcashReference: _paymentMethod == 'gcash' && _gcashRefController.text.trim().isNotEmpty
            ? _gcashRefController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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

  void _simulateFileUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening gallery...')),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _hasUploadedReceipt = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot attached!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    });
  }

  void _copyGcashNumber() {
    Clipboard.setData(const ClipboardData(text: '09171234567'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GCash number copied to clipboard!'),
        backgroundColor: _primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalItemCount = widget.cart.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: _surfaceCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceCanvas.withValues(alpha: 0.8),
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
                      color: _surfaceIce,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onBack,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back, color: _primaryBlue, size: 22),
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
                            color: _onSurface,
                          ),
                        ),
                        Text(
                          'ORDER SUMMARY & REFILL DISPATCH',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _primaryBlue,
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
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                        color: _surfaceIce,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: _primaryBlue, size: 20),
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
                                  color: _primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _secondaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text(
                                  'Home',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _secondary,
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
                              color: _onSurface,
                            ),
                          ),
                          const Text(
                            'San Pablo City, Laguna 4000',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _onSurfaceVariant,
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
                color: _surfaceIce,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: widget.onChangeAddress,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryBlue,
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
              color: _surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.pin_drop, size: 18, color: _outline),
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
                      color: _onSurfaceVariant,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_drink, color: _primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.17,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _surfaceIce,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$totalItemCount Items • $_orderedRefillsCount Gals',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primaryBlue,
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
                            color: _surfaceIce,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSlim ? Icons.water_drop : Icons.local_drink,
                            color: _primaryBlue,
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
                                  color: _onSurface,
                                ),
                              ),
                              Text(
                                'Qty: ${e.value} • ₱${(p['price'] as double).toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: _onSurfaceVariant,
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
                      color: _onSurface,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.swap_horizontal_circle, color: _primaryBlue, size: 20),
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
                              color: _onSurface,
                            ),
                          ),
                          Text(
                            'Total containers ordered: $_orderedRefillsCount',
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Standard 1:1',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceCanvas,
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
                          color: _onSurface,
                        ),
                      ),
                      Text(
                        'Handing over to rider at door',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Material(
                      color: _surfaceLowest,
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
                          child: Icon(Icons.remove, size: 18, color: _primaryBlue),
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
                          color: _onSurface,
                        ),
                      ),
                    ),
                    Material(
                      color: _surfaceLowest,
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
                          child: Icon(Icons.add, size: 18, color: _primaryBlue),
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
                color: _errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: _coralAlert, size: 20),
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
                            color: _coralAlert,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Missing $_missingContainersCount container(s). A refundable deposit of ₱${_missingContainerDeposit.toStringAsFixed(2)} (₱200/gal) has been added.',
                          style: const TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _onSurfaceVariant,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: _primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.17,
                      color: _onSurface,
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
                  color: _primaryBlue,
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
                      backgroundColor: !isGcash ? _primaryBlue : _surfaceCanvas,
                      foregroundColor: !isGcash ? Colors.white : _onSurfaceVariant,
                      elevation: !isGcash ? 4 : 0,
                      shadowColor: const Color(0x400284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: Icon(Icons.payments, size: 18, color: !isGcash ? Colors.white : _onSurfaceVariant),
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
                      backgroundColor: isGcash ? _primaryBlue : _surfaceCanvas,
                      foregroundColor: isGcash ? Colors.white : _onSurfaceVariant,
                      elevation: isGcash ? 4 : 0,
                      shadowColor: const Color(0x400284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: Icon(Icons.check_circle, size: 18, color: isGcash ? Colors.white : _onSurfaceVariant),
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
                color: _surfaceCanvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GCASH ACCOUNT NAME',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: _primaryBlue,
                            ),
                          ),
                          Text(
                            'Station Owner (Aquaflow)',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _onSurface,
                            ),
                          ),
                          Text(
                            '0917 123 4567',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: _surfaceLowest,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _copyGcashNumber,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(Icons.content_copy, size: 18, color: _primaryBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '13-Digit Ref Number',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _surfaceCanvas,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag, color: _primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _gcashRefController,
                            maxLength: 13,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              color: _onSurface,
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
                        const Icon(Icons.check_circle, color: _secondary, size: 20),
                      ],
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
                          color: _onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _hasUploadedReceipt ? 'Uploaded' : 'Not uploaded',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _hasUploadedReceipt ? _secondary : _coralAlert,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _simulateFileUpload,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _surfaceIce,
                        side: BorderSide(color: _primaryBlue.withValues(alpha: 0.4), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.add_photo_alternate, size: 20, color: _primaryBlue),
                      label: const Text(
                        'Upload Screenshot from Gallery',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  if (_hasUploadedReceipt) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _surfaceCanvas,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _surfaceIce,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: _primaryBlue, size: 20),
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
                                    color: _onSurface,
                                  ),
                                ),
                                Text(
                                  'Verified Attachment • 1.4 MB',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _secondary,
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
                              onTap: _simulateFileUpload,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.sync, size: 18, color: _primaryBlue),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() => _hasUploadedReceipt = false),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.close, size: 18, color: _outline),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speaker_notes, color: _primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Notes',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.17,
                  color: _onSurface,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _notesController,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                color: _onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Provide instructions for rider...',
                hintStyle: TextStyle(color: _onSurfaceVariant),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                  color: _onSurfaceVariant,
                ),
              ),
              Text(
                '₱${_cartSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
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
                    const Icon(Icons.shield, size: 16, color: _coralAlert),
                    const SizedBox(width: 6),
                    Text(
                      'Container Deposit (${_missingContainersCount}x)',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _coralAlert,
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
                    color: _coralAlert,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceIce,
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
                        color: _primaryBlue,
                      ),
                    ),
                    Text(
                      'Includes fully refundable bottle deposit',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _onSurfaceVariant,
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
                    color: _primaryBlue,
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
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _primaryBlue.withValues(alpha: 0.45),
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