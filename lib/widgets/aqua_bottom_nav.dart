import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AquaBottomNav extends StatelessWidget implements PreferredSizeWidget {
  final bool isOwner;
  final bool isStaff;
  final bool isRider;
  final bool hasActiveOrder;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color brandLoginBlue = Color(0xFF0284C7);

  const AquaBottomNav({
    super.key,
    required this.isOwner,
    this.isStaff = false,
    this.isRider = false,
    this.hasActiveOrder = false,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items;

    if (isOwner) {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (isStaff) {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (isRider) {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.local_mall), label: 'Store'),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.receipt_long),
              if (hasActiveOrder)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.cyanElectric,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
            ],
          ),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Payments'),
        const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
      ];
    }

    return SafeArea(
      top: false,
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
                    color: AppColors.surfaceLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: brandLoginBlue.withValues(alpha: 0.12),
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
                      currentIndex: currentIndex,
                      onTap: onTap,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: brandLoginBlue,
                      unselectedItemColor: AppColors.textVariant,
                      selectedIconTheme: const IconThemeData(color: brandLoginBlue),
                      unselectedIconTheme: const IconThemeData(color: AppColors.textVariant),
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: brandLoginBlue,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textVariant,
                      ),
                      items: items,
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
}