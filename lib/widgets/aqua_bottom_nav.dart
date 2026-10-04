import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AquaBottomNav extends StatelessWidget {
  final bool isOwner;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AquaBottomNav({
    super.key,
    required this.isOwner,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = isOwner
        ? const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
      BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ]
        : const [
      BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
      BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

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
                    color: AppColors.surfaceLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
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
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.textVariant,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
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