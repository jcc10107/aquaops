import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import 'chat_conversation_screen.dart';

const String _font = 'Plus Jakarta Sans';

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key});

  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  final MessagingService _messagingService = MessagingService();
  final FirestoreService _firestoreService = FirestoreService();

  String _filter = 'open'; // 'open' | 'unassigned' | 'mine' | 'resolved' | 'all'
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted) {
      setState(() => _currentUser = profile);
    }
  }

  void _showAssignAgentSheet(ChatConversationModel convo, List<UserModel> staffList) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Support Agent',
                      style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (staffList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No active staff members found.', style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ...staffList.map((staff) {
                    final isCurrent = convo.assignedStaffId == staff.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? AppColors.primarySky : AppColors.surfaceFrost,
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                          style: TextStyle(color: isCurrent ? Colors.white : AppColors.primarySky, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(staff.name, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(staff.role.name.toUpperCase(), style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                      trailing: isCurrent ? const Icon(Icons.check, color: AppColors.primarySky) : null,
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        await _messagingService.assignSupportAgent(
                          conversationId: convo.id,
                          staffId: staff.id,
                          staffName: staff.name,
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
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
            chip('open', 'Open Tickets'),
            const SizedBox(width: 8),
            chip('unassigned', 'Unassigned'),
            const SizedBox(width: 8),
            chip('mine', 'Assigned to Me'),
            const SizedBox(width: 8),
            chip('resolved', 'Resolved'),
            const SizedBox(width: 8),
            chip('all', 'All'),
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
                'Support Operations Desk',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Customer support tickets & live inquiries',
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

  Widget _buildSupportCard(ChatConversationModel convo, List<UserModel> staffList) {
    final unread = convo.staffOrRiderUnreadCount;
    final isUnassigned = convo.assignedStaffId == null || convo.assignedStaffId!.isEmpty;
    final isResolved = convo.status == ConversationStatus.resolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread > 0 ? AppColors.primarySky.withValues(alpha: 0.5) : AppColors.slate200,
          width: unread > 0 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatConversationScreen(conversation: convo),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                      child: const Icon(Icons.headset_mic_outlined, size: 18, color: AppColors.primarySky),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            convo.customerName,
                            style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          Text(
                            convo.supportTopic ?? 'Customer Inquiry',
                            style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        convo.status.displayName,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isResolved ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  convo.lastMessageText ?? 'No messages exchanged yet.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showAssignAgentSheet(convo, staffList),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              isUnassigned ? Icons.person_add_alt : Icons.badge_outlined,
                              size: 14,
                              color: isUnassigned ? const Color(0xFFD97706) : AppColors.slate600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isUnassigned ? 'Unassigned (Tap to assign)' : 'Assigned: ${convo.assignedStaffName}',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isUnassigned ? const Color(0xFFD97706) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(100)),
                        child: Text(
                          '$unread new',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUserId ?? '';
    final topInset = MediaQuery.of(context).padding.top;
    final role = _currentUser?.role ?? UserRole.staff;

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
                child: StreamBuilder<List<UserModel>>(
                  stream: _firestoreService.getTeamMembersStream(),
                  builder: (context, staffSnap) {
                    final staffList = staffSnap.data ?? const <UserModel>[];

                    return StreamBuilder<List<ChatConversationModel>>(
                      stream: _messagingService.watchConversations(userId: uid, role: role),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading support queue: ${snapshot.error}',
                                style: const TextStyle(color: AppColors.coralAlert)),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allSupport = snapshot.data!.where((c) => c.isSupport).toList();

                        final filtered = allSupport.where((c) {
                          if (_filter == 'open') return c.status == ConversationStatus.open;
                          if (_filter == 'unassigned') return c.assignedStaffId == null || c.assignedStaffId!.isEmpty;
                          if (_filter == 'mine') return c.assignedStaffId == uid;
                          if (_filter == 'resolved') return c.status == ConversationStatus.resolved;
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
                                    child: const Icon(Icons.support_agent, size: 26, color: AppColors.primarySky),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Support Tickets',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'There are currently no tickets matching your filter criteria.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
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
                            return _buildSupportCard(filtered[index], staffList);
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