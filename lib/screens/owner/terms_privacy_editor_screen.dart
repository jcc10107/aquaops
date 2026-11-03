import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/firestore_service.dart';
import '../profile/terms_privacy_screen.dart'
    show fallbackEffectiveDate, fallbackJurisdiction, fallbackContactEmail, fallbackTermsClauses, fallbackPrivacyClauses;

const String _font = 'Plus Jakarta Sans';

class _ClauseEntry {
  final TextEditingController title;
  final TextEditingController body;
  _ClauseEntry({String title = '', String body = ''})
      : title = TextEditingController(text: title),
        body = TextEditingController(text: body);

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

class TermsPrivacyEditorScreen extends StatefulWidget {
  const TermsPrivacyEditorScreen({super.key});

  @override
  State<TermsPrivacyEditorScreen> createState() => _TermsPrivacyEditorScreenState();
}

class _TermsPrivacyEditorScreenState extends State<TermsPrivacyEditorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _effectiveDateCtrl = TextEditingController();
  final TextEditingController _jurisdictionCtrl = TextEditingController();
  final TextEditingController _contactEmailCtrl = TextEditingController();

  List<_ClauseEntry> _termsClauses = [];
  List<_ClauseEntry> _privacyClauses = [];
  bool _loading = true;
  bool _saving = false;
  String? _effectiveDateError;
  String? _jurisdictionError;
  String? _contactEmailError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _firestoreService.getTermsPrivacyOnce();
    _effectiveDateCtrl.text = (data?['effectiveDate'] as String?) ?? fallbackEffectiveDate;
    _jurisdictionCtrl.text = (data?['jurisdiction'] as String?) ?? fallbackJurisdiction;
    _contactEmailCtrl.text = (data?['contactEmail'] as String?) ?? fallbackContactEmail;
    final terms = (data?['termsClauses'] as List?)?.map((c) => Map<String, String>.from(c as Map)).toList() ?? fallbackTermsClauses;
    final privacy = (data?['privacyClauses'] as List?)?.map((c) => Map<String, String>.from(c as Map)).toList() ?? fallbackPrivacyClauses;
    if (!mounted) return;
    setState(() {
      _termsClauses = terms.map((c) => _ClauseEntry(title: c['title'] ?? '', body: c['body'] ?? '')).toList();
      _privacyClauses = privacy.map((c) => _ClauseEntry(title: c['title'] ?? '', body: c['body'] ?? '')).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _effectiveDateCtrl.dispose();
    _jurisdictionCtrl.dispose();
    _contactEmailCtrl.dispose();
    for (final c in _termsClauses) {
      c.dispose();
    }
    for (final c in _privacyClauses) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final effectiveDate = _effectiveDateCtrl.text.trim();
    final jurisdiction = _jurisdictionCtrl.text.trim();
    final contactEmail = _contactEmailCtrl.text.trim();
    setState(() {
      _effectiveDateError = effectiveDate.isEmpty ? 'Effective date is required.' : null;
      _jurisdictionError = jurisdiction.isEmpty ? 'Jurisdiction is required.' : null;
      _contactEmailError = Validators.validateEmail(
        contactEmail,
        requiredMessage: 'Contact email is required.',
        invalidMessage: 'Enter a valid email address.',
      );
    });
    if (_effectiveDateError != null || _jurisdictionError != null || _contactEmailError != null) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await _firestoreService.updateTermsPrivacy({
        'effectiveDate': _effectiveDateCtrl.text.trim(),
        'jurisdiction': _jurisdictionCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'termsClauses': _termsClauses.map((c) => {'title': c.title.text.trim(), 'body': c.body.text.trim()}).toList(),
        'privacyClauses': _privacyClauses.map((c) => {'title': c.title.text.trim(), 'body': c.body.text.trim()}).toList(),
      });
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Terms & Privacy updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.coralAlert));
    }
  }

  Widget _header(double topInset) {
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
                'Edit Terms & Privacy',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Station policies and legal disclosures',
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

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? errorText, VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => onChanged?.call(),
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceCanvas,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primarySky)),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _clauseCard(_ClauseEntry entry, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _field('Clause Title', entry.title)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coralAlert),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field('Clause Body', entry.body, maxLines: 4),
        ],
      ),
    );
  }

  Widget _section(String title, Color accent, List<_ClauseEntry> clauses, VoidCallback onAdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(100))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16, color: AppColors.primarySky),
                label: const Text('Add Clause', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primarySky)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < clauses.length; i++)
            _clauseCard(clauses[i], () => setState(() {
              clauses[i].dispose();
              clauses.removeAt(i);
            })),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // #F8FAFC
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
          child: Column(
            children: [
              _header(topInset),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          children: [
                            _field(
                              'Effective Date',
                              _effectiveDateCtrl,
                              errorText: _effectiveDateError,
                              onChanged: () {
                                if (_effectiveDateError != null) setState(() => _effectiveDateError = null);
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              'Jurisdiction',
                              _jurisdictionCtrl,
                              errorText: _jurisdictionError,
                              onChanged: () {
                                if (_jurisdictionError != null) setState(() => _jurisdictionError = null);
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              'Contact Email',
                              _contactEmailCtrl,
                              errorText: _contactEmailError,
                              onChanged: () {
                                if (_contactEmailError != null) setState(() => _contactEmailError = null);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _section('Part 1: Terms of Service', AppColors.primarySky, _termsClauses, () => setState(() => _termsClauses.add(_ClauseEntry()))),
                      const SizedBox(height: 16),
                      _section('Part 2: Privacy Policy', const Color(0xFF059669), _privacyClauses, () => setState(() => _privacyClauses.add(_ClauseEntry()))),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
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