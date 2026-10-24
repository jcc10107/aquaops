import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/utils/validators.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/editor_text_field.dart';

const String _font = 'Plus Jakarta Sans';

class GcashAccountEditorScreen extends StatefulWidget {
  const GcashAccountEditorScreen({super.key});

  @override
  State<GcashAccountEditorScreen> createState() =>
      _GcashAccountEditorScreenState();
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
      final shot = await _picker
          .pickImage(source: ImageSource.gallery)
          .timeout(const Duration(seconds: 20));
      if (shot == null) {
        if (!mounted) return;
        setState(() => _uploadingQr = false);
        return;
      }
      final bytes =
      await shot.readAsBytes().timeout(const Duration(seconds: 20));
      final url = await _cloudinary
          .uploadImage(
        bytes,
        filename: 'gcash_qr.jpg',
        folder: 'gcash_qr',
      )
          .timeout(const Duration(seconds: 30));
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

    setState(() {
      _nameError = name.isEmpty ? 'Account name is required.' : null;
      _numberError = Validators.validateGCash(
        number,
        requiredMessage: 'GCash number is required.',
        invalidMessage:
        'Enter a valid 11-digit GCash number (e.g. 09171234567).',
      );
    });
    if (_nameError != null || _numberError != null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await _firestoreService.setGcashAccount(
        accountName: name,
        accountNumber: Validators.sanitizePhone(number),
        qrImageUrl: _qrImageUrl,
      );
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('GCash account updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Edit GCash Account',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const Text(
                  'This is the GCash account shown to customers and cashiers for payment — at checkout, on the POS counter QR, and on the GCash reference field. Update it here if the number ever changes or reaches its transaction limit; both screens pick up the change immediately.',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    children: [
                      EditorTextField(
                        label: 'Account Name',
                        controller: _nameCtrl,
                        errorText: _nameError,
                        onChanged: () {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      EditorTextField(
                        label: 'GCash Number',
                        controller: _numberCtrl,
                        keyboardType: TextInputType.phone,
                        errorText: _numberError,
                        onChanged: () {
                          if (_numberError != null) {
                            setState(() => _numberError = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                      const Text(
                        'GCASH PERSONAL QR',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Open your own GCash app → Profile → "My QR", screenshot it, and upload it here. This is the only kind of QR the real GCash app will scan — a generated or made-up QR will always say "not valid."',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_qrImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _qrImageUrl!,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (_qrImageUrl != null) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _uploadingQr
                                  ? null
                                  : _pickAndUploadQr,
                              icon: _uploadingQr
                                  ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.upload,
                                size: 16,
                                color: AppColors.primarySky,
                              ),
                              label: Text(
                                _qrImageUrl == null
                                    ? 'Upload QR Photo'
                                    : 'Replace QR Photo',
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primarySky,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          if (_qrImageUrl != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () =>
                                  setState(() => _qrImageUrl = null),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.coralAlert.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 17,
                                  color: AppColors.coralAlert,
                                ),
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
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
}