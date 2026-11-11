import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_conversation_model.dart';

const String _font = 'Plus Jakarta Sans';

class ConversationTile extends StatelessWidget {
  final ChatConversationModel conversation;
  final bool isCustomer;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isCustomer,
    required this.onTap,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${dt.month}/${dt.day}';
    }
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final unread = isCustomer
        ? conversation.customerUnreadCount
        : conversation.staffOrRiderUnreadCount;
    final isDelivery = conversation.isDelivery;

    // Show whoever the VIEWER isn't — a customer wants to see their
    // rider's name, while a rider/staff viewing the same delivery chat
    // needs to see the customer's name, not their own.
    final title = isDelivery
        ? (isCustomer ? (conversation.assignedRiderName ?? 'Delivery Rider') : conversation.customerName)
        : (conversation.supportTopic ?? 'Support Request');

    final subtitle = conversation.lastMessageText ?? 'No messages yet';
    final timeStr = _formatTime(conversation.lastMessageAt ?? conversation.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: unread > 0 ? Colors.white : const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread > 0 ? AppColors.primarySky.withValues(alpha: 0.5) : AppColors.slate200,
          width: unread > 0 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDelivery ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDelivery ? Icons.two_wheeler : Icons.headset_mic_outlined,
                    size: 22,
                    color: isDelivery ? AppColors.primarySky : const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 11,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
                              color: unread > 0 ? AppColors.primarySky : AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 12,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                color: unread > 0 ? AppColors.textLight : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySky,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}