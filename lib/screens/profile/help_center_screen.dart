import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/sub_screen_header.dart';
import '../messaging/support_request_screen.dart';

class _Faq {
  final String question;
  final String answer;
  final String keywords;

  const _Faq({
    required this.question,
    required this.answer,
    required this.keywords,
  });
}

class _HelpCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String filter;

  const _HelpCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.filter,
  });
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _openIndex;

  static const String _font = 'Plus Jakarta Sans';

  static final List<_HelpCategory> _categories = [
    const _HelpCategory(
      title: 'Refills',
      subtitle: 'Orders & timing',
      icon: Icons.water_drop_outlined,
      background: Color(0xFFE0F2FE),
      foreground: AppColors.primarySky,
      filter: 'refill',
    ),
    const _HelpCategory(
      title: 'Bottle Swap',
      subtitle: 'Deposit rules',
      icon: Icons.sync_alt,
      background: Color(0xFFECFDF5),
      foreground: Color(0xFF059669),
      filter: 'swap',
    ),
    const _HelpCategory(
      title: 'Delivery',
      subtitle: 'Routes & zones',
      icon: Icons.local_shipping_outlined,
      background: Color(0xFFF0F9FF),
      foreground: Color(0xFF0284C7),
      filter: 'delivery',
    ),
    const _HelpCategory(
      title: 'GCash / Pay',
      subtitle: 'Payment help',
      icon: Icons.account_balance_wallet_outlined,
      background: Color(0xFFFFFBEB),
      foreground: Color(0xFFD97706),
      filter: 'gcash',
    ),
  ];

  static const List<_Faq> _faqs = [
    _Faq(
      question: 'How does the empty gallon container swap work?',
      answer:
      'Leave your clean, undamaged Drink 8 empty container at your doorstep or hand it to our dispatch rider upon delivery to avoid new bottle deposit fees.',
      keywords: 'empty gallon container swap bottle deposit clean undamaged doorstep rider',
    ),
    _Faq(
      question: 'What are your delivery hours in San Pablo City?',
      answer:
      'Our riders operate Monday to Saturday from 7:00 AM to 5:30 PM across covered barangays including San Isidro and San Antonio.',
      keywords: 'delivery hours san pablo city timing barangay monday saturday isidro antonio',
    ),
    _Faq(
      question: 'How do I verify GCash payments?',
      answer:
      'Input your GCash 13-digit reference number upon ordering or upload your transaction screenshot directly in Checkout or to the rider.',
      keywords: 'verify gcash payments 13-digit reference number upload receipt screenshot checkout rider',
    ),
    _Faq(
      question: 'What if my delivery is delayed due to weather?',
      answer:
      'In case of heavy rains or localized flooding, order status updates will be broadcast directly via push alerts and SMS.',
      keywords: 'delivery delay delayed heavy rain weather flooding push alerts broadcast sms status',
    ),
    _Faq(
      question: 'Can I request an emergency refill?',
      answer:
      "Yes! Contact the station dispatch hotline or select 'Priority Queue' during ordering if available.",
      keywords: 'request emergency refill priority queue urgent fast hotline dispatch call',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    setState(() => _query = value);
  }

  void _clearSearch() {
    _searchController.clear();
    _setQuery('');
  }

  void _filterCategory(String filter) {
    _searchController.value = TextEditingValue(
      text: filter,
      selection: TextSelection.collapsed(offset: filter.length),
    );
    _setQuery(filter);
  }

  void _openStationChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportRequestScreen()),
    );
  }

  Widget _buildTitleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How can we help?',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Drink 8 Purified Water Refilling Station • San Pablo City',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.primarySky),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _setQuery,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
              decoration: const InputDecoration(
                hintText: 'Search questions, refills, deposits...',
                hintStyle: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _clearSearch,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: AppColors.slate500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_HelpCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _filterCategory(category.filter),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, size: 20, color: category.foreground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
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

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BROWSE BY TOPIC',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${_categories.length} topics',
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categories[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildCategoryCard(_categories[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categories[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildCategoryCard(_categories[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildFaqItem(int index, _Faq faq) {
    final bool open = _openIndex == index;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _openIndex = open ? null : index),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F9FF),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primarySky),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: open
                  ? Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: AppColors.slate100)),
                ),
                padding: const EdgeInsets.all(14),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiries() {
    final term = _query.toLowerCase().trim();
    final List<int> visible = [];
    for (int i = 0; i < _faqs.length; i++) {
      final faq = _faqs[i];
      final text = '${faq.question} ${faq.answer}'.toLowerCase();
      if (term.isEmpty || text.contains(term) || faq.keywords.contains(term)) {
        visible.add(i);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'COMMON QUESTIONS',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${visible.length} topics',
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                const Icon(Icons.search_off_outlined, size: 36, color: AppColors.slate400),
                const SizedBox(height: 10),
                const Text(
                  'No matching answers',
                  style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try another search term or reach out directly to station support below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _clearSearch,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primarySky),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('Clear Search', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          Column(
            children: visible.map((idx) => _buildFaqItem(idx, _faqs[idx])).toList(),
          ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.headset_mic_outlined, size: 20, color: AppColors.primarySky),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need help?',
                      style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    Text(
                      'Contact the San Pablo dispatch team directly.',
                      style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Station Support Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openStationChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Chat with Station Support', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Mon - Sat: 7:00 AM - 5:30 PM (San Pablo City Hub)',
              style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.slate500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // #F8FAFC
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SubScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: 16),
                          _buildSearchField(),
                          const SizedBox(height: 20),
                          _buildCategories(),
                          const SizedBox(height: 20),
                          _buildInquiries(),
                          const SizedBox(height: 20),
                          _buildContactCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}