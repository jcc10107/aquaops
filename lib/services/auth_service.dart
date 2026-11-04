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

// Web Push certificate key from Firebase Console. Required on web only.
const String fcmVapidKey =
    'BF_KZ5ez3lP1Ca4RsO0kdiOqwLTyQI0TYAZSxM8m3sUuSlnDk_Qej62mQGEdclEVMFG3KRrHUf85tCvsJ85Mt2U';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  static bool _foregroundListenerRegistered = false;
  static bool _tokenRefreshListenerRegistered = false;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address entered is not valid.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
        case 'email-already-in-use':
          return 'An account with this email address already exists.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled for this project.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'requires-recent-login':
          return 'Please log out and log in again before making this update.';
        default:
          return error.message ?? 'An authentication error occurred (${error.code}).';
      }
    }
    return error?.toString() ?? 'An unexpected authentication error occurred.';
  }

  Future<void> _registerForPushNotifications(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = kIsWeb
          ? await messaging.getToken(vapidKey: fcmVapidKey)
          : await messaging.getToken();
      if (token != null) {
        await _firestore.saveFcmToken(uid, token);
      }

      if (!_foregroundListenerRegistered) {
        _foregroundListenerRegistered = true;
        FirebaseMessaging.onMessage.listen((message) {
          final title = message.notification?.title ?? 'AquaOps';
          final body = message.notification?.body ?? '';
          showWebNotification(title, body);
        });
      }

      if (!_tokenRefreshListenerRegistered) {
        _tokenRefreshListenerRegistered = true;
        // FCM can rotate a device's token at any time (not just at sign-in)
        // — without this, a rotated token silently stops receiving pushes
        // until the next full sign-in. Always save to whoever is CURRENTLY
        // signed in, not the uid this particular sign-in started with.
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          final currentUid = _auth.currentUser?.uid;
          if (currentUid == null) return;
          _firestore.saveFcmToken(currentUid, newToken).catchError((e, st) {
            debugPrint('[FCM] token refresh save error: $e\n$st');
          });
        });
      }
    } catch (e, st) {
      debugPrint('[FCM] registration error: $e\n$st');
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      final profile = await _firestore.getUser(credential.user!.uid);
      if (profile == null) {
        await _auth.signOut();
        return null;
      }
      unawaited(_registerForPushNotifications(credential.user!.uid));
      return profile;
    }
    return null;
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
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email.trim(),
      role: role,
      phone: phone,
      address: address,
      hasOwnContainers: hasOwnContainers,
    );

    await _firestore.createUser(user);
    unawaited(_registerForPushNotifications(uid));
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await sendPasswordReset(email);
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
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      final user = UserModel(
        id: uid,
        name: name,
        email: email.trim(),
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

String getAuthErrorMessage(dynamic error) =>
    AuthService.getAuthErrorMessage(error);