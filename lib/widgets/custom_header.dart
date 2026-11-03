import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../screens/profile/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'messaging/messages_button.dart';
import 'notification_bell.dart';

class CustomHeader extends StatefulWidget implements PreferredSizeWidget {
  final String hubName;
  final VoidCallback? onProfileTap;

  const CustomHeader({
    super.key,
    this.hubName = 'Sta Monica, San Pablo City',
    this.onProfileTap,
  });

  static const double contentHeight = 76;

  @override
  Size get preferredSize => const Size.fromHeight(contentHeight);

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  late final Stream<UserModel?> _userStream;

  @override
  void initState() {
    super.initState();
    final String? uid = AuthService().currentUserId;
    _userStream = uid == null
        ? const Stream<UserModel?>.empty()
        : FirestoreService().getUserStream(uid);
  }

  void _navigateToProfile(BuildContext context) {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    }
  }

  String _getSingleInitial(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        final String initial = _getSingleInitial(snapshot.data?.name);
        return _buildHeader(context, isDark, initial);
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String initial) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: CustomHeader.contentHeight + topInset,
              padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate200,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildWordmarkAndLocation(isDark),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Real-time Chat Messages Button
                      MessagesButton(isDark: isDark),
                      const SizedBox(width: 8),
                      // Notifications Bell
                      NotificationBell(isDark: isDark),
                      const SizedBox(width: 10),
                      // Profile Avatar
                      _buildAvatar(context, isDark, initial),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordmarkAndLocation(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.textLight,
            ),
            children: const [
              TextSpan(text: 'Aqua'),
              TextSpan(
                text: 'Ops',
                style: TextStyle(color: AppColors.primarySky),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: AppColors.primarySky,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.hubName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDark, String initial) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _navigateToProfile(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceFrost,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.slate200,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primarySky,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}