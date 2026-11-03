import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/messaging/conversation_tile.dart';
import 'chat_conversation_screen.dart';

const String _font = 'Plus Jakarta Sans';

class RiderMessagesScreen extends StatefulWidget {
  const RiderMessagesScreen({super.key});

  @override
  State<RiderMessagesScreen> createState() => _RiderMessagesScreenState();
}

class _RiderMessagesScreenState extends State<RiderMessagesScreen> {
  final MessagingService _messagingService = MessagingService();
  String _filter = 'active'; // 'active' | 'completed' | 'all'

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
      child: Row(
        children: [
          chip('active', 'Active Orders'),
          const SizedBox(width: 8),
          chip('completed', 'Delivered (History)'),
          const SizedBox(width: 8),
          chip('all', 'All'),
        ],
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
                'Delivery Chats',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Customer communication for active deliveries',
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
                  stream: _messagingService.watchConversations(
                    userId: uid,
                    role: UserRole.rider,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading chats: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.coralAlert),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final all = snapshot.data!;
                    final filtered = all.where((c) {
                      if (_filter == 'active') return !c.isReadOnly;
                      if (_filter == 'completed') return c.isReadOnly;
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
                                child: const Icon(Icons.two_wheeler,
                                    size: 26, color: AppColors.primarySky),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Delivery Chats',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _filter == 'active'
                                    ? 'Chats with customers on your active routes will appear here.'
                                    : 'No completed delivery chat records found.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return ConversationTile(
                          conversation: c,
                          isCustomer: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatConversationScreen(conversation: c),
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
    );
  }
}