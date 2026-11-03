import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/editor_text_field.dart';

const String _font = 'Plus Jakarta Sans';

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
    final messenger = ScaffoldMessenger.of(context);

    try {
      final shot = await _picker
          .pickImage(source: ImageSource.gallery)
          .timeout(const Duration(seconds: 20));

      if (shot == null) {
        if (!mounted) return;
        setState(() => _uploadingQr = false);
        return;
      }

      final bytes = await shot.readAsBytes().timeout(const Duration(seconds: 20));
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
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload QR photo: $e'), backgroundColor: AppColors.coralAlert),
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
        invalidMessage: 'Enter a valid 11-digit GCash number (e.g. 09171234567).',
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
        const SnackBar(content: Text('GCash account updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.coralAlert),
      );
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
                'Edit GCash Account',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Customer and checkout payment destination',
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

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Color(0xFF0369A1)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is the payment account shown to customers during checkout and on the POS counter. Updates take effect immediately across all customer and cashier devices.',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12,
                color: Color(0xFF075985),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountDetailsCard() {
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, size: 18, color: AppColors.primarySky),
              ),
              const SizedBox(width: 10),
              const Text(
                'Account Details',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          EditorTextField(
            label: 'Account Name *',
            controller: _nameCtrl,
            hintText: "Enter registered account holder's full name",
            errorText: _nameError,
            onChanged: () {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 12),
          EditorTextField(
            label: 'GCash Number *',
            controller: _numberCtrl,
            hintText: 'e.g. 09171234567',
            keyboardType: TextInputType.phone,
            errorText: _numberError,
            onChanged: () {
              if (_numberError != null) setState(() => _numberError = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _qrSectionCard() {
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_2, size: 18, color: AppColors.primarySky),
              ),
              const SizedBox(width: 10),
              const Text(
                'Personal GCash QR Code',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Open your GCash app → Profile → "My QR", take a screenshot, and upload it here. Generated or placeholder QR images will be rejected by customer banking apps.',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // QR Preview Container
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: _qrImageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _qrImageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 36, color: AppColors.slate400),
                  ),
                ),
              )
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 44, color: AppColors.slate400),
                  SizedBox(height: 8),
                  Text(
                    'No QR Code Uploaded',
                    style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Upload / Remove Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadingQr ? null : _pickAndUploadQr,
                  icon: _uploadingQr
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                  )
                      : const Icon(Icons.upload_file_outlined, size: 18, color: AppColors.primarySky),
                  label: Text(
                    _qrImageUrl == null ? 'Upload QR Photo' : 'Replace QR Photo',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primarySky,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primarySky),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (_qrImageUrl != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Remove QR',
                  onPressed: () => setState(() => _qrImageUrl = null),
                  icon: const Icon(Icons.delete_outline, color: AppColors.coralAlert),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                  ),
                ),
              ],
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
                      _infoBanner(),
                      const SizedBox(height: 16),
                      _accountDetailsCard(),
                      const SizedBox(height: 16),
                      _qrSectionCard(),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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