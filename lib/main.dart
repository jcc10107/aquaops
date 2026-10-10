import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile/profile_screen.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<String> currentUserRoleNotifier = ValueNotifier('none');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  }

  runApp(const AquaOpsApp());
}

enum ShellTab { dashboard, pos, queue, stock, refund, profile }

Widget shellAt(ShellTab tab) {
  final String role = currentUserRoleNotifier.value;
  int index = 0;
  if (role == 'owner') {
    switch (tab) {
      case ShellTab.dashboard:
        index = 0;
        break;
      case ShellTab.pos:
        index = 1;
        break;
      case ShellTab.queue:
        index = 2;
        break;
      case ShellTab.stock:
        index = 3;
        break;
      case ShellTab.refund:
        index = 4;
        break;
      case ShellTab.profile:
        index = 5;
        break;
    }
  } else if (role == 'staff') {
    switch (tab) {
      case ShellTab.stock:
        index = 1;
        break;
      case ShellTab.profile:
        index = 2;
        break;
      default:
        index = 0;
        break;
    }
  } else if (role == 'rider') {
    switch (tab) {
      case ShellTab.profile:
        index = 1;
        break;
      default:
        index = 0;
        break;
    }
  } else {
    switch (tab) {
      case ShellTab.profile:
        index = 2;
        break;
      default:
        index = 0;
        break;
    }
  }
  return MainShell(initialIndex: index);
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
            fontFamily: 'Plus Jakarta Sans',
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.backgroundDark,
            fontFamily: 'Plus Jakarta Sans',
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/profile': (context) =>
            currentUserRoleNotifier.value == 'customer'
                ? const Scaffold(
              backgroundColor: AppColors.surfaceCanvas,
              body: SafeArea(child: ProfileScreen()),
            )
                : shellAt(ShellTab.profile),
            '/owner_dashboard': (context) => shellAt(ShellTab.dashboard),
            '/pos': (context) => shellAt(ShellTab.pos),
            '/dispatch': (context) => shellAt(ShellTab.queue),
            '/inventory': (context) => shellAt(ShellTab.stock),
            '/owner_refund': (context) => shellAt(ShellTab.refund),
            '/customer': (context) => const CustomerMainScreen(),
          },
        );
      },
    );
  }
}