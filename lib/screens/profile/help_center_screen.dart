import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  String _query = '';
  int? _openIndex;

  static const String _font = 'Plus Jakarta Sans';
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _outline = Color(0xFF707881);
  static const Color _primary = Color(0xFF006194);
  static const Color _primaryContainer = Color(0xFF007BB9);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _frost = Color(0xFFE0F2FE);
  static const Color _ice = Color(0xFFF0F9FF);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _blue = Color(0xFF0284C7);
  static const double _maxWidth = 450;
  static const double _sidePadding = 20;

  static const List<_HelpCategory> _categories = [
    _HelpCategory(
      title: 'Refills',
      subtitle: 'Orders & Timing',
      icon: Icons.water_drop,
      background: Color(0xFFCCE5FF),
      foreground: Color(0xFF006194),
      filter: 'refill',
    ),
    _HelpCategory(
      title: 'Bottle Swap',
      subtitle: 'Deposit rules',
      icon: Icons.sync_alt,
      background: Color(0xFF6FFBBE),
      foreground: Color(0xFF006C49),
      filter: 'swap',
    ),
    _HelpCategory(
      title: 'Delivery',
      subtitle: 'Routes & zones',
      icon: Icons.local_shipping,
      background: Color(0xFFE0F2FE),
      foreground: Color(0xFF007BB9),
      filter: 'delivery',
    ),
    _HelpCategory(
      title: 'GCash / Pay',
      subtitle: 'Reference code',
      icon: Icons.account_balance_wallet,
      background: Color(0x2606B6D4),
      foreground: Color(0xFF006194),
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
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BoxShadow> get _shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

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

  void _showToast(IconData icon, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF283044),
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        duration: const Duration(milliseconds: 2800),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF22D3EE)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.22,
                  color: Color(0xFFEEF0FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyHotline() async {
    await Clipboard.setData(const ClipboardData(text: '(049) 562-8000'));
    if (!mounted) return;
    _showToast(Icons.call, 'Hotline number copied');
  }

  void _openStationChat() {
    _showToast(Icons.support_agent, 'Connecting to San Pablo dispatcher...');
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF475569), size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Back to Profile',
                    style: TextStyle(
                      fontFamily: _font,
                      color: Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help Center & FAQs',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            letterSpacing: -0.6,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Drink 8 Purified Water Refilling Station • San Pablo City',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: _primary),
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
                color: _onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search topics, refill guides, deposits...',
                hintStyle: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(width: 8),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _clearSearch,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: _onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String left, Widget right) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 12 / 10,
              letterSpacing: 1.0,
              color: _outline,
            ),
          ),
          right,
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_HelpCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadowSm,
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
                const SizedBox(width: 12),
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
                          fontWeight: FontWeight.w700,
                          height: 16 / 13,
                          letterSpacing: 0.13,
                          color: _onSurface,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 16 / 11,
                          color: _onSurfaceVariant,
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
        _buildSectionHeader(
          'Categories',
          const Text(
            'FAST ANSWERS',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 12 / 10,
              letterSpacing: 1.0,
              color: _primary,
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _openIndex = open ? null : index),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 22 / 15,
                            color: _onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: _ice,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: const Icon(Icons.keyboard_arrow_down, size: 18, color: _primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: open
                  ? Container(
                width: double.infinity,
                color: _ice.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.625,
                    color: _onSurfaceVariant,
                  ),
                ),
              )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEAEDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.troubleshoot, size: 24, color: _primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching answers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
              letterSpacing: -0.17,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: const Text(
              'Try another keyword or reach out directly to the San Pablo dispatch desk below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 16 / 11,
                color: _onSurfaceVariant,
              ),
            ),
          ),
        ],
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
        _buildSectionHeader(
          'Common Inquiries',
          Text(
            '${visible.length} topics',
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 12 / 10,
              letterSpacing: 0.6,
              color: _onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          _buildNoResults()
        else
          Column(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                _buildFaqItem(visible[i], _faqs[visible[i]]),
                if (i != visible.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _frost.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 4,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6CF8BB).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeTransition(
                                    opacity: _pulseAnimation,
                                    child: const SizedBox(
                                      width: 6,
                                      height: 6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: _secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Live Dispatch',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 12 / 10,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF005236),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Still need help?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  height: 24 / 17,
                                  letterSpacing: -0.17,
                                  color: _onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _frost,
                          shape: BoxShape.circle,
                          boxShadow: _shadowSm,
                        ),
                        child: const Icon(Icons.headset_mic, size: 19, color: _primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ice,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: _shadowSm,
                          ),
                          child: const Icon(Icons.call, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DIRECT DISPATCH HOTLINE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 12 / 10,
                                  letterSpacing: 0.5,
                                  color: _primary,
                                ),
                              ),
                              Text(
                                '(049) 562-8000',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 16 / 13,
                                  letterSpacing: -0.325,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9999),
                              onTap: _copyHotline,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Text(
                                  'Call',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 14 / 11,
                                    letterSpacing: 0.22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9999),
                        onTap: _openStationChat,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 19, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Chat with Station Support',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 16 / 13,
                                letterSpacing: 0.13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 14, color: _onSurfaceVariant),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Mon - Sat: 7:00 AM - 5:30 PM (San Pablo City Hub)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 12 / 10,
                            letterSpacing: 0.6,
                            color: _onSurfaceVariant,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(_sidePadding, 8, _sidePadding, 24 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: 20),
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