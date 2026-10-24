import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile/profile_screen.dart';
import 'services/offline_queue_service.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<String> currentUserRoleNotifier = ValueNotifier('none');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await OfflineQueueService().init();

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  }

  runApp(const AquaOpsApp());
}

enum ShellTab { dashboard, pos, queue, stock, refund, profile }

const Map<String, Map<ShellTab, int>> _roleTabMapping = {
  'owner': {
    ShellTab.dashboard: 0,
    ShellTab.pos: 1,
    ShellTab.queue: 2,
    ShellTab.stock: 3,
    ShellTab.refund: 4,
    ShellTab.profile: 5,
  },
  'staff': {
    ShellTab.pos: 0,
    ShellTab.stock: 1,
    ShellTab.profile: 2,
  },
  'rider': {
    ShellTab.queue: 0,
    ShellTab.profile: 1,
  },
};

Widget shellAt(ShellTab tab) {
  final String role = currentUserRoleNotifier.value;
  final roleMap = _roleTabMapping[role] ?? {ShellTab.profile: 2};
  final index = roleMap[tab] ?? 0;
  return MainShell(initialIndex: index);
}

class AquaOpsApp extends StatelessWidget {
  const AquaOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
        return MaterialApp(
          title: 'AquaOps',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // TASK 7.4: Standardize global Plus Jakarta Sans typography across textTheme
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
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
            '/signup': (context) => const SignupScreen(),
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