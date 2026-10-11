import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../main.dart';
import '../screens/notifications/notification_screen.dart';
import 'notification_feed.dart';

class NotificationBell extends StatelessWidget {
  final bool isDark;
  const NotificationBell({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final NotificationReadStore store = NotificationReadStore.instance;

    return ValueListenableBuilder<String>(
      valueListenable: currentUserRoleNotifier,
      builder: (context, rawRole, _) {
        final String role = normalizeNotificationRole(rawRole);
        if (uid != null) store.ensureLoaded(uid);

        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return NotificationFeed(
              role: role,
              uid: uid,
              builder: (context, items, loading, error) {
                final int unread = (uid != null && store.isLoadedFor(uid)) ? items.where((n) => !store.isRead(n.id)).length : 0;
                return _buildBell(context, unread);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBell(BuildContext context, int unread) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                },
                child: Center(
                  child: Icon(
                    Icons.notifications_none,
                    color: isDark ? Colors.grey[300] : AppColors.textVariant,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.coralAlert, Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}