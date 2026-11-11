import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'firebase_options.dart';
import 'models/order_model.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/customer/customer_map_screen.dart';
import 'screens/delivery/fulfill_delivery_screen.dart';
import 'screens/main_shell.dart';
import 'screens/messaging/chat_conversation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/refund/owner_request_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';
import 'services/offline_queue_service.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<String> currentUserRoleNotifier = ValueNotifier('none');
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  _wireNotificationTapRouting();

  runApp(const AquaOpsApp());
}

// Opens the relevant screen when the user taps a push notification —
// covers both "app was backgrounded, tap brings it to the foreground"
// (onMessageOpenedApp) and "app was fully closed, tap launches it"
// (getInitialMessage, checked once at startup).
void _wireNotificationTapRouting() {
  Future<void> handleTap(RemoteMessage message) async {
    final data = message.data;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final conversationId = data['conversationId'] as String?;
    if (conversationId != null) {
      final conversation = await MessagingService().getConversationOnce(conversationId);
      if (conversation != null) {
        nav.push(MaterialPageRoute(builder: (_) => ChatConversationScreen(conversation: conversation)));
      }
      return;
    }

    final role = UserRole.fromString(currentUserRoleNotifier.value);
    final fs = FirestoreService();

    final orderId = data['orderId'] as String?;
    if (orderId != null) {
      final order = await fs.getOrderOnce(orderId);
      if (order == null) return;
      final orderActive = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
      switch (role) {
        case UserRole.rider:
          if (orderActive && order.assignedRiderId == AuthService().currentUserId) {
            nav.push(MaterialPageRoute(builder: (_) => FulfillDeliveryScreen(order: order)));
          } else {
            nav.push(MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)));
          }
          break;
        case UserRole.owner:
        case UserRole.staff:
          nav.push(MaterialPageRoute(builder: (_) => shellAt(ShellTab.queue)));
          break;
        case UserRole.customer:
          if (order.status == OrderStatus.outForDelivery) {
            nav.push(MaterialPageRoute(builder: (_) => CustomerMapScreen(order: order)));
          } else {
            nav.push(MaterialPageRoute(builder: (_) => const CustomerMainScreen(initialTab: 1)));
          }
          break;
      }
      return;
    }

    final refundId = data['refundId'] as String?;
    if (refundId != null) {
      switch (role) {
        case UserRole.owner:
        case UserRole.staff:
          nav.push(MaterialPageRoute(builder: (_) => const OwnerRequestScreen()));
          break;
        case UserRole.customer:
          nav.push(MaterialPageRoute(builder: (_) => const CustomerMainScreen(initialTab: 1)));
          break;
        case UserRole.rider:
          break;
      }
      return;
    }

    // Cash-out and emergency-transfer review both live inside the dispatch
    // queue (delivery_queue_screen.dart), reachable via the shell's queue tab.
    final cashOutId = data['cashOutId'] as String?;
    final emergencyRequestId = data['emergencyRequestId'] as String?;
    if (cashOutId != null || emergencyRequestId != null) {
      switch (role) {
        case UserRole.owner:
        case UserRole.staff:
        case UserRole.rider:
          nav.push(MaterialPageRoute(builder: (_) => shellAt(ShellTab.queue)));
          break;
        case UserRole.customer:
          break;
      }
    }
  }

  FirebaseMessaging.onMessageOpenedApp.listen(handleTap);
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) handleTap(message);
  });
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
    ShellTab.queue: 1,
    ShellTab.stock: 2,
    ShellTab.refund: 3,
    ShellTab.profile: 4,
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
          navigatorKey: navigatorKey,
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
          home: const _AuthGate(),
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

// Restores a session on app reload instead of forcing a fresh login every
// time — Firebase Auth already persists the session in the browser/device,
// but nothing previously consulted it; every reload landed on LoginScreen
// regardless of a still-valid sign-in. Routes straight to the correct
// role's shell when one exists, matching login_screen.dart's own role ->
// destination mapping.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceBackground,
            body: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return _RestoredSessionHome(uid: user.uid);
      },
    );
  }
}

class _RestoredSessionHome extends StatefulWidget {
  final String uid;
  const _RestoredSessionHome({required this.uid});

  @override
  State<_RestoredSessionHome> createState() => _RestoredSessionHomeState();
}

class _RestoredSessionHomeState extends State<_RestoredSessionHome> {
  late final Future<UserModel?> _profileFuture = FirestoreService().getUser(widget.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceBackground,
            body: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          // Auth session is valid but the Firestore profile is gone (e.g.
          // the account was deleted) — can't restore into anything, so
          // sign out and fall back to a fresh login.
          AuthService().signOut();
          return const LoginScreen();
        }

        currentUserRoleNotifier.value = profile.role.name;
        unawaited(AuthService().ensurePushRegistered(widget.uid));

        return switch (profile.role) {
          UserRole.owner => shellAt(ShellTab.dashboard),
          UserRole.staff => shellAt(ShellTab.pos),
          UserRole.rider => shellAt(ShellTab.queue),
          UserRole.customer => const CustomerMainScreen(),
        };
      },
    );
  }
}