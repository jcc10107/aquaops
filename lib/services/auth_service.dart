import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification_web.dart';

// Web Push certificate key, from Firebase Console > Project Settings >
// Cloud Messaging > Web configuration > Web Push certificates. Needed only
// on web — getToken() ignores it on Android/iOS.
const String fcmVapidKey = 'BF_KZ5ez3lP1Ca4RsO0kdiOqwLTyQI0TYAZSxM8m3sUuSlnDk_Qej62mQGEdclEVMFG3KRrHUf85tCvsJ85Mt2U';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool _foregroundListenerRegistered = false;

  // Asks for notification permission and saves this device's FCM token to
  // the user's profile. Never blocks login on failure (permission denied,
  // unsupported browser, etc. are all fine — the app just won't get pushes).
  Future<void> _registerForPushNotifications(String uid) async {
    try {
      debugPrint('[FCM] requesting permission...');
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      debugPrint('[FCM] permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[FCM] permission not granted, stopping.');
        return;
      }
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: fcmVapidKey)
          : await messaging.getToken();
      debugPrint('[FCM] token: $token');
      if (token != null) {
        await _firestore.saveFcmToken(uid, token);
        debugPrint('[FCM] token saved to Firestore.');
      }

      // A message that arrives while the tab is focused never reaches the
      // service worker (that only fires when the tab is backgrounded or
      // closed) — this is the only way to surface it when the tab is open.
      if (!_foregroundListenerRegistered) {
        _foregroundListenerRegistered = true;
        debugPrint('[FCM] registering onMessage listener.');
        FirebaseMessaging.onMessage.listen((message) {
          debugPrint('[FCM] onMessage fired: ${message.notification?.title} / ${message.notification?.body}');
          final title = message.notification?.title ?? 'AquaOps';
          final body = message.notification?.body ?? '';
          showWebNotification(title, body);
          debugPrint('[FCM] showWebNotification called.');
        });
      } else {
        debugPrint('[FCM] onMessage listener already registered.');
      }
    } catch (e, st) {
      debugPrint('[FCM] registration error: $e\n$st');
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final profile = await _firestore.getUser(credential.user!.uid);
        if (profile == null) {
          // Their Firestore profile is gone (e.g. removed from the team) —
          // don't leave them signed in at the Auth level with nowhere to go.
          await _auth.signOut();
          return null;
        }
        unawaited(_registerForPushNotifications(credential.user!.uid));
        return profile;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error Code: ${e.code}');
      debugPrint('Firebase Auth Error Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('General Error: $e');
      rethrow;
    }
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
    UserRole role = UserRole.customer,
    bool? hasOwnContainers,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      role: role,
      phone: phone,
      address: address,
      hasOwnContainers: hasOwnContainers,
    );

    await _firestore.createUser(user);
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel> createTeamAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? assignedArea,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'accountCreation-${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        role: role,
        phone: phone,
        assignedArea: assignedArea,
      );
      await _firestore.createUser(user);
      return user;
    } finally {
      await secondaryApp.delete();
    }
  }
}