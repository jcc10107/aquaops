import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../owner/owner_settings_screen.dart';
import 'change_password_screen.dart';
import 'help_center_screen.dart';
import 'manage_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'terms_privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  static const String _font = 'Plus Jakarta Sans';

  String _getSingleInitial(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  String _badgeForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'STATION OWNER';
      case UserRole.staff:
        return 'STATION STAFF';
      case UserRole.rider:
        return 'DISPATCH RIDER';
      case UserRole.customer:
        return 'ACTIVE SUBSCRIBER';
    }
  }

  Map<String, String> _userDataFromModel(UserModel user) {
    return {
      'name': user.name.isEmpty ? 'User' : user.name,
      'email': user.email,
      'phone': user.phone,
      'badge': _badgeForRole(user.role),
      'initials': _getSingleInitial(user.name),
    };
  }

  void _openManageProfile(UserModel user, Map<String, String> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageProfileScreen(user: user, userData: userData),
      ),
    );
  }

  void _openSavedAddresses() {
    final uid = _authService.currentUserId;
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SavedAddressesScreen(uid: uid)),
    );
  }

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  void _openHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
    );
  }

  // Temporary diagnostic tool — walks through FCM permission + token
  // retrieval + Firestore save step by step and shows exactly where it
  // fails, since a silent failure in any of those three steps is
  // otherwise invisible (no console access on a release web build).
  Future<void> _checkNotificationSetup() async {
    final buffer = StringBuffer();
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      buffer.writeln('1. Permission: ${settings.authorizationStatus.name}');

      String? token;
      try {
        token = await messaging.getToken(vapidKey: fcmVapidKey);
        buffer.writeln('2. Token: ${token == null ? 'NULL (no error, but no token)' : '${token.substring(0, token.length.clamp(0, 24))}...'}');
      } catch (e) {
        buffer.writeln('2. Token FAILED: $e');
      }

      final uid = _authService.currentUserId;
      buffer.writeln('3. Current UID: ${uid ?? 'NULL (not signed in?)'}');

      if (uid != null && token != null) {
        try {
          await _firestoreService.saveFcmToken(uid, token);
          buffer.writeln('4. Saved to Firestore: YES');
        } catch (e) {
          buffer.writeln('4. Save FAILED: $e');
        }
      } else {
        buffer.writeln('4. Save SKIPPED (missing uid or token above)');
      }
    } catch (e) {
      buffer.writeln('Unexpected error: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notification Diagnostic'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
    );
  }

  void _openOwnerSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerSettingsScreen()),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 360,
          child: Dialog(
            backgroundColor: AppColors.surfaceCanvas,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.coralAlert, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text('Delete Account', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 6),
                  const Text('Are you sure you want to permanently delete your account? This action cannot be undone.', textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _signOutAndGoToLogin(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coralAlert,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Delete', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOutAndGoToLogin(BuildContext context) async {
    await _authService.signOut();
    currentUserRoleNotifier.value = 'none';
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = UserRole.fromString(currentUserRoleNotifier.value);
    final uid = _authService.currentUserId;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<UserModel?>(
      stream: uid == null ? const Stream.empty() : _firestoreService.getUserStream(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userData = user == null
            ? _userDataFromModel(UserModel(id: '', name: '', email: '', role: UserRole.customer, phone: ''))
            : _userDataFromModel(user);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 20, 16, 120 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clean, Simplified Hero Profile Card
                  _buildProfileHero(userData),
                  const SizedBox(height: 20),

                  // Dedicated Owner Settings Hub Entry Card
                  if (currentRole == UserRole.owner) ...[
                    _buildOwnerSettingsBanner(),
                    const SizedBox(height: 20),
                  ],

                  // 1. Account Settings
                  _buildSectionHeader('Account Settings', 'Personal Details'),
                  const SizedBox(height: 8),
                  _buildCardGroup([
                    _buildListTile(
                      'Manage Profile',
                      'Name, email & contact phone',
                      Icons.person_outline,
                      AppColors.primarySky,
                      onTap: user == null ? null : () => _openManageProfile(user, userData),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      'Change Password',
                      'Update account credentials & security',
                      Icons.lock_outline,
                      AppColors.primarySky,
                      onTap: _openChangePassword,
                    ),
                    if (currentRole == UserRole.customer) ...[
                      _buildDivider(),
                      _buildListTile(
                        'Saved Delivery Addresses',
                        'Delivery locations, notes, and default drop-off',
                        Icons.location_on_outlined,
                        AppColors.primarySky,
                        onTap: _openSavedAddresses,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // 2. Preferences
                  _buildSectionHeader('Preferences', 'Alerts'),
                  const SizedBox(height: 8),
                  _buildCardGroup([
                    _buildListTile(
                      'Notification Alerts',
                      'Delivery status alerts & system reminders',
                      Icons.notifications_active_outlined,
                      AppColors.primarySky,
                      trailing: _buildSwitchTile(
                        value: user?.notificationsEnabled ?? true,
                        onTap: user == null
                            ? null
                            : () => _firestoreService.setNotificationsEnabled(user.id, !(user.notificationsEnabled)),
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      'Check Notification Setup',
                      'Diagnose why push notifications may not be arriving',
                      Icons.troubleshoot_outlined,
                      AppColors.primarySky,
                      onTap: _checkNotificationSetup,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // 3. Support & Policies
                  _buildSectionHeader('Support & Legal', 'Guidelines'),
                  const SizedBox(height: 8),
                  _buildCardGroup([
                    _buildListTile(
                      'Help Center & FAQs',
                      'Guides, operations, and support contact',
                      Icons.support_agent_outlined,
                      AppColors.primarySky,
                      onTap: _openHelpCenter,
                    ),
                    _buildDivider(),
                    _buildListTile(
                      'Terms & Privacy',
                      'Station policies & data guidelines',
                      Icons.shield_outlined,
                      AppColors.primarySky,
                      onTap: _openTerms,
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Session Logout
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      foregroundColor: AppColors.coralAlert,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                      ),
                    ),
                    onPressed: () => _signOutAndGoToLogin(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.coralAlert),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.coralAlert,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Customer-Only Account Deletion
                  if (currentRole == UserRole.customer) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => _showDeleteAccountDialog(isDark),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'STA MONICA SAN PABLO CITY • PURE HYDRATION',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.slate400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHero(Map<String, String> userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              ),
            ),
            child: Center(
              child: Text(
                userData['initials']!,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userData['name']!,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userData['email']!,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              userData['badge']!.toUpperCase(),
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSettingsBanner() {
    return InkWell(
      onTap: _openOwnerSettings,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primarySky, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x0A0284C7), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primarySky, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Settings',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage team, coverage, branches, payments & pricing',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: AppColors.primarySky),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(
      String title,
      String subtitle,
      IconData icon,
      Color iconColor, {
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: trailing != null ? 12 : 8),
            trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: AppColors.slate100);

  Widget _buildSwitchTile({required bool value, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: value ? AppColors.primarySky : AppColors.slate300,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: value ? const Icon(Icons.check, size: 13, color: AppColors.primarySky) : null,
          ),
        ),
      ),
    );
  }
}