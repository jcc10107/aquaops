import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_conversation_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/messaging/chat_message_bubble.dart';
import 'delivery_quick_replies.dart';
import 'message_composer.dart';

const String _font = 'Plus Jakarta Sans';

class ChatConversationScreen extends StatefulWidget {
  final ChatConversationModel conversation;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final MessagingService _messagingService = MessagingService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  String? _currentUserName;
  UserRole _currentUserRole = UserRole.customer;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _markRead();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted && profile != null) {
      setState(() {
        _currentUserName = profile.name;
        _currentUserRole = profile.role;
      });
    }
  }

  void _markRead() {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    final isCustomer = widget.conversation.customerId == uid;
    _messagingService.markConversationAsRead(
      conversationId: widget.conversation.id,
      isCustomer: isCustomer,
    );
  }

  Future<void> _handleSend() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = AuthService().currentUserId;
    if (uid == null) return;

    setState(() => _isSending = true);
    _textCtrl.clear();

    try {
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        text: text,
        senderId: uid,
        senderName: _currentUserName ?? 'User',
        senderRole: _currentUserRole.name,
      );
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('StateError: ', '')),
          backgroundColor: AppColors.coralAlert,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildHeader(double topInset) {
    final isDelivery = widget.conversation.isDelivery;
    final title = isDelivery
        ? (widget.conversation.assignedRiderName ?? 'Assigned Rider')
        : (widget.conversation.supportTopic ?? 'Aqua Ops Support');

    final subtitle = isDelivery
        ? (widget.conversation.orderId != null
        ? 'Order #${widget.conversation.orderId}'
        : 'Delivery')
        : 'Station Dispatch Desk';

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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDelivery ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivery ? Icons.two_wheeler : Icons.headset_mic_outlined,
              size: 20,
              color: isDelivery ? AppColors.primarySky : const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.conversation.isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Archived',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final currentUserId = AuthService().currentUserId ?? '';
    final isReadOnly = widget.conversation.isReadOnly;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // Standard #F8FAFC
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
          child: Column(
            children: [
              _buildHeader(topInset),
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: _messagingService.watchMessages(widget.conversation.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.coralAlert),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUserId;
                        return ChatMessageBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
              ),
              if (!isReadOnly && widget.conversation.isDelivery)
                DeliveryQuickReplies(
                  onSelect: (reply) {
                    _textCtrl.text = reply;
                  },
                ),
              MessageComposer(
                controller: _textCtrl,
                isReadOnly: isReadOnly,
                isSending: _isSending,
                onSend: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}