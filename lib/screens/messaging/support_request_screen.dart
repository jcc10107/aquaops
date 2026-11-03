import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import 'chat_conversation_screen.dart';

const String _font = 'Plus Jakarta Sans';

class SupportRequestScreen extends StatefulWidget {
  final String? preselectedOrderId;

  const SupportRequestScreen({super.key, this.preselectedOrderId});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _detailsCtrl = TextEditingController();

  String _selectedTopic = 'Refill Delivery Issue';
  String? _selectedOrderId;
  bool _isSubmitting = false;

  final List<String> _topics = const [
    'Refill Delivery Issue',
    'Payment & GCash Inquiries',
    'Container Swap / Deposit',
    'Damaged Container Return',
    'Account / Profile Help',
    'Other Inquiries',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOrderId = widget.preselectedOrderId;
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitSupportRequest() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    final details = _detailsCtrl.text.trim();
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you need assistance with.'),
          backgroundColor: AppColors.coralAlert,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProfile = await _firestoreService.getUser(uid);
      final customerName = userProfile?.name ?? 'Customer';

      final convo = await _messagingService.createOrReopenSupportConversation(
        customerId: uid,
        customerName: customerName,
        topic: _selectedTopic,
        orderId: _selectedOrderId,
      );

      await _messagingService.sendMessage(
        conversationId: convo.id,
        text: details,
        senderId: uid,
        senderName: customerName,
        senderRole: 'customer',
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(conversation: convo),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start support ticket: $e'),
          backgroundColor: AppColors.coralAlert,
        ),
      );
    }
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
                'Contact Aqua Ops Support',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Direct line to San Pablo station dispatch',
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
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final uid = AuthService().currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildHeader(topInset),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.headset_mic_outlined, size: 22, color: AppColors.primarySky),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Submit a support inquiry. Station staff will review and respond directly in your Messages tab.',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  color: Color(0xFF0369A1),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        '1. Select Inquiry Topic',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Non-deprecated Topic Selector
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          children: _topics.map((t) {
                            final isSelected = _selectedTopic == t;
                            return InkWell(
                              onTap: () => setState(() => _selectedTopic = t),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected ? Border.all(color: AppColors.primarySky) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: isSelected ? AppColors.primarySky : AppColors.slate400,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppColors.primarySky : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        '2. Link a Recent Order (Optional)',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<OrderModel>>(
                        stream: _firestoreService.getOrdersForCustomerStream(uid),
                        builder: (context, snapshot) {
                          final orders = snapshot.data ?? const <OrderModel>[];
                          if (orders.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                value: _selectedOrderId,
                                hint: const Text('Select related delivery...', style: TextStyle(fontFamily: _font, fontSize: 13)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('No specific order', style: TextStyle(fontFamily: _font, fontSize: 13))),
                                  ...orders.map((o) => DropdownMenuItem(
                                    value: o.id,
                                    child: Text(
                                      '#${o.orderNumber} • ₱${o.totalAmount.toStringAsFixed(2)} (${o.status.name})',
                                      style: const TextStyle(fontFamily: _font, fontSize: 13),
                                    ),
                                  )),
                                ],
                                onChanged: (val) => setState(() => _selectedOrderId = val),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        '3. Describe Your Issue',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _detailsCtrl,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                        decoration: InputDecoration(
                          hintText: 'Please provide details about your inquiry or concern...',
                          hintStyle: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primarySky),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitSupportRequest,
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Starting Support Chat...' : 'Start Support Chat',
                            style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}