// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            )),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.backgroundDark,
            fontFamily: 'Inter',
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
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
