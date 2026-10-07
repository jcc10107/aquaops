import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/aqua_bottom_nav.dart';
import '../../widgets/custom_header.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import 'customer_store_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_payments_screen.dart';
import 'customer_checkout_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _navIndex = 0;
  bool _isCheckoutView = false;
  final Map<String, int> _cart = {};
  String _currentAddress = 'Barangay San Isidro';

  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  late final Future<UserModel?> _userFuture;
  late final Stream<List<OrderModel>> _ordersStream;

  static const List<String> _availableAddresses = [
    'Barangay San Isidro',
    'Barangay Del Remedio',
    'Barangay San Roque',
  ];

  final List<Map<String, dynamic>> _products = const [
    {
      'id': 'r_slim',
      'name': 'Slim Refill',
      'price': 35.0,
      'type': 'Refill exchange • Cap sanitized',
    },
    {
      'id': 'r_round',
      'name': 'Round Refill',
      'price': 35.0,
      'type': 'Refill exchange • Dispenser fit',
    },
    {
      'id': 'n_slim',
      'name': 'New Slim Gallon',
      'price': 235.0,
      'type': 'New Container + Pure Water',
    },
    {
      'id': 'n_round',
      'name': 'New Round Gallon',
      'price': 255.0,
      'type': 'New Container + Pure Water',
    },
  ];

  double get _cartSubtotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'] == id);
      total += (product['price'] as double) * qty;
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    _userFuture = uid == null
        ? Future<UserModel?>.value(null)
        : _firestoreService.getUser(uid);
    _ordersStream = uid == null
        ? const Stream.empty()
        : _firestoreService.getOrdersForCustomerStream(uid);
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 50,
                    spreadRadius: -12,
                    offset: Offset(0, 25),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFC7D2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Delivery Address',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF131B2E),
                            ),
                          ),
                          Text(
                            'Select your preferred delivery location',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF3F4850),
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: const Color(0xFFEAEDFF),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(sheetContext),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(Icons.close,
                                size: 20, color: Color(0xFF3F4850)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._availableAddresses.map((address) {
                    final bool isSelected = address == _currentAddress;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            setState(() => _currentAddress = address);
                            Navigator.pop(sheetContext);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF006194)
                                        : const Color(0xFFE0F2FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF006194),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF131B2E),
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 22,
                                  color: isSelected
                                      ? const Color(0xFF006194)
                                      : const Color(0xFFBFC7D2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () => Navigator.pop(sheetContext),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Confirm Delivery Address',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        final myOrders = snapshot.data ?? const <OrderModel>[];
        final hasActiveOrder = myOrders.any(
              (o) =>
          o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF6FAFC),
          extendBody: true,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: _isCheckoutView
                  ? CustomerCheckoutScreen(
                cart: _cart,
                products: _products,
                currentAddress: _currentAddress,
                onBack: () => setState(() => _isCheckoutView = false),
                onChangeAddress: () => _showLocationPicker(isDark),
                onOrderSuccess: () {
                  setState(() {
                    _isCheckoutView = false;
                    _navIndex = 1;
                    _cart.clear();
                  });
                },
              )
                  : Stack(
                children: [
                  _buildMainBody(isDark, myOrders, hasActiveOrder),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CustomHeader(
                      onProfileTap: () => _onNavTapped(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _isCheckoutView
              ? null
              : AquaBottomNav(
            isOwner: false,
            hasActiveOrder: hasActiveOrder,
            currentIndex: _navIndex,
            onTap: _onNavTapped,
          ),
          floatingActionButton:
          (!_isCheckoutView && _cart.isNotEmpty && _navIndex == 0)
              ? _buildCheckoutButton()
              : null,
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildMainBody(
      bool isDark, List<OrderModel> myOrders, bool hasActiveOrder) {
    return IndexedStack(
      index: _navIndex,
      children: [
        CustomerStoreScreen(
          userFuture: _userFuture,
          currentAddress: _currentAddress,
          onAddressTap: () => _showLocationPicker(isDark),
          products: _products,
          cart: _cart,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
        ),
        CustomerOrdersScreen(
          myOrders: myOrders,
          hasActiveOrder: hasActiveOrder,
          products: _products,
          onReorder: (cartUpdates) {
            setState(() {
              cartUpdates.forEach((key, value) {
                _cart[key] = (_cart[key] ?? 0) + value;
              });
              _navIndex = 0;
            });
          },
        ),
        CustomerPaymentsScreen(
          myOrders: myOrders,
          userFuture: _userFuture,
          uid: _uid,
        ),
        const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: CustomHeader.contentHeight + 12),
            child: ProfileScreen(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    final int itemCount = _cart.values.fold(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxWidth: 450),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73007BB9),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => setState(() => _isCheckoutView = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag,
                          color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Check out',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$itemCount items',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '₱${_cartSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}