import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_header.dart';

class CustomerStoreScreen extends StatelessWidget {
  final Future<UserModel?> userFuture;
  final String currentAddress;
  final VoidCallback onAddressTap;
  final List<Map<String, dynamic>> products;
  final Map<String, int> cart;
  final Function(String) onAddToCart;
  final Function(String) onRemoveFromCart;

  const CustomerStoreScreen({
    super.key,
    required this.userFuture,
    required this.currentAddress,
    required this.onAddressTap,
    required this.products,
    required this.cart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  static const String _font = 'Plus Jakarta Sans';
  static const Color _blue = Color(0xFF0284C7);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _frost = Color(0xFFE0F2FE);

  IconData _iconFor(String id) {
    switch (id) {
      case 'r_slim':
        return Icons.water_drop;
      case 'r_round':
        return Icons.local_drink;
      case 'n_slim':
        return Icons.propane_tank;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<UserModel?>(
          future: userFuture,
          builder: (context, snapshot) {
            final name = snapshot.data?.name.split(' ').first ?? 'there';
            return Text(
              'Good Day, $name!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 22,
                height: 28 / 22,
                letterSpacing: -0.44,
                fontWeight: FontWeight.w800,
                color: _onSurface,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        const Text(
          'Stay fresh and hydrated today',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w500,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0284C7),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onAddressTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: _frost,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, size: 18, color: _blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 10,
                              height: 12 / 10,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800,
                              color: _onSurfaceVariant,
                            ),
                          ),
                          Text(
                            currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              height: 16 / 13,
                              letterSpacing: 0.13,
                              fontWeight: FontWeight.w700,
                              color: _onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 20, color: _onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006194), Color(0xFF007BB9), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D007BB9),
            blurRadius: 20,
            spreadRadius: -4,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -32,
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: 0.2),
                      const Color(0xFF22D3EE).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 13, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'DOH APPROVED',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 10,
                                  height: 12 / 10,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Drink 8 Purified Water',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 22,
                            height: 28 / 22,
                            letterSpacing: -0.44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Safe, multi-filtered, and 100% clean direct to your home.',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            height: 16 / 11,
                            fontWeight: FontWeight.w400,
                            color: _frost.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 6,
                                    spreadRadius: -1,
                                    offset: Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 4,
                                    spreadRadius: -2,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(100),
                                  onTap: () => onAddToCart('r_slim'),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Quick Reorder',
                                          style: TextStyle(
                                            fontFamily: _font,
                                            fontSize: 13,
                                            height: 16 / 13,
                                            letterSpacing: 0.13,
                                            fontWeight: FontWeight.w700,
                                            color: _blue,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward, size: 16, color: _blue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '₱35 / 5-Gal',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 13,
                                height: 16 / 13,
                                letterSpacing: -0.13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(0x26000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 12,
              child: IgnorePointer(
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const Icon(
                        Icons.water_drop,
                        size: 48,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      children: [
        const Text(
          'Water & Containers',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 17,
            height: 24 / 17,
            letterSpacing: -0.17,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6CF8BB).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${products.length} Items',
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 10,
              height: 12 / 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00714D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p, int qty) {
    final String id = p['id'] as String;
    final bool isRefill = id == 'r_slim' || id == 'r_round';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0284C7),
            blurRadius: 16,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 96,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF0F9FF),
                      _frost.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 6,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRefill ? Colors.white : const Color(0xFF006C49),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            isRefill ? 'REFILL' : 'NEW',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 9,
                              height: 12 / 9,
                              letterSpacing: 0.54,
                              fontWeight: FontWeight.w800,
                              color: isRefill ? _blue : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        _iconFor(id),
                        size: 42,
                        color: _blue,
                        shadows: const [
                          Shadow(
                            color: Color(0x1A000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                p['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  height: 22 / 15,
                  letterSpacing: -0.15,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                p['type'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w400,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₱${(p['price'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  height: 24 / 17,
                  letterSpacing: -0.17,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (qty > 0)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _frost.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemoveFromCart(id),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(Icons.remove, size: 16, color: _blue),
                      ),
                    ),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      height: 16 / 13,
                      letterSpacing: 0.13,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  Material(
                    color: _blue,
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onAddToCart(id),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: _blue,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => onAddToCart(id),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            height: 14 / 11,
                            letterSpacing: 0.22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topInset + CustomHeader.contentHeight + 12,
        bottom: 120,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(),
          const SizedBox(height: 16),
          _buildHero(),
          const SizedBox(height: 24),
          _buildCatalogHeader(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final p = products[index];
              return _buildProductCard(p, cart[p['id']] ?? 0);
            },
          ),
        ],
      ),
    );
  }
}