import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/chat_conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/messaging/conversation_tile.dart';
import 'chat_conversation_screen.dart';

const String _font = 'Plus Jakarta Sans';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final MessagingService _messagingService = MessagingService();
  final FirestoreService _firestoreService = FirestoreService();

  String _filter = 'all'; // 'all' | 'delivery' | 'support' | 'unread'

  void _showNewSupportDialog(BuildContext context, String uid) {
    final topicCtrl = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCanvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.headset_mic_outlined, color: AppColors.primarySky, size: 22),
              SizedBox(width: 8),
              Text(
                'Contact Support',
                style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What do you need assistance with?',
                style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicCtrl,
                style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'e.g., Damaged Container, Refill Inquiry...',
                  hintStyle: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                final topic = topicCtrl.text.trim();
                if (topic.isEmpty) return;

                setDialogState(() => isCreating = true);
                try {
                  final profile = await _firestoreService.getUser(uid);
                  final convo = await _messagingService.createOrReopenSupportConversation(
                    customerId: uid,
                    customerName: profile?.name ?? 'Customer',
                    topic: topic,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatConversationScreen(conversation: convo),
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isCreating = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String key, String label) {
      final isSelected = _filter == key;
      return InkWell(
        onTap: () => setState(() => _filter = key),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySky : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isSelected ? AppColors.primarySky : AppColors.slate200),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.slate600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('all', 'All'),
            const SizedBox(width: 8),
            chip('delivery', 'Deliveries'),
            const SizedBox(width: 8),
            chip('support', 'Support'),
            const SizedBox(width: 8),
            chip('unread', 'Unread'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topInset) {
    return Container(
      height: 64 + topInset,
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCanvas,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Delivery updates and station support',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUserId ?? '';
    final topInset = MediaQuery.of(context).padding.top;
    final role = UserRole.fromString(currentUserRoleNotifier.value);
    final isCustomer = role == UserRole.customer;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
          child: Column(
            children: [
              _buildHeader(topInset),
              _buildFilterChips(),
              Expanded(
                child: StreamBuilder<List<ChatConversationModel>>(
                  stream: _messagingService.watchConversations(userId: uid, role: role),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.coralAlert)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final all = snapshot.data!;
                    final filtered = all.where((c) {
                      if (_filter == 'delivery') return c.isDelivery;
                      if (_filter == 'support') return c.isSupport;
                      if (_filter == 'unread') {
                        final unread = isCustomer ? c.customerUnreadCount : c.staffOrRiderUnreadCount;
                        return unread > 0;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F2FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline,
                                    size: 26, color: AppColors.primarySky),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Messages Yet',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Chats with your delivery rider and station support will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return ConversationTile(
                          conversation: c,
                          isCustomer: isCustomer,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatConversationScreen(conversation: c),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isCustomer
          ? FloatingActionButton.extended(
        onPressed: () => _showNewSupportDialog(context, uid),
        backgroundColor: AppColors.primarySky,
        elevation: 2,
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text('Contact Support',
            style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.bold)),
      )
          : null,
    );
  }
}