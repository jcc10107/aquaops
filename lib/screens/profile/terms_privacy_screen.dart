import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../widgets/sub_screen_header.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

const String fallbackEffectiveDate = 'September 21, 2026';
const String fallbackJurisdiction = 'San Pablo City, Laguna';
const String fallbackContactEmail = 'support@drink8water.ph';
const List<Map<String, String>> fallbackTermsClauses = [
  {
    'title': 'Acceptance of Terms',
    'body':
    'By accessing, creating an account, or ordering through the Drink 8 Refilling Station platform (AquaOps), you confirm that you have read, understood, and agreed to be bound by these Terms of Service and applicable municipal health regulations.',
  },
  {
    'title': 'User Accounts & Registration',
    'body':
    'Customers must provide accurate residential delivery addresses, active mobile contact numbers, and ensure credentials remain secure. Account holders are responsible for all refill orders requested under their authenticated profile.',
  },
  {
    'title': 'Product & Gallon Policy',
    'body':
    'All 5-gallon slim and round containers exchanged must be thoroughly inspectable, free from contamination, oil residues, chemical odours, or structural fissures. Damaged customer-owned containers may be rejected to preserve hygienic purification integrity.',
  },
];
const List<Map<String, String>> fallbackPrivacyClauses = [
  {
    'title': 'Information Collection',
    'body':
    'We collect personal details necessary to facilitate scheduled water distribution: full legal name, delivery drop-off point coordinates, mobile contact digits, and historical replenishment intervals.',
  },
  {
    'title': 'Data Usage & Protection',
    'body':
    'Customer telemetry and contact records are strictly utilized for delivery dispatches, sanitation notices, and billing receipts. Data is never shared or sold to third-party commercial marketing entities without explicit written consent.',
  },
];

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _accepting = false;
  final FirestoreService _firestoreService = FirestoreService();

  static const String _font = 'Plus Jakarta Sans';
  static const Color _teal600 = Color(0xFF0D9488);

  Future<void> _handleAccept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Terms & Privacy accepted successfully!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final popped = await Navigator.maybePop(context);
    if (!popped && mounted) {
      setState(() => _accepting = false);
    }
  }

  Widget _buildTitleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Privacy',
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

  Widget _buildMetadataCard(String effectiveDate, String jurisdiction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EFFECTIVE DATE', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                const SizedBox(height: 2),
                Text(effectiveDate, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight)),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.slate200),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JURISDICTION', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                const SizedBox(height: 2),
                Text(jurisdiction, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClauseCard(List<Map<String, String>> clauses, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < clauses.length; i++) ...[
            if (i > 0) const Divider(height: 24, color: AppColors.slate100),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}'.padLeft(2, '0'),
                    style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clauses[i]['title'] ?? '',
                        style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        clauses[i]['body'] ?? '',
                        style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: _firestoreService.getTermsPrivacyStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final effectiveDate = (data?['effectiveDate'] as String?) ?? fallbackEffectiveDate;
                  final jurisdiction = (data?['jurisdiction'] as String?) ?? fallbackJurisdiction;
                  final contactEmail = (data?['contactEmail'] as String?) ?? fallbackContactEmail;
                  final termsClauses = (data?['termsClauses'] as List?)?.map((c) => Map<String, String>.from(c as Map)).toList() ?? fallbackTermsClauses;
                  final privacyClauses = (data?['privacyClauses'] as List?)?.map((c) => Map<String, String>.from(c as Map)).toList() ?? fallbackPrivacyClauses;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTitleBlock(),
                            const SizedBox(height: 16),
                            _buildMetadataCard(effectiveDate, jurisdiction),
                            const SizedBox(height: 20),

                            // Part 1: Terms of Service
                            Row(
                              children: [
                                Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(100))),
                                const SizedBox(width: 8),
                                const Text(
                                  'Part 1: Terms of Service',
                                  style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildClauseCard(termsClauses, AppColors.primarySky),
                            const SizedBox(height: 24),

                            // Part 2: Privacy Policy
                            Row(
                              children: [
                                Container(width: 4, height: 16, decoration: BoxDecoration(color: _teal600, borderRadius: BorderRadius.circular(100))),
                                const SizedBox(width: 8),
                                const Text(
                                  'Part 2: Privacy Policy',
                                  style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildClauseCard(privacyClauses, _teal600),
                            const SizedBox(height: 16),

                            // Contact Note
                            Center(
                              child: Text(
                                'Questions about these policies? Contact: $contactEmail',
                                style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Accept Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _accepting ? null : _handleAccept,
                                icon: _accepting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check, size: 18),
                                label: const Text('I Accept Terms & Conditions', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}