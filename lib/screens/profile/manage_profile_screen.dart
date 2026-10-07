import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/aqua_logo.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(context);
    try {
      await _firestoreService.updateUserProfile(uid: widget.user.id, name: name, phone: phone);
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
      );
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

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.userData['name'] ?? 'User';
    final String initials = widget.userData['initials'] ?? 'U';
    final String email = widget.userData['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AquaLogo(size: 80),
                        const SizedBox(height: 16),
                        const Text(
                          'Manage Profile',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.44,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Update your personal details & contact info',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3F4850),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006194),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF006194),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Full Name',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildInputField(
                              controller: _nameCtrl,
                              icon: Icons.person_outline,
                              hint: 'Full name',
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildInputField(
                              controller: _phoneCtrl,
                              icon: Icons.call_outlined,
                              hint: '0917 123 4567',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Email Address',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3F4850),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 13, color: Color(0xFF006C49)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: Color(0xFF006C49),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildReadOnlyField(
                              icon: Icons.mail_outline,
                              value: email,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007BB9),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007BB9).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF007BB9).withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9999),
                                  onTap: _saveChanges,
                                  child: const Center(
                                    child: Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: const Color(0xFF707881), size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF131B2E),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF707881),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String value,
  }) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: const Color(0xFF707881), size: 18),
            ),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF131B2E),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, right: 14),
              child: Icon(Icons.lock_outline, color: Color(0xFF707881), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}