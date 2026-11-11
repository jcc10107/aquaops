import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/product_illustration.dart';

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
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
                letterSpacing: -0.4,
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
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // Clean Rectangular Address Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onAddressTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.sky50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppColors.primarySky,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DELIVER TO',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primarySky,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            currentAddress.isEmpty ? 'Tap to select delivery location' : currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 20, color: AppColors.slate400),
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
          colors: [
            AppColors.primary,
            AppColors.primarySky,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0284C7),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            bottom: -6,
            child: Icon(
              Icons.water_drop,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'DOH APPROVED',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Drink 8 Purified Water',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-filtered and safe purified water delivered straight to your door.',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => onAddToCart('r_slim'),
                      icon: const Icon(Icons.flash_on, size: 15, color: AppColors.primarySky),
                      label: const Text(
                        'Quick Reorder',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primarySky,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primarySky,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '₱35 / 5-Gal',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Water & Containers',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${products.length} Products',
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.slate600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p, int qty, String? imageUrl) {
    final String id = p['id'] as String;
    final bool isRefill = id == 'r_slim' || id == 'r_round';
    final bool inStock = (p['inStock'] as bool?) ?? true;
    final int maxQty = (p['maxQty'] as int?) ?? 1 << 30;
    final bool canAddMore = inStock && qty < maxQty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIce,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ProductIllustration(productId: id),
                        ),
                      )
                    else
                      Positioned.fill(child: ProductIllustration(productId: id)),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRefill ? Colors.white : AppColors.primarySky,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isRefill ? AppColors.sky200 : AppColors.primarySky,
                          ),
                        ),
                        child: Text(
                          isRefill ? 'REFILL' : 'NEW JUG',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isRefill ? AppColors.primarySky : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                p['type'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₱${(p['price'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                ),
              ),
            ],
            ),
          ),
          const SizedBox(height: 8),

          // Add to cart / Quantity controller
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: qty > 0
                ? Container(
              key: const ValueKey('stepper'),
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.sky50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.sky200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => onRemoveFromCart(id),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                    child: const SizedBox(
                      width: 32,
                      height: 36,
                      child: Center(
                        child: Icon(Icons.remove, size: 16, color: AppColors.primarySky),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$qty',
                      key: ValueKey(qty),
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primarySky,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: canAddMore ? () => onAddToCart(id) : null,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                    child: SizedBox(
                      width: 32,
                      height: 36,
                      child: Center(
                        child: Icon(Icons.add, size: 16, color: canAddMore ? AppColors.primarySky : AppColors.slate300),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : SizedBox(
              key: const ValueKey('addButton'),
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: inStock ? () => onAddToCart(id) : null,
                icon: Icon(inStock ? Icons.add_shopping_cart : Icons.block, size: 14),
                label: Text(
                  inStock ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inStock ? AppColors.primarySky : AppColors.slate200,
                  foregroundColor: inStock ? Colors.white : AppColors.slate500,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Exactly matches POS screen constraints
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: topInset + CustomHeader.contentHeight + 14,
            bottom: 130, // Matches POS screen bottom padding
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 24),
              _buildCatalogHeader(),
              const SizedBox(height: 14),
              StreamBuilder<Map<String, String>>(
                stream: FirestoreService().getProductImagesStream(),
                builder: (context, imageSnapshot) {
                  final images = imageSnapshot.data ?? const <String, String>{};
                  return GridView.builder(
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
                      return _buildProductCard(p, cart[p['id']] ?? 0, images[p['id'] as String]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}