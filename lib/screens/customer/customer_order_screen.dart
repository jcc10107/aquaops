import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_input_field.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';

class CustomerOrderScreen extends StatefulWidget {
  const CustomerOrderScreen({super.key});
  @override
  State<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _isCheckoutView = false;
  final Map<String, int> _cart = {};
  int _emptyGallonsReturning = 0;
  String _paymentMethod = 'cash';
  bool _isPlacingOrder = false;
  final TextEditingController _gcashRefController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _currentAddress = 'Barangay San Isidro';

  bool _hasUploadedReceipt = false;
  int _ordersTab = 0;

  String _orderHistoryFilter = 'All Orders';
  final TextEditingController _historySearchCtrl = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  late final Future<UserModel?> _userFuture;

  static const Map<String, String> _areaZoneByAddress = {
    'Barangay San Isidro': 'si',
    'Barangay Del Remedio': 'dr',
    'Barangay San Roque': 'sr',
    'Barangay San Marcos': 'sm',
  };

  static const List<String> _availableAddresses = [
    'Barangay San Isidro',
    'Barangay Del Remedio',
    'Barangay San Roque',
    'Barangay San Marcos',
  ];

  static const String _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBmYpl5hY9wyEIoETjaeklpojtzwdgaasl38ctMgV7pwf1KTLme42r2ezcO6h-LI2_r86iwoCfwCq31uJ1z4kzykLjJxnOogo_ON-CGuFyXHMSVAuRbm8XemhvItBpM1fQFoSeJzHh-XSwXFXRXRap6VpR7dleRTq8NGfo53rsn7hYrfzbPAuMxOgsuYaujq88tetXrnWNdAylRO42apbcdGEOu4nuyb4ADH2AuafX99e6T_cN_P9jm';

  final List<Map<String, dynamic>> _products = const [
    {'id': 'r_slim', 'name': 'Slim Refill', 'price': 35.0, 'type': 'Refill exchange • Cap sanitized', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4u3PhCIJ2d1trH8uCDX58oPbgVqxpKZH7Hx9Kkdvo30b1UWe1UyJY9Rvzx8I_Pf4nkjNtk8RcX84hVCRBKfdC-RGl0chPnCyVOMUoY2ubUHs14Bhpub55_9UZ-y8iGLruyYvm7xFG3AXiWAQP2Y0j22UmJrpnZxxAV6kxvlZxkMQBY2xqZA4_ipMvwBclC3oZLNQGL8kt_e4jbXuSGwRQeVJr2yubm-O-m3juCf9i5EGYwsnm8DOn'},
    {'id': 'r_round', 'name': 'Round Refill', 'price': 35.0, 'type': 'Refill exchange • Dispenser fit', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCxjOo4hQIzbzqeZGiuDEuVYWCScgi8T7rbC_n5NevhXTPPeSNwKg7ouy25ALS0htW-pV6U9xbYF3oK1dC_uW-4ixVxe4ICetk-1b0x7Wf0c6KmFM2_To10U-Wr_JVhKMbbbYMtNZhwevs6h2-aR2GmkSU9nSbWD3tNVOAEE9wx_CYi_Gad75mc6DXYNWHLWNevRibxdEV5mjpygEqcrX7HMWETBdtQ0PCnH8C0r_k7VGZE2oBHu454'},
    {'id': 'n_slim', 'name': 'New Slim Gallon', 'price': 235.0, 'type': 'New Container + Pure Water', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAa4Ad3g1lOJDwu8NTxhwvLi3BqR6mRoNZOe_eYf6_7aMoWl7anW2H1CaqTaSp4jLIsgJ7EZRCvRe_mj3wPo0-C-xlE6qjpJ25PVnXKQRmtG1WNcSlH9HE06TRi8bBIbo4jGRIZ26-leqZa0y1LUe7T6PKu1LpCStYV_ATBf4lF7z0tRPsGi1hBadasTOhEopubO1QQcEBNiUQILmlTtuhBbeyAs6kdyoZxdWdR-vb2KYUo1hLDxJMJ'},
    {'id': 'n_round', 'name': 'New Round Gallon', 'price': 255.0, 'type': 'New Container + Pure Water', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDR3dJWp8_seEQIjiiX5wGlkNwmmjshzElrWqv6hOv6-zr7KR1hKMDsUz9kPCqtQ55zG5QjHN9JF8zHOxsidKwJEzstXf6jJWXE83nUPWBibNUWaqBjcTgAA_Vaw382B1QesGyowfzlNAJiPar6oFVeDToaic_KCKpL9id99YkiqH7FTQCmkq4Fv5UxEU-aZj9LiSLdmEvpF4jvmJIDF84v8PaA8OSmqWIoQzQxO2FdJ60TEyF3hLY_'},
  ];

  double get _cartSubtotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'] == id);
      total += (product['price'] as double) * qty;
    });
    return total;
  }

  int get _orderedRefillsCount {
    int count = 0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'] == id);
      if (product['id'] == 'r_slim' || product['id'] == 'r_round') count += qty;
    });
    return count;
  }

  double get _missingContainerDeposit {
    int missing = _orderedRefillsCount - _emptyGallonsReturning;
    return missing > 0 ? (missing * 200.0) : 0.0;
  }

  double get _checkoutTotal => _cartSubtotal + _missingContainerDeposit;

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    _userFuture = uid == null ? Future<UserModel?>.value(null) : _firestoreService.getUser(uid);
  }

  @override
  void dispose() {
    _gcashRefController.dispose();
    _notesController.dispose();
    _historySearchCtrl.dispose();
    super.dispose();
  }

  void _addToCart(String id) {
    setState(() => _cart[id] = (_cart[id] ?? 0) + 1);
  }

  void _removeFromCart(String id) {
    setState(() {
      if (_cart.containsKey(id) && _cart[id]! > 1) {
        _cart[id] = _cart[id]! - 1;
      } else {
        _cart.remove(id);
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    final uid = _uid;
    if (uid == null) return;

    if (_paymentMethod == 'gcash' && _gcashRefController.text.trim().length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 13-digit GCash reference number.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final profile = await _firestoreService.getUser(uid);
      final items = _cart.entries.map((e) {
        final product = _products.firstWhere((p) => p['id'] == e.key);
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
        deliveryAddress: _currentAddress,
        areaZone: _areaZoneByAddress[_currentAddress] ?? 'other',
        items: items,
        totalAmount: _checkoutTotal,
        paymentMethod: _paymentMethod,
        gcashReference: _paymentMethod == 'gcash' && _gcashRefController.text.trim().isNotEmpty ? _gcashRefController.text.trim() : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isPlacingOrder = false;
        _isCheckoutView = false;
        _navIndex = 1;
        _cart.clear();
        _gcashRefController.clear();
        _notesController.clear();
        _hasUploadedReceipt = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Order Placed Successfully!'), backgroundColor: AppColors.secondary));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to place order: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.cancelOrder(orderId);
      messenger.showSnackBar(const SnackBar(content: Text('Order Cancelled.'), backgroundColor: AppColors.error));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: AppColors.error));
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _navIndex = index;
      _isCheckoutView = false;
    });
  }

  void _showLocationPicker(bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose Delivery Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(height: 16),
                  ..._availableAddresses.map((address) {
                    final bool isSelected = address == _currentAddress;
                    return InkWell(
                      onTap: () {
                        setState(() => _currentAddress = address);
                        Navigator.pop(sheetContext);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surfaceFrost : AppColors.surfaceCanvas,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: isSelected ? AppColors.primary : AppColors.outline),
                            const SizedBox(width: 10),
                            Expanded(child: Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textMain))),
                            if (isSelected) const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMapDialog(bool isDark) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.near_me, color: AppColors.tertiary),
                        SizedBox(width: 8),
                        Text('Live Rider Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Icon(Icons.map, size: 48, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                        child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _simulateFileUpload() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening gallery...')));
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _hasUploadedReceipt = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Screenshot attached!'), backgroundColor: AppColors.secondary));
      }
    });
  }

  Widget _buildFloatingBottomNav(bool isDark, bool hasActiveOrder) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))
                        ],
                      ),
                      child: BottomNavigationBar(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        type: BottomNavigationBarType.fixed,
                        currentIndex: _navIndex,
                        onTap: _onNavTapped,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedItemColor: AppColors.primary,
                        unselectedItemColor: AppColors.textVariant,
                        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelStyle: const TextStyle(fontSize: 11),
                        items: [
                          const BottomNavigationBarItem(icon: Icon(Icons.local_mall), label: 'Store'),
                          BottomNavigationBarItem(
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.receipt_long),
                                  if (hasActiveOrder)
                                    Positioned(
                                      top: -2, right: -4,
                                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.cyanElectric, shape: BoxShape.circle)),
                                    )
                                ],
                              ),
                              label: 'Orders'),
                          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Payments'),
                          const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = _uid;

    return StreamBuilder<List<OrderModel>>(
      stream: uid == null ? const Stream.empty() : _firestoreService.getOrdersForCustomerStream(uid),
      builder: (context, snapshot) {
        final myOrders = snapshot.data ?? const <OrderModel>[];
        final hasActiveOrder = myOrders.any(
              (o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: _isCheckoutView ? SafeArea(child: _buildCheckoutView(isDark)) : _buildMainBody(isDark, myOrders, hasActiveOrder),
            ),
          ),
          bottomNavigationBar: _isCheckoutView ? null : _buildFloatingBottomNav(isDark, hasActiveOrder),
          floatingActionButton: (!_isCheckoutView && _cart.isNotEmpty && _navIndex == 0) ? _buildCheckoutButton(isDark) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildMainBody(bool isDark, List<OrderModel> myOrders, bool hasActiveOrder) {
    if (_navIndex == 0) return _buildHomeFeed(isDark);
    if (_navIndex == 1) return _buildOrdersScreen(isDark, myOrders, hasActiveOrder);
    if (_navIndex == 2) return _buildPaymentsScreen(isDark, myOrders);
    return const SafeArea(child: ProfileScreen());
  }

  Widget _buildProductListItem(Map<String, dynamic> p, int qty, bool isDark) {
    final bool isPopular = p['id'] == 'r_slim';
    final bool isNewTank = p['id'] == 'n_slim' || p['id'] == 'n_round';
    final String priceSuffix = isNewTank ? 'complete' : '/ jug';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(12)),
            child: Image.network(p['image'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, color: AppColors.cyanElectric)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(p['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain))),
                    if (isPopular) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(4)),
                        child: const Text('POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(p['type'], style: const TextStyle(fontSize: 11, color: AppColors.textVariant), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₱${(p['price'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textMain, fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(priceSuffix, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(100)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _removeFromCart(p['id']),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                    child: const Icon(Icons.remove, size: 16, color: AppColors.primary),
                  ),
                ),
                SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain))),
                InkWell(
                  onTap: () => _addToCart(p['id']),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4)]),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryContainer, AppColors.primary]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: -2, offset: const Offset(0, 8))]
              ),
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _emptyGallonsReturning = _orderedRefillsCount;
                  _isCheckoutView = true;
                }),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text('Check out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                          child: Text('${_cart.values.fold(0, (a, b) => a + b)} items', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('₱${_cartSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersScreen(bool isDark, List<OrderModel> myOrders, bool hasActiveOrder) {
    final activeOrders = myOrders
        .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
        .toList();
    final historyOrders = myOrders
        .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
        .toList();

    return SafeArea(
      child: Column(
        children: [
          _buildOrderSwitcher(hasActiveOrder),
          Expanded(
            child: _ordersTab == 0
                ? _buildActiveOrdersList(isDark, activeOrders)
                : _buildOrderHistoryList(isDark, historyOrders),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSwitcher(bool hasActiveOrder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(100)),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _ordersTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: _ordersTab == 0 ? BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer]),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
                  ) : const BoxDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_ordersTab == 0 && hasActiveOrder)
                        Container(margin: const EdgeInsets.only(right: 6), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.cyanElectric, shape: BoxShape.circle)),
                      Text('Active Orders', textAlign: TextAlign.center, style: TextStyle(color: _ordersTab == 0 ? Colors.white : AppColors.textVariant, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _ordersTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: _ordersTab == 1 ? BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer]),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
                  ) : const BoxDecoration(),
                  child: Text('Order History', textAlign: TextAlign.center, style: TextStyle(color: _ordersTab == 1 ? Colors.white : AppColors.textVariant, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryList(bool isDark, List<OrderModel> historyOrders) {
    final now = DateTime.now();
    List<OrderModel> displayedHistory = historyOrders.where((order) {
      if (_orderHistoryFilter == 'All Orders') return true;
      if (_orderHistoryFilter == 'Delivered') return order.status == OrderStatus.delivered;
      if (_orderHistoryFilter == 'Cancelled') return order.status == OrderStatus.cancelled;
      if (_orderHistoryFilter == 'This Month') {
        return order.createdAt.year == now.year && order.createdAt.month == now.month;
      }
      return true;
    }).toList();

    final searchQuery = _historySearchCtrl.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      displayedHistory = displayedHistory.where((order) {
        return order.orderNumber.toLowerCase().contains(searchQuery) ||
            order.items.any((i) => i.name.toLowerCase().contains(searchQuery));
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _buildLifetimeSummaryCard(historyOrders),
        const SizedBox(height: 24),
        _buildOrderSearchAndFilters(isDark, historyOrders.length),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_orderHistoryFilter.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1.2)),
            Text('${displayedHistory.length} Deliveries Found', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 16),

        if (displayedHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No orders match your filter.', style: TextStyle(color: AppColors.textVariant))),
          )
        else
          ...displayedHistory.map((order) => _buildOrderHistoryCard(order)),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildLifetimeSummaryCard(List<OrderModel> historyOrders) {
    final completedOrders = historyOrders.where((o) => o.status == OrderStatus.delivered).toList();
    final gallonsRefilled = completedOrders.fold<int>(
      0,
          (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.quantity),
    );
    final totalSpent = completedOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.38), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, bottom: -40,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.cyanHighlight.withValues(alpha: 0.15))),
          ),
          Positioned(
            left: -20, top: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryContainer.withValues(alpha: 0.2))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop, color: AppColors.cyanHighlight, size: 18),
                        SizedBox(width: 4),
                        Text('HYDRATION METRICS', style: TextStyle(color: AppColors.surfaceFrost, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                      child: const Text('Drink 8 Member', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat('${completedOrders.length}', 'Completed', Colors.white),
                    _buildSummaryStat('$gallonsRefilled', 'Gallons Refilled', AppColors.cyanHighlight),
                    _buildSummaryStat('₱${totalSpent.toStringAsFixed(0)}', 'Total Spent', AppColors.secondaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor, height: 1)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.surfaceFrost.withValues(alpha: 0.9))),
      ],
    );
  }

  Widget _buildOrderSearchAndFilters(bool isDark, int totalOrders) {
    return Column(
      children: [
        TextField(
          controller: _historySearchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search Order ID or product...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.outline),
            filled: true, fillColor: AppColors.surfaceLowest,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHistoryFilterChip('All Orders', count: '$totalOrders'),
              const SizedBox(width: 8),
              _buildHistoryFilterChip('Delivered', dotColor: AppColors.tealAccent),
              const SizedBox(width: 8),
              _buildHistoryFilterChip('This Month'),
              const SizedBox(width: 8),
              _buildHistoryFilterChip('Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilterChip(String label, {Color? dotColor, String? count}) {
    bool isActive = _orderHistoryFilter == label;
    return InkWell(
      onTap: () => setState(() => _orderHistoryFilter = label),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer]) : null,
          color: isActive ? null : AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(100),
          border: isActive ? null : Border.all(color: AppColors.surfaceContainer),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          children: [
            if (dotColor != null && !isActive) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6)
            ],
            if (isActive && label != 'All Orders') ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4)
            ],
            Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textVariant, fontSize: 13, fontWeight: FontWeight.bold)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.2) : AppColors.surfaceContainer, shape: BoxShape.circle),
                child: Text(count, style: TextStyle(color: isActive ? Colors.white : AppColors.textVariant, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final accentColor = isDelivered ? AppColors.tealAccent : (isCancelled ? AppColors.outline : AppColors.error);
    final statusLabel = isDelivered ? 'Delivered' : (isCancelled ? 'Cancelled' : 'Pending');
    final statusIcon = isDelivered ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.schedule);
    final dateLabel = '${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(order.orderNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(100)),
                                  child: const Text('Standard', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(dateLabel, style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDelivered ? AppColors.secondaryContainer.withValues(alpha: 0.3) : (isCancelled ? AppColors.surfaceContainer : AppColors.errorContainer),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 12, color: isDelivered ? AppColors.secondary : (isCancelled ? AppColors.outline : AppColors.error)),
                              const SizedBox(width: 4),
                              Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDelivered ? AppColors.secondary : (isCancelled ? AppColors.outline : AppColors.error))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.water_drop, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                  ],
                                ),
                                Text('₱${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₱${order.totalAmount.toStringAsFixed(2)} total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        Row(
                          children: [
                            Icon(order.paymentMethod == PaymentMethod.gcash ? Icons.account_balance_wallet : Icons.payments, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(order.paymentMethod == PaymentMethod.gcash ? 'GCash' : 'Cash', style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isDelivered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (final item in order.items) {
                                final product = _products.firstWhere(
                                      (p) => p['name'] == item.name,
                                  orElse: () => const {},
                                );
                                if (product.isNotEmpty) {
                                  _cart[product['id']] = (_cart[product['id']] ?? 0) + item.quantity;
                                }
                              }
                              _navIndex = 0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to cart.')));
                          },
                          icon: const Icon(Icons.repeat, size: 16, color: Colors.white),
                          label: const Text('Reorder', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeFeed(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 120, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<UserModel?>(
                      future: _userFuture,
                      builder: (context, snapshot) {
                        final name = snapshot.data?.name.split(' ').first ?? 'there';
                        return Row(
                          children: [
                            Flexible(child: Text('Good Day, $name!', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5))),
                            const SizedBox(width: 8),
                            const Icon(Icons.water_drop, color: AppColors.cyanElectric, size: 20),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showLocationPicker(isDark),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('Delivery to: ', style: TextStyle(fontSize: 13, color: AppColors.textVariant)),
                          Flexible(
                            child: Text(
                              _currentAddress,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const Icon(Icons.expand_more, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(100)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text('Pure Certified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryContainer, AppColors.primary, AppColors.cyanElectric]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('DOH APPROVED STATION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Drink 8 Purified Water Refill', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                          const SizedBox(height: 6),
                          Text(
                            'Multi-stage micro-filtration with automated UV sanitization cycle.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 76,
                      height: 92,
                      child: Image.network(
                        _heroImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, color: Colors.white, size: 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('₱35', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          SizedBox(width: 4),
                          Text('/ 5-Gallon', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addToCart('r_slim'),
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 18),
                        label: const Text('Quick Reorder', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Standard Catalog', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(100)),
                    child: Text('${_products.length} Options', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final p = _products[index];
              int qty = _cart[p['id']] ?? 0;
              return _buildProductListItem(p, qty, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(bool isDark, List<OrderModel> activeOrders) {
    if (activeOrders.isEmpty) {
      return const Center(child: Text('No active orders right now.', style: TextStyle(color: AppColors.outline)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        for (final order in activeOrders) ...[
          _buildActiveOrderCard(order, isDark),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 84),
      ],
    );
  }

  Widget _buildActiveOrderCard(OrderModel order, bool isDark) {
    final int currentStep = order.status == OrderStatus.outForDelivery ? 2 : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 17, letterSpacing: -0.5)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(100)),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.cyanElectric),
                              const SizedBox(width: 4),
                              Text(order.status == OrderStatus.outForDelivery ? 'Out for delivery' : 'Placed', style: const TextStyle(fontSize: 10, color: AppColors.cyanElectric, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(order.deliveryAddress ?? '', style: const TextStyle(color: AppColors.textVariant, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
                  Row(
                    children: [
                      Icon(order.isPaid ? Icons.check_circle : Icons.hourglass_bottom, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 2),
                      Text(order.isPaid ? 'Paid' : (order.paymentMethod == PaymentMethod.gcash ? 'GCash Pending' : 'Cash on Delivery'), style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                for (int i = 0; i < order.items.length; i++) ...[
                  if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFE2E7FF))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceLowest, shape: BoxShape.circle), child: const Icon(Icons.water_drop, size: 18, color: AppColors.primary)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(order.items[i].name, style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${order.items[i].quantity}x', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                          Text('₱${order.items[i].totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStepDot('Placed', 0, currentStep, AppColors.secondary, Icons.check),
              _buildStepLine(1, currentStep, AppColors.cyanElectric),
              _buildStepDot('Filling', 1, currentStep, AppColors.cyanElectric, Icons.water_drop, glowing: true),
              _buildStepLine(2, currentStep, AppColors.cyanElectric),
              _buildStepDot('Delivery', 2, currentStep, const Color(0xFFEAEDFF), Icons.two_wheeler, iconColor: AppColors.outline, textColor: AppColors.outline),
              _buildStepLine(3, currentStep, AppColors.cyanElectric),
              _buildStepDot('Done', 3, currentStep, const Color(0xFFEAEDFF), Icons.verified, iconColor: AppColors.outline, textColor: AppColors.outline),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (order.status == OrderStatus.outForDelivery) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showMapDialog(isDark),
                    icon: const Icon(Icons.near_me, size: 18, color: Colors.white),
                    label: const Text('Live Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 4),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _cancelOrder(order.id),
                  icon: const Icon(Icons.cancel, size: 18, color: AppColors.error),
                  label: const Text('Cancel Order', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorContainer, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _downloadMonthlyStatement(List<OrderModel> thisMonthOrders, double totalSpent, String monthLabel) async {
    final messenger = ScaffoldMessenger.of(context);
    if (thisMonthOrders.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No completed orders this month yet.')));
      return;
    }
    try {
      final customer = await _userFuture;
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pdfContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('AquaOps — Drink 8 Purified Water', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Monthly Statement — $monthLabel'),
              pw.SizedBox(height: 12),
              pw.Text('Customer: ${customer?.name ?? 'N/A'}'),
              pw.Text('Email: ${customer?.email ?? 'N/A'}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Order #', 'Items', 'Amount'],
                data: thisMonthOrders.map((o) => [
                  '${o.createdAt.month}/${o.createdAt.day}/${o.createdAt.year}',
                  o.orderNumber,
                  o.items.isEmpty ? '-' : o.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                  'PHP ${o.totalAmount.toStringAsFixed(2)}',
                ]).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total: PHP ${totalSpent.toStringAsFixed(2)}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'aquaops_statement_${monthLabel.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to generate statement: $e'), backgroundColor: AppColors.error));
    }
  }

  Widget _buildPaymentsScreen(bool isDark, List<OrderModel> myOrders) {
    final now = DateTime.now();
    final thisMonthOrders = myOrders.where((o) =>
    o.status == OrderStatus.delivered &&
        o.revenueDate.year == now.year &&
        o.revenueDate.month == now.month).toList();
    final totalSpentThisMonth = thisMonthOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final monthLabel = '${_monthNames[now.month - 1]} ${now.year}';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryContainer, AppColors.primary, AppColors.cyanElectric]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics, color: AppColors.cyanHighlight, size: 20),
                        SizedBox(width: 8),
                        Text('SPENDING OVERVIEW', style: TextStyle(color: AppColors.cyanHighlight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)), child: Text(monthLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Spent this month', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('₱', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 2),
                    Text(totalSpentThisMonth.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.water_drop, color: Colors.white, size: 16)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${thisMonthOrders.length} Orders', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), const Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 10))])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.inventory_2, color: Colors.white, size: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FutureBuilder<UserModel?>(
                                future: _uid == null ? null : _firestoreService.getUser(_uid!),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.unreturnedContainers ?? 0;
                                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$count Container${count == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), const Text('At Your Home', style: TextStyle(color: Colors.white70, fontSize: 10))]);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 16),

          if (myOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.outline))),
            ),
          ...myOrders.map((o) {
            final subtitle = '${o.createdAt.month}/${o.createdAt.day}/${o.createdAt.year} • ${o.paymentMethod == PaymentMethod.gcash ? 'GCash' : 'Cash'}';
            final status = o.status == OrderStatus.delivered ? 'Completed' : (o.status == OrderStatus.cancelled ? 'Cancelled' : 'Pending');
            final details = o.items.isEmpty ? '—' : o.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionItem(
                icon: Icons.local_shipping,
                title: 'Refill Order ${o.orderNumber}',
                subtitle: subtitle,
                amount: '-₱${o.totalAmount.toStringAsFixed(2)}',
                status: status,
                details: details,
                isCredit: false,
              ),
            );
          }),

          const SizedBox(height: 12),
          InkWell(
            onTap: () => _downloadMonthlyStatement(thisMonthOrders, totalSpentThisMonth, monthLabel),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceLowest, shape: BoxShape.circle), child: const Icon(Icons.description, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download Monthly Statement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        Text('Includes all receipts & return credits (.PDF)', style: TextStyle(fontSize: 11, color: AppColors.textVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.download, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({required IconData icon, required String title, required String subtitle, required String amount, required String status, required String details, required bool isCredit}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: isCredit ? AppColors.secondaryContainer : AppColors.surfaceFrost, shape: BoxShape.circle), child: Icon(icon, size: 18, color: isCredit ? AppColors.secondary : AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain), overflow: TextOverflow.ellipsis),
                          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isCredit ? AppColors.secondary : AppColors.textMain)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isCredit ? AppColors.surfaceFrost : AppColors.secondaryContainer, borderRadius: BorderRadius.circular(100)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCredit ? AppColors.primary : AppColors.secondary))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(details, style: const TextStyle(fontSize: 11, color: AppColors.outline), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Icon(Icons.receipt, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('E-Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(String label, int stepIndex, int currentStep, Color activeColor, IconData icon, {Color? iconColor, Color? textColor, bool glowing = false}) {
    bool isActive = currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : const Color(0xFFEAEDFF),
            boxShadow: glowing && isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 16)] : const [],
          ),
          child: Icon(icon, size: 16, color: isActive ? Colors.white : (iconColor ?? AppColors.outline)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.textMain : (textColor ?? AppColors.outline))),
      ],
    );
  }

  Widget _buildStepLine(int targetStep, int currentStep, Color primary) {
    bool isActive = currentStep >= targetStep;
    return Expanded(child: Container(height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isActive ? primary : const Color(0xFFE2E7FF), borderRadius: BorderRadius.circular(2))));
  }

  Widget _buildCheckoutView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 200, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => setState(() => _isCheckoutView = false)),
              const Text('Checkout', style: TextStyle(color: AppColors.textMain, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.cyanElectric.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.water_drop, color: AppColors.primary, size: 20)), const SizedBox(width: 12), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FAST PURE FLOW', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1)), Text('Express Hydration Dispatch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain))])]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(100)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, size: 14, color: AppColors.secondary), SizedBox(width: 4), Text('30-45 MINS', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold))])),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.location_on, color: AppColors.primary, size: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [Text('DELIVERING TO', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)), SizedBox(width: 6), Icon(Icons.circle, size: 6, color: AppColors.secondary), SizedBox(width: 6), Text('Home', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold))]),
                                const SizedBox(height: 2),
                                Text(_currentAddress, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                                const Text('San Pablo City, Laguna 4000', style: TextStyle(fontSize: 13, color: AppColors.textVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showLocationPicker(isDark),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(100)), child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.pin_drop, size: 16, color: AppColors.outline), SizedBox(width: 8), Expanded(child: Text('Near Blue Gate, Landmark: Water Station Alpha', style: TextStyle(fontSize: 11, color: AppColors.textVariant)))])),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_drink, color: AppColors.primary, size: 20), SizedBox(width: 8), Text('Order Summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFCCE5FF), borderRadius: BorderRadius.circular(100)), child: Text('${_cart.values.fold(0, (a, b) => a + b)} Items', style: const TextStyle(fontSize: 10, color: Color(0xFF004B73), fontWeight: FontWeight.bold)))]),
                const SizedBox(height: 16),
                ..._cart.entries.map((e) {
                  final p = _products.firstWhere((prod) => prod['id'] == e.key);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(8)), child: Icon((p['id'] as String).contains('slim') ? Icons.water_drop : Icons.local_drink, color: AppColors.cyanElectric, size: 24)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain), overflow: TextOverflow.ellipsis), Text('Qty: ${e.value} • ₱${(p['price'] as double).toStringAsFixed(2)} each', style: const TextStyle(fontSize: 11, color: AppColors.textVariant))]))])),
                        const SizedBox(width: 8),
                        Text('₱${((p['price'] as double) * e.value).toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_orderedRefillsCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Row(children: [const Icon(Icons.swap_horizontal_circle, color: AppColors.secondary, size: 22), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Container Exchange', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)), Text('Total containers ordered: $_orderedRefillsCount', style: const TextStyle(fontSize: 11, color: AppColors.textVariant))]))])), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(100)), child: const Text('Standard 1:1', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Empty Gallons Returning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain)), Text('Handing over to rider at door', style: TextStyle(fontSize: 11, color: AppColors.primary))])),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                          child: Row(
                            children: [
                              InkWell(onTap: () => setState(() => _emptyGallonsReturning = _emptyGallonsReturning > 0 ? _emptyGallonsReturning - 1 : 0), child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.remove, size: 18, color: AppColors.primary))),
                              Container(width: 28, alignment: Alignment.center, child: Text('$_emptyGallonsReturning', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain))),
                              InkWell(onTap: () => setState(() => _emptyGallonsReturning++), child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.add, size: 18, color: AppColors.primary))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_missingContainerDeposit > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CONTAINER DEFICIT NOTICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.error, letterSpacing: 1)), const SizedBox(height: 2), Text('Missing ${_orderedRefillsCount - _emptyGallonsReturning} container(s). A refundable deposit of ₱${_missingContainerDeposit.toStringAsFixed(2)} (₱200/gal) has been added.', style: const TextStyle(fontSize: 13, color: AppColors.error))])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20), SizedBox(width: 8), Text('Payment Method', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain))]), Text('INSTANT VERIFY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary))]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: InkWell(onTap: () => setState(() => _paymentMethod = 'cash'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _paymentMethod == 'cash' ? AppColors.primaryContainer : AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(100), boxShadow: _paymentMethod == 'cash' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)] : const []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payments, size: 18, color: _paymentMethod == 'cash' ? Colors.white : AppColors.textVariant), const SizedBox(width: 8), Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _paymentMethod == 'cash' ? Colors.white : AppColors.textVariant))])))),
                    const SizedBox(width: 12),
                    Expanded(child: InkWell(onTap: () => setState(() => _paymentMethod = 'gcash'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _paymentMethod == 'gcash' ? AppColors.primaryContainer : AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(100), boxShadow: _paymentMethod == 'gcash' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)] : const []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, size: 18, color: _paymentMethod == 'gcash' ? Colors.white : AppColors.textVariant), const SizedBox(width: 8), Text('GCash Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _paymentMethod == 'gcash' ? Colors.white : AppColors.textVariant))])))),
                  ],
                ),
                if (_paymentMethod == 'gcash') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GCASH ACCOUNT NAME', style: TextStyle(fontSize: 10, color: AppColors.textVariant, fontWeight: FontWeight.w800)), Text('Station Owner (Aquaflow)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)), Text('0917 123 4567', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: 1))])), Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.content_copy, size: 18, color: AppColors.primary))])),
                        const SizedBox(height: 16),
                        SoftInputField(icon: Icons.receipt_long, label: '13-Digit Ref Number', controller: _gcashRefController),
                        const SizedBox(height: 16),
                        const Text('Payment Screenshot Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textVariant)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _simulateFileUpload,
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(100)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 20, color: AppColors.primary), SizedBox(width: 8), Text('Upload GCash Screenshot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))])),
                        ),
                        if (_hasUploadedReceipt) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                            child: Row(
                              children: [
                                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.image, color: AppColors.primary)),
                                const SizedBox(width: 12),
                                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('receipt_gcash.jpg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMain)), Text('Verified Attachment • 1.4 MB', style: TextStyle(fontSize: 11, color: AppColors.secondary))])),
                                IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.textVariant), onPressed: () => setState(() => _hasUploadedReceipt = false)),
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
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery Notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)), Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.textVariant))]),
                const SizedBox(height: 12),
                TextField(controller: _notesController, maxLines: 2, style: const TextStyle(color: AppColors.textMain, fontSize: 13), decoration: InputDecoration(hintText: 'Ring the bell twice, gate is unlocked...', hintStyle: const TextStyle(color: AppColors.outline), filled: true, fillColor: AppColors.surfaceCanvas, contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Refills Total (${_cart.values.fold(0, (a, b) => a + b)} Gallons)', style: const TextStyle(fontSize: 13, color: AppColors.textVariant)), Text('₱${_cartSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain))]),
          if (_missingContainerDeposit > 0) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.shield, size: 14, color: AppColors.error), const SizedBox(width: 4), Text('Container Deposit (${_orderedRefillsCount - _emptyGallonsReturning}x)', style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500))]), Text('₱${_missingContainerDeposit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.error))]),
          ],
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TOTAL PAY AMOUNT', style: TextStyle(fontSize: 10, color: AppColors.textVariant, fontWeight: FontWeight.w800, letterSpacing: 1)), Text('Includes fully refundable bottle deposit', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold))])), Text('₱${_checkoutTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1))]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 4),
              child: _isPlacingOrder
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Confirm Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}