import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../profile/terms_privacy_screen.dart' show fallbackEffectiveDate, fallbackJurisdiction, fallbackContactEmail, fallbackTermsClauses, fallbackPrivacyClauses;

const String _font = 'Plus Jakarta Sans';
const Color _background = Color(0xFFF6FAFC);
const Color _onSurface = Color(0xFF131B2E);
const Color _onSurfaceVariant = Color(0xFF3F4850);
const Color _frost = Color(0xFFE0F2FE);
const Color _blue = Color(0xFF0284C7);
const Color _fieldBg = Color(0xFFF2F3FF);
const Color _coral = Color(0xFFF43F5E);
const double _maxWidth = 450;

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
    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(contactEmail);
    setState(() {
      _effectiveDateError = effectiveDate.isEmpty ? 'Effective date is required.' : null;
      _jurisdictionError = jurisdiction.isEmpty ? 'Jurisdiction is required.' : null;
      _contactEmailError = contactEmail.isEmpty
          ? 'Contact email is required.'
          : (!emailValid ? 'Enter a valid email address.' : null);
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
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? errorText, VoidCallback? onChanged}) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: _onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: maxLines > 1 ? 10 : 0),
          height: maxLines > 1 ? null : 42,
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: hasError ? Border.all(color: _coral, width: 1.5) : null,
          ),
          alignment: maxLines > 1 ? null : Alignment.centerLeft,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) => onChanged?.call(),
            style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500, color: _onSurface),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(errorText, style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, color: _coral)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _field('Title', entry.title)),
              const SizedBox(width: 8),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _coral.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, size: 17, color: _coral),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field('Body', entry.body, maxLines: 4),
        ],
      ),
    );
  }

  Widget _section(String title, Color accent, List<_ClauseEntry> clauses, VoidCallback onAdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _onSurface)),
              ),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _frost, borderRadius: BorderRadius.circular(999)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: _blue),
                      SizedBox(width: 4),
                      Text('Add Clause', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w700, color: _blue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _onSurface), onPressed: () => Navigator.maybePop(context)),
        title: const Text('Edit Terms & Privacy', style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w700, color: _onSurface)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
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
                      _section('Part 1: Terms of Service', _blue, _termsClauses, () => setState(() => _termsClauses.add(_ClauseEntry()))),
                      const SizedBox(height: 16),
                      _section('Part 2: Privacy Policy', const Color(0xFF0D9488), _privacyClauses, () => setState(() => _privacyClauses.add(_ClauseEntry()))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
