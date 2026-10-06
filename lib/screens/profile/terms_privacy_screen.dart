import 'package:flutter/material.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _accepting = false;

  static const String _font = 'Plus Jakarta Sans';
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _sky600 = Color(0xFF0284C7);
  static const Color _sky700 = Color(0xFF0369A1);
  static const Color _sky50 = Color(0xFFF0F9FF);
  static const Color _teal600 = Color(0xFF0D9488);
  static const Color _teal800 = Color(0xFF115E59);
  static const Color _teal50 = Color(0xFFF0FDFA);
  static const Color _teal200 = Color(0xFF99F6E4);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate100 = Color(0xFFF1F5F9);

  List<BoxShadow> get _shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  Future<void> _handleAccept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _slate900.withValues(alpha: 0.95),
        elevation: 6,
        margin: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        duration: const Duration(milliseconds: 1500),
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 18, color: Color(0xFF2DD4BF)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Terms & Privacy Accepted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final popped = await Navigator.maybePop(context);
    if (!popped && mounted) {
      setState(() => _accepting = false);
    }
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
          'Terms & Privacy',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 32 / 24,
            letterSpacing: -0.6,
            color: _slate900,
          ),
        ),
        SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.water_drop_outlined, size: 15, color: _sky600),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Drink 8 Purified Water Refilling Station • San Pablo City',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.625,
                  color: _slate500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text, Color barColor) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 16,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: _slate800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBlock(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _sky50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 17, color: _sky700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 16 / 10,
                  color: _slate400,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: _slate800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200.withValues(alpha: 0.7)),
        boxShadow: _shadowSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoBlock(
              Icons.calendar_today_outlined,
              'Effective Date',
              'September 21, 2026',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: _slate200,
          ),
          Expanded(
            child: _buildInfoBlock(
              Icons.location_on_outlined,
              'Jurisdiction',
              'San Pablo City, Laguna',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClause(String number, String title, String body, Color numberColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$number ', style: TextStyle(color: numberColor)),
              TextSpan(text: title),
            ],
          ),
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 16 / 12,
            color: _slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.625,
            color: _slate600,
          ),
        ),
      ],
    );
  }

  Widget _buildClauseCard(List<Widget> clauses) {
    final List<Widget> children = [];
    for (int i = 0; i < clauses.length; i++) {
      children.add(clauses[i]);
      if (i != clauses.length - 1) {
        children.add(const SizedBox(height: 16));
        children.add(Container(height: 1, color: _slate100));
        children.add(const SizedBox(height: 16));
      }
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200.withValues(alpha: 0.7)),
        boxShadow: _shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Part 1: Terms of Service', _sky600),
        const SizedBox(height: 24),
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildClauseCard([
          _buildClause(
            '1.',
            'Acceptance of Terms',
            'By accessing, creating an account, or ordering through the Drink 8 Refilling Station platform (AquaOps), you confirm that you have read, understood, and agreed to be bound by these Terms of Service and applicable municipal health regulations.',
            _sky600,
          ),
          _buildClause(
            '2.',
            'User Accounts & Registration',
            'Customers must provide accurate residential delivery addresses, active mobile contact numbers, and ensure credentials remain secure. Account holders are responsible for all refill orders requested under their authenticated profile.',
            _sky600,
          ),
          _buildClause(
            '3.',
            'Product & Gallon Policy',
            'All 5-gallon slim and round containers exchanged must be thoroughly inspectable, free from contamination, oil residues, chemical odours, or structural fissures. Damaged customer-owned containers may be rejected to preserve hygienic purification integrity.',
            _sky600,
          ),
        ]),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: _slate200)),
        SizedBox(width: 12),
        Icon(Icons.shield_outlined, size: 14, color: _slate400),
        SizedBox(width: 12),
        Expanded(child: Divider(height: 1, thickness: 1, color: _slate200)),
      ],
    );
  }

  Widget _buildComplianceBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _teal50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _teal200.withValues(alpha: 0.7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 16, color: _teal600),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Compliance: RA No. 10173 (Data Privacy Act of 2012)',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: _teal800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Part 2: Privacy Policy', _teal600),
        const SizedBox(height: 16),
        _buildComplianceBadge(),
        const SizedBox(height: 16),
        _buildClauseCard([
          _buildClause(
            '1.',
            'Information Collection',
            'We collect personal details necessary to facilitate scheduled water distribution: full legal name, delivery drop-off point coordinates, mobile contact digits, and historical replenishment intervals.',
            _teal600,
          ),
          _buildClause(
            '2.',
            'Data Usage & Protection',
            'Customer telemetry and contact records are strictly utilized for delivery dispatches, sanitation notices, and billing receipts. Data is never shared or sold to third-party commercial marketing entities without explicit written consent.',
            _teal600,
          ),
        ]),
        const SizedBox(height: 16),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Questions regarding legal guidelines? Contact station administration at '),
                  TextSpan(
                    text: 'support@drink8water.ph',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _sky700,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.625,
                color: _slate400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _accepting ? 0.9 : 1,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _sky600,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: _sky600.withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: _accepting ? null : _handleAccept,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 19, color: Colors.white),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'I Accept Terms & Conditions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                      color: Colors.white,
                    ),
                  ),
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: 24),
                          _buildTermsSection(),
                          const SizedBox(height: 28),
                          _buildDivider(),
                          const SizedBox(height: 28),
                          _buildPrivacySection(),
                          const SizedBox(height: 28),
                          _buildAcceptButton(),
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