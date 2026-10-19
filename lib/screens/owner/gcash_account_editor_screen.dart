import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

const String _font = 'Plus Jakarta Sans';
const Color _background = Color(0xFFF6FAFC);
const Color _onSurface = Color(0xFF131B2E);
const Color _onSurfaceVariant = Color(0xFF3F4850);
const Color _blue = Color(0xFF0284C7);
const Color _fieldBg = Color(0xFFF2F3FF);
const Color _coral = Color(0xFFF43F5E);
const double _maxWidth = 450;

class GcashAccountEditorScreen extends StatefulWidget {
  const GcashAccountEditorScreen({super.key});

  @override
  State<GcashAccountEditorScreen> createState() => _GcashAccountEditorScreenState();
}

class _GcashAccountEditorScreenState extends State<GcashAccountEditorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _uploadingQr = false;
  String? _nameError;
  String? _numberError;
  String? _qrImageUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = await _firestoreService.getGcashAccountStream().first;
    _nameCtrl.text = account.accountName;
    _numberCtrl.text = account.accountNumber;
    _qrImageUrl = account.qrImageUrl;
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadQr() async {
    if (_uploadingQr) return;
    setState(() => _uploadingQr = true);
    try {
      final shot = await _picker.pickImage(source: ImageSource.gallery).timeout(const Duration(seconds: 20));
      if (shot == null) {
        if (!mounted) return;
        setState(() => _uploadingQr = false);
        return;
      }
      final bytes = await shot.readAsBytes().timeout(const Duration(seconds: 20));
      final url = await _cloudinary.uploadImage(bytes, filename: 'gcash_qr.jpg', folder: 'gcash_qr').timeout(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() {
        _qrImageUrl = url;
        _uploadingQr = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingQr = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload QR photo: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    final number = _numberCtrl.text.trim();
    final numberValid = RegExp(r'^09\d{9}$').hasMatch(number);
    setState(() {
      _nameError = name.isEmpty ? 'Account name is required.' : null;
      _numberError = number.isEmpty
          ? 'GCash number is required.'
          : (!numberValid ? 'Enter a valid 11-digit GCash number (e.g. 09171234567).' : null);
    });
    if (_nameError != null || _numberError != null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await _firestoreService.setGcashAccount(accountName: name, accountNumber: number, qrImageUrl: _qrImageUrl);
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('GCash account updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Widget _field(String label, TextEditingController controller, {String? errorText, VoidCallback? onChanged}) {
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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: hasError ? Border.all(color: _coral, width: 1.5) : null,
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _onSurface), onPressed: () => Navigator.maybePop(context)),
        title: const Text('Edit GCash Account', style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w700, color: _onSurface)),
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
                      Text(
                        'This is the GCash account shown to customers and cashiers for payment — at checkout, on the POS counter QR, and on the GCash reference field. Update it here if the number ever changes or reaches its transaction limit; both screens pick up the change immediately.',
                        style: TextStyle(fontFamily: _font, fontSize: 12, color: _onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          children: [
                            _field(
                              'Account Name',
                              _nameCtrl,
                              errorText: _nameError,
                              onChanged: () {
                                if (_nameError != null) setState(() => _nameError = null);
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              'GCash Number',
                              _numberCtrl,
                              errorText: _numberError,
                              onChanged: () {
                                if (_numberError != null) setState(() => _numberError = null);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GCASH PERSONAL QR',
                              style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: _onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Open your own GCash app → Profile → "My QR", screenshot it, and upload it here. This is the only kind of QR the real GCash app will scan — a generated or made-up QR will always say "not valid."',
                              style: TextStyle(fontFamily: _font, fontSize: 12, color: _onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            if (_qrImageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_qrImageUrl!, height: 180, fit: BoxFit.contain),
                              ),
                            if (_qrImageUrl != null) const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadingQr ? null : _pickAndUploadQr,
                                    icon: _uploadingQr
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.upload, size: 16, color: _blue),
                                    label: Text(
                                      _qrImageUrl == null ? 'Upload QR Photo' : 'Replace QR Photo',
                                      style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: _blue),
                                    ),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                                  ),
                                ),
                                if (_qrImageUrl != null) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => setState(() => _qrImageUrl = null),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(color: _coral.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.delete_outline, size: 17, color: _coral),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
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
