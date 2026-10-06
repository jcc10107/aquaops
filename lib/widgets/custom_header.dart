import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'notification_bell.dart';

class CustomHeader extends StatelessWidget {
  final String hubName;
  final VoidCallback? onProfileTap;

  const CustomHeader({
    super.key,
    this.hubName = 'Sta Monica, San Pablo City',
    this.onProfileTap,
  });

  static const double contentHeight = 76;

  String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'U';
    final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<UserModel?>(
      stream: uid == null
          ? const Stream<UserModel?>.empty()
          : FirestoreService().getUserStream(uid),
      builder: (context, snapshot) {
        final String initials = _getInitials(snapshot.data?.name ?? 'User');
        return _buildHeader(context, isDark, initials);
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String initials) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: contentHeight + topInset,
              padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.85)
                    : AppColors.surfaceLowest.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.borderLight.withValues(alpha: 0.4),
                  ),
                ),
                boxShadow: isDark
                    ? const []
                    : const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        _buildLogo(),
                        const SizedBox(width: 12),
                        Flexible(child: _buildTitleBlock(isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NotificationBell(isDark: isDark),
                      const SizedBox(width: 8),
                      _buildAvatar(initials),
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

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          'https://lh3.googleusercontent.com/aida/AEtjO1Vas2R0e1buuUvrIGqWLEEG0V0H59JlDQkO7FLkBmQzzjU6g26vP8Vv7gwG-zwqNkOL5Vt1aieuZmY-keD-332BDvKo4Z8ch1r2Z7W3pz6ghvbkWPY-sQm-2ontpVO2Z0b9NvfhmBnHq1jLSXB2mnbFWuM3sUEcZ_TJ5j4mVJ5lkfDlfHOyIawrb8SIKfLdFmrE0s7ClNCu5B6QaR2lQJbjdb5uK7kB164Ivpb7blvt0VqnGXTiGtHdeq0',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 44,
            height: 44,
            color: const Color(0xFF0284C7),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBlock(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textMain,
                ),
                children: const [
                  TextSpan(text: 'Aqua'),
                  TextSpan(
                    text: 'Ops',
                    style: TextStyle(color: Color(0xFF0077B6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFA5F3FC).withValues(alpha: 0.6),
                ),
              ),
              child: const Text(
                'HQ',
                style: TextStyle(
                  color: Color(0xFF00689C),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hubName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(String initials) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onProfileTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7), // Matches login screen primary color
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}