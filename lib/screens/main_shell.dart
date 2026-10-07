import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../main.dart';
import '../widgets/aqua_bottom_nav.dart';
import '../widgets/custom_header.dart';
import 'delivery/delivery_queue_screen.dart';
import 'inventory/inventory_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import 'pos/pos_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentUserRoleNotifier,
      builder: (context, role, _) {
        final bool isOwner = role == 'owner';
        final bool isStaff = role == 'staff';
        final bool isRider = role == 'rider';

        List<Widget> pages;
        if (isOwner) {
          pages = const [
            OwnerDashboardScreen(),
            PosScreen(),
            DeliveryQueueScreen(),
            InventoryScreen(),
            ProfileScreen(),
          ];
        } else if (isStaff) {
          pages = const [
            PosScreen(),
            InventoryScreen(),
            ProfileScreen(),
          ];
        } else if (isRider) {
          pages = const [
            DeliveryQueueScreen(),
            ProfileScreen(),
          ];
        } else {
          pages = const [
            Center(child: Text('Order')),
            Center(child: Text('Orders')),
            Center(child: Text('Payments')),
            ProfileScreen(),
          ];
        }

        final int safeIndex = _index.clamp(0, pages.length - 1);

        return Scaffold(
          backgroundColor: AppColors.surfaceCanvas,
          extendBody: true,
          body: Column(
            children: [
              CustomHeader(
                onProfileTap: () => setState(() => _index = pages.length - 1),
              ),
              Expanded(
                child: IndexedStack(index: safeIndex, children: pages),
              ),
            ],
          ),
          bottomNavigationBar: AquaBottomNav(
            isOwner: isOwner,
            isStaff: isStaff,
            isRider: isRider,
            currentIndex: safeIndex,
            onTap: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}