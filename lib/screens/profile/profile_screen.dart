import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../owner/manage_team_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'manage_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'change_password_screen.dart';
import 'help_center_screen.dart';
import 'terms_privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const String _font = 'Plus Jakarta Sans';
  static const Color _surface = Color(0xFFF6FAFC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _outline = Color(0xFF707881);
  static const Color _outlineVariant = Color(0xFFBFC7D2);
  static const Color _primaryBlue = Color(0xFF0284C7);
  static const Color _iconBg = Color(0xFFF0F9FF);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _onSecondaryContainer = Color(0xFF00714D);
  static const Color _secondaryFixed = Color(0xFF6FFBBE);
  static const Color _containerHigh = Color(0xFFE2E7FF);
  static const Color _errorColor = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'U';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
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
      'initials': _getInitials(user.name),
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
    final uid = _uid;
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

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 360,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.2), blurRadius: 8)]),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textVariant, height: 1.4)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 14, color: AppColors.coralAlert),
                        SizedBox(width: 6),
                        Text('3 BOTTLE DEPOSITS WILL BE FORFEITED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textVariant, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(backgroundColor: AppColors.surfaceContainerLow, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _signOutAndGoToLogin(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shadowColor: AppColors.error.withValues(alpha: 0.5), elevation: 4, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.delete, size: 14, color: Colors.white),
                          label: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
    final role = currentUserRoleNotifier.value;
    final uid = _uid;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<UserModel?>(
      stream: uid == null ? const Stream.empty() : _firestoreService.getUserStream(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userData = user == null ? _userDataFromModel(UserModel(id: '', name: '', email: '', role: UserRole.customer, phone: '')) : _userDataFromModel(user);

        return Scaffold(
          backgroundColor: _surface,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 130 + bottomInset),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileHero(userData, isDark),
                              const SizedBox(height: 20),

                              _buildSectionHeader('Account Settings', 'Personal Details', _outlineVariant, false),
                              const SizedBox(height: 8),
                              _buildCardGroup([
                                _buildListTile('Manage Profile', 'Name, email & contact number', Icons.person, _primaryBlue, isDark, onTap: user == null ? null : () => _openManageProfile(user, userData)),
                                _buildDivider(isDark),
                                _buildListTile('Saved Delivery Addresses', 'Delivery locations & notes', Icons.location_on, _primaryBlue, isDark, onTap: _openSavedAddresses),
                              ], isDark),
                              const SizedBox(height: 20),

                              if (role == 'owner') ...[
                                _buildSectionHeader('Station Operations', 'Owner Only', _primaryBlue, true),
                                const SizedBox(height: 8),
                                _buildCardGroup([
                                  _buildListTile('Manage Staff & Riders', 'Staff accounts & rider routes', Icons.groups, _primaryBlue, isDark, badge: '4 Active', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTeamScreen()))),
                                ], isDark),
                                const SizedBox(height: 20),
                              ],

                              _buildSectionHeader('Preferences', 'Customized', _outlineVariant, false),
                              const SizedBox(height: 8),
                              _buildCardGroup([
                                _buildListTile('Notification Settings', 'Delivery alerts & reminders', Icons.notifications_active, _primaryBlue, isDark, trailing: _buildCustomSwitch(user)),
                              ], isDark),
                              const SizedBox(height: 20),

                              _buildSectionHeader('Security & Access', 'Protected', _secondary, true),
                              const SizedBox(height: 8),
                              _buildCardGroup([
                                _buildListTile('Change Password', 'Login credentials & security', Icons.lock, _primaryBlue, isDark, onTap: _openChangePassword),
                              ], isDark),
                              const SizedBox(height: 20),

                              _buildSectionHeader('Support & Policies', '24/7 Available', _outlineVariant, false),
                              const SizedBox(height: 8),
                              _buildCardGroup([
                                _buildListTile('Help Center & FAQs', 'Guides & customer support', Icons.support_agent, _primaryBlue, isDark, onTap: _openHelpCenter),
                                _buildDivider(isDark),
                                _buildListTile('Terms & Privacy', 'Station policies & guidelines', Icons.shield, _primaryBlue, isDark, onTap: _openTerms),
                              ], isDark),
                              const SizedBox(height: 32),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _errorContainer.withValues(alpha: 0.6),
                                  foregroundColor: _errorColor,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 52),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => _signOutAndGoToLogin(context),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, size: 20, color: _errorColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 24 / 17,
                                        letterSpacing: -0.17,
                                        color: _errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (role == 'customer') ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () => _showDeleteAccountDialog(isDark),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _onSurfaceVariant,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete_forever, size: 18, color: _onSurfaceVariant),
                                        SizedBox(width: 6),
                                        Text(
                                          'Delete Account',
                                          style: TextStyle(
                                            fontFamily: _font,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            height: 14 / 11,
                                            letterSpacing: 0.22,
                                            color: _onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _containerHigh.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 6,
                                        height: 6,
                                        child: DecoratedBox(decoration: BoxDecoration(color: _secondary, shape: BoxShape.circle)),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Version 1.0.0 (Build 42)',
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          height: 12 / 10,
                                          letterSpacing: 0.6,
                                          color: _outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'STA MONICA SAN PABLO CITY • PURE HYDRATION',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 12 / 10,
                                    letterSpacing: 1.0,
                                    color: _outlineVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHero(Map<String, String> userData, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 25,
                  spreadRadius: -3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF00B4D8), Color(0xFF0284C7), Color(0xFF0369A1)],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                foregroundDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x1A000000), Color(0x00000000)],
                  ),
                ),
                child: Text(
                  userData['initials']!,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 28 / 22,
                    letterSpacing: -0.55,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userData['name']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 28 / 22,
              letterSpacing: -0.44,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userData['email']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 18 / 13,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _secondaryFixed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(decoration: BoxDecoration(color: _secondary, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 6),
                Text(
                  userData['badge']!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 12 / 10,
                    letterSpacing: 0.5,
                    color: _onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color subColor, bool bold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 12 / 10,
              letterSpacing: 0.6,
              color: _outline,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 10,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              height: 12 / 10,
              letterSpacing: 0.6,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, Color iconColor, bool isDark, {Widget? trailing, VoidCallback? onTap, String? badge}) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 22 / 15,
        color: _onSurface,
      ),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Row(
                      children: [
                        Flexible(child: titleText),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _secondaryFixed.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 12 / 10,
                              letterSpacing: 0.6,
                              color: _primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    titleText,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 16 / 11,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: trailing != null ? 12 : 8),
            trailing ?? const Icon(Icons.chevron_right, size: 20, color: _outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: _containerHigh,
  );

  Widget _buildCustomSwitch(UserModel? user) {
    final enabled = user?.notificationsEnabled ?? true;
    return GestureDetector(
      onTap: user == null ? null : () => _firestoreService.setNotificationsEnabled(user.id, !enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: enabled ? _primaryBlue : _outlineVariant.withValues(alpha: 0.6),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  spreadRadius: -1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: enabled ? const Icon(Icons.check, size: 13, color: _primaryBlue) : null,
          ),
        ),
      ),
    );
  }
}