// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/pos/pos_screen.dart';
import 'screens/delivery/delivery_queue_screen.dart';
import 'screens/customer/customer_order_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'core/constants/app_colors.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<String> currentUserRoleNotifier = ValueNotifier('none');

final List<Map<String, dynamic>> globalNotifications = [
  {'role': 'owner', 'title': 'Inventory Restocked', 'desc': 'Restocked 100 units. Stock levels refreshed.', 'time': 'Just now'},
  {'role': 'owner', 'title': 'Low Stock Alert', 'desc': 'Non-Spill Blue Gallon Caps is below minimum threshold (24 left).', 'time': '10 mins ago'},
  {'role': 'owner', 'title': 'Maintenance Required', 'desc': 'Station High-Pressure Feed Pump routine service is overdue by 3 days.', 'time': '1 hour ago'},
  {'role': 'customer', 'title': 'Order Out for Delivery', 'desc': 'Rider Arnel is on the way with your 2x Round Purified water.', 'time': '5 mins ago'},
];

void main() {
  runApp(const AquaOpsApp());
}

class AquaOpsApp extends StatelessWidget {
  const AquaOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'AquaOps',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.backgroundLight,
            fontFamily: 'Inter',
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                )),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.backgroundDark,
            fontFamily: 'Inter',
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                )),
          ),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/owner_dashboard': (context) => const OwnerDashboardScreen(),
            '/pos': (context) => const PosScreen(),
            '/dispatch': (context) => const DeliveryQueueScreen(),
            '/customer': (context) => const CustomerOrderScreen(),
            '/inventory': (context) => const InventoryScreen(),
          },
        );
      },
    );
  }
}