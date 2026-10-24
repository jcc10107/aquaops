import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/sub_screen_header.dart';

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
  static const double _sidePadding = 20;

  static final List<_HelpCategory> _categories = [
    const _HelpCategory(
      title: 'Refills',
      subtitle: 'Orders & Timing',
      icon: Icons.water_drop,
      background: Color(0xFFCCE5FF),
      foreground: AppColors.primary,
      filter: 'refill',
    ),
    const _HelpCategory(
      title: 'Bottle Swap',
      subtitle: 'Deposit rules',
      icon: Icons.sync_alt,
      background: AppColors.mintBadge,
      foreground: AppColors.secondary,
      filter: 'swap',
    ),
    const _HelpCategory(
      title: 'Delivery',
      subtitle: 'Routes & zones',
      icon: Icons.local_shipping,
      background: AppColors.surfaceFrost,
      foreground: AppColors.primaryContainer,
      filter: 'delivery',
    ),
    _HelpCategory(
      title: 'GCash / Pay',
      subtitle: 'Reference code',
      icon: Icons.account_balance_wallet,
      background: AppColors.cyanElectric.withValues(alpha: 0.15),
      foreground: AppColors.primary,
      filter: 'gcash',
    ),
  ];

  static const List<_Faq> _faqs = [
    _Faq(
      question: 'How does the empty gallon container swap work?',
      answer:
      'Leave your clean, undamaged Drink 8 empty container at your doorstep or hand it to our dispatch rider upon delivery to avoid new bottle deposit fees.',
      keywords:
      'empty gallon container swap bottle deposit clean undamaged doorstep rider',
    ),
    _Faq(
      question: 'What are your delivery hours in San Pablo City?',
      answer:
      'Our riders operate Monday to Saturday from 7:00 AM to 5:30 PM across covered barangays including San Isidro and San Antonio.',
      keywords:
      'delivery hours san pablo city timing barangay monday saturday isidro antonio',
    ),
    _Faq(
      question: 'How do I verify GCash payments?',
      answer:
      'Input your GCash 13-digit reference number upon ordering or upload your transaction screenshot directly in Checkout or to the rider.',
      keywords:
      'verify gcash payments 13-digit reference number upload receipt screenshot checkout rider',
    ),
    _Faq(
      question: 'What if my delivery is delayed due to weather?',
      answer:
      'In case of heavy rains or localized flooding, order status updates will be broadcast directly via push alerts and SMS.',
      keywords:
      'delivery delay delayed heavy rain weather flooding push alerts broadcast sms status',
    ),
    _Faq(
      question: 'Can I request an emergency refill?',
      answer:
      "Yes! Contact the station dispatch hotline or select 'Priority Queue' during ordering if available.",
      keywords:
      'request emergency refill priority queue urgent fast hotline dispatch call',
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

  Future<void> _copyHotline() async {
    await Clipboard.setData(const ClipboardData(text: '(049) 562-8000'));
    if (!mounted) return;
    AppToast.showInfo(context, 'Hotline number copied');
  }

  void _openStationChat() {
    AppToast.showInfo(context, 'Connecting to San Pablo dispatcher...');
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
            color: AppColors.backgroundDark,
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
            color: AppColors.slate500,
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
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.primary),
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
              decoration: InputDecoration(
                hintText: 'Search topics, refill guides, deposits...',
                hintStyle: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
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
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
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
              color: AppColors.outline,
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
                  child:
                  Icon(category.icon, size: 20, color: category.foreground),
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
                          color: AppColors.textLight,
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
              color: AppColors.primary,
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
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceIce,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: AppColors.primary),
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
                color: AppColors.surfaceIce.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.625,
                    color: AppColors.textSecondary,
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
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.troubleshoot, size: 24, color: AppColors.primary),
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
              color: AppColors.textLight,
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
                color: AppColors.textSecondary,
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
              color: AppColors.textSecondary,
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
        border: Border.all(color: AppColors.surfaceFrost.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
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
                  color: AppColors.cyanElectric.withValues(alpha: 0.05),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
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
                                          color: AppColors.secondary,
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
                                  color: AppColors.textLight,
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
                          color: AppColors.surfaceFrost,
                          shape: BoxShape.circle,
                          boxShadow: _shadowSm,
                        ),
                        child: const Icon(Icons.headset_mic,
                            size: 19, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceIce,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: _shadowSm,
                          ),
                          child: const Icon(Icons.call,
                              size: 18, color: Colors.white),
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
                                  color: AppColors.primary,
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
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primarySky,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primarySky.withValues(alpha: 0.3),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
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
                      color: AppColors.primarySky,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primarySky.withValues(alpha: 0.35),
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
                      Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
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
                            color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surfaceBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SubScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          _sidePadding, 8, _sidePadding, 24 + bottomInset),
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