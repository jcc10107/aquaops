import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/sub_screen_header.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final FocusNode _currFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _isMatch = false;
  int _strength = 0;
  bool _isSubmitting = false;
  bool _submitAttempted = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  static const String _font = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(_checkStrength);
    _confirmPassController.addListener(_validate);
    _currPassController.addListener(() => setState(() {}));
    _currFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  Future<void> _changePassword() async {
    setState(() => _submitAttempted = true);
    if (_currPassController.text.isEmpty || !_isMatch) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: _currPassController.text);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassController.text);

      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF059669)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        'requires-recent-login' => 'Please log out and log back in, then try again.',
        _ => e.message ?? 'Failed to update password.',
      };
      messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.coralAlert));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to update password: $e'), backgroundColor: AppColors.coralAlert));
    }
  }

  @override
  void dispose() {
    _currPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _currFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _checkStrength() {
    final val = _newPassController.text;
    int s = 0;
    if (val.length >= 2) s = 1;
    if (val.length >= 6) s = 2;
    if (val.length >= 8) s = 3;
    if (val.length >= 8 && RegExp(r'[A-Z]').hasMatch(val) && RegExp(r'[0-9]').hasMatch(val)) s = 4;
    setState(() => _strength = s);
    _validate();
  }

  void _validate() {
    setState(() {
      _isMatch = _newPassController.text.isNotEmpty &&
          _newPassController.text == _confirmPassController.text &&
          _newPassController.text.length >= 8;
    });
  }

  Widget _buildTitleBlock() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
          child: const Icon(Icons.lock_reset, size: 28, color: AppColors.primarySky),
        ),
        const SizedBox(height: 12),
        const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Update your account password and security credentials',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required String label,
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool visible,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? AppColors.coralAlert : (focusNode.hasFocus ? AppColors.primarySky : AppColors.slate200),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, size: 18, color: AppColors.slate400),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: !visible,
                  style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: placeholder,
                    hintStyle: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.slate400),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.slate400),
                onPressed: onToggle,
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(errorText, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.coralAlert)),
          ),
      ],
    );
  }

  Widget _buildStrengthMeter() {
    Widget segment(int index) {
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _strength > index ? AppColors.primarySky : AppColors.slate200,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [segment(0), segment(1), segment(2), segment(3)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _isMatch && _currPassController.text.isNotEmpty && !_isSubmitting;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // #F8FAFC
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SubScreenHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: 24),
                          _buildInput(
                            label: 'Current Password',
                            placeholder: 'Enter your existing password',
                            icon: Icons.lock_outline,
                            controller: _currPassController,
                            focusNode: _currFocus,
                            visible: _showCurrent,
                            onToggle: () => setState(() => _showCurrent = !_showCurrent),
                            errorText: _submitAttempted && _currPassController.text.isEmpty ? 'Current password is required.' : null,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildInput(
                                label: 'New Password',
                                placeholder: 'Min. 8 characters with letters & numbers',
                                icon: Icons.lock_reset,
                                controller: _newPassController,
                                focusNode: _newFocus,
                                visible: _showNew,
                                onToggle: () => setState(() => _showNew = !_showNew),
                                errorText: _submitAttempted && _newPassController.text.length < 8
                                    ? 'Password must be at least 8 characters.'
                                    : null,
                              ),
                              _buildStrengthMeter(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            label: 'Confirm New Password',
                            placeholder: 'Re-enter your new password',
                            icon: Icons.check_circle_outline,
                            controller: _confirmPassController,
                            focusNode: _confirmFocus,
                            visible: _showConfirm,
                            onToggle: () => setState(() => _showConfirm = !_showConfirm),
                            errorText: _submitAttempted && _confirmPassController.text.isNotEmpty && !_isMatch
                                ? 'Passwords do not match.'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: canSubmit ? _changePassword : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySky,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.slate200,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Update Password', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
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