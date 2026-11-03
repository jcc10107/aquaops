import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../screens/messaging/messages_inbox_screen.dart';
import '../../services/auth_service.dart';
import '../../services/messaging_service.dart';

class MessagesButton extends StatelessWidget {
  final bool isDark;

  const MessagesButton({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService().currentUserId;
    if (uid == null) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: currentUserRoleNotifier,
      builder: (context, rawRole, _) {
        final role = UserRole.fromString(rawRole);

        return StreamBuilder<int>(
          stream: MessagingService().watchUnreadConversationsCount(
            userId: uid,
            role: role,
          ),
          builder: (context, snapshot) {
            final int unreadCount = snapshot.data ?? 0;

            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.slate200,
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
                            MaterialPageRoute(
                              builder: (context) => const MessagesInboxScreen(),
                            ),
                          );
                        },
                        child: Center(
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySky,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}