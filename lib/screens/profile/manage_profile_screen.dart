import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/aqua_logo.dart';
import '../../widgets/sub_screen_header.dart';

class ManageProfileScreen extends StatefulWidget {
  final UserModel user;
  final Map<String, String> userData;

  const ManageProfileScreen({
    super.key,
    required this.user,
    required this.userData,
  });

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _nameError;
  String? _phoneError;
  bool _saving = false;

  static const String _font = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Full name is required.' : null;
      _phoneError = Validators.validateGCash(
        phone,
        requiredMessage: 'Mobile number is required.',
        invalidMessage: 'Enter a valid 11-digit mobile number.',
      );
    });

    if (_nameError != null || _phoneError != null) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await _firestoreService.updateUserProfile(
        uid: widget.user.id,
        name: name,
        phone: phone,
      );
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.coralAlert),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.userData['name'] ?? 'User';
    final String initials = widget.userData['initials'] ?? 'U';
    final String email = widget.userData['email'] ?? '';
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
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const AquaLogo(size: 72),
                            const SizedBox(height: 12),
                            const Text(
                              'Manage Profile',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Update your personal information & contact details',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // User Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.primarySky,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayName,
                                    style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Form Fields
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Full Name *', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _nameCtrl,
                                  style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.slate400),
                                    hintText: 'Enter your full name',
                                    filled: true,
                                    fillColor: AppColors.surfaceCanvas,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primarySky)),
                                    errorText: _nameError,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                const Text('Mobile Phone Number *', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.slate400),
                                    hintText: '09XX XXX XXXX',
                                    filled: true,
                                    fillColor: AppColors.surfaceCanvas,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primarySky)),
                                    errorText: _phoneError,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Email Address', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified, size: 13, color: Color(0xFF059669)),
                                        const SizedBox(width: 4),
                                        Text('Verified', style: const TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.slate200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.mail_outline, size: 18, color: AppColors.slate400),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ),
                                      const Icon(Icons.lock_outline, size: 16, color: AppColors.slate400),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _saveChanges,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primarySky,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _saving
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Save Changes', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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