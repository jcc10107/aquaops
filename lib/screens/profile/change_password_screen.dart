import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  static const String _font = 'Plus Jakarta Sans';
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _blue = Color(0xFF0284C7);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const double _maxWidth = 450;
  static const double _sidePadding = 20;

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
      messenger.showSnackBar(const SnackBar(content: Text('Password updated smoothly!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        'requires-recent-login' => 'Please log out and log back in, then try again.',
        _ => e.message ?? 'Failed to update password.',
      };
      messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to update password: $e'), backgroundColor: AppColors.error));
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
    setState(() {
      _strength = s;
    });
    _validate();
  }

  void _validate() {
    setState(() {
      _isMatch = _newPassController.text.isNotEmpty && _newPassController.text == _confirmPassController.text && _newPassController.text.length >= 6;
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD).withValues(alpha: 0.8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.verified_user_outlined, size: 32, color: _blue),
        ),
        const SizedBox(height: 16),
        const Text(
          'Change Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            letterSpacing: -0.6,
            color: _slate900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Update your personal credentials & login info',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: _slate500,
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
    bool showForgot = false,
  }) {
    final bool focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: _slate600,
                ),
              ),
              if (showForgot)
                const Text(
                  'Forgot?',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 16 / 12,
                    color: _blue,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: focused ? _blue : _slate200, width: 1),
            boxShadow: focused
                ? [
              BoxShadow(
                color: _blue.withValues(alpha: 0.2),
                blurRadius: 0,
                spreadRadius: 2,
              ),
            ]
                : [
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
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(icon, size: 20, color: _blue),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: !visible,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    color: _slate800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ).copyWith(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      color: _slate400,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  child: Icon(
                    visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: _slate400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthMeter() {
    Widget segment(int index) {
      return Expanded(
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: _strength > index ? _blue : _slate200,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        children: [
          segment(0),
          const SizedBox(width: 6),
          segment(1),
          const SizedBox(width: 6),
          segment(2),
          const SizedBox(width: 6),
          segment(3),
        ],
      ),
    );
  }

  Widget _buildHintBanner() {
    final bool hasConfirm = _confirmPassController.text.isNotEmpty;

    final Color background = _isMatch
        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
        : (hasConfirm ? AppColors.errorContainer.withValues(alpha: 0.4) : const Color(0xFFF0F9FF));
    final Color borderColor = _isMatch
        ? AppColors.secondary.withValues(alpha: 0.2)
        : (hasConfirm ? AppColors.error.withValues(alpha: 0.2) : const Color(0xFFE0F2FE));
    final Color iconColor = _isMatch ? AppColors.secondary : (hasConfirm ? AppColors.error : _blue);
    final Color textColor = _isMatch ? AppColors.secondary : (hasConfirm ? AppColors.error : const Color(0xFF075985));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _isMatch ? Icons.check_circle_outline : (hasConfirm ? Icons.error_outline : Icons.info_outline),
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isMatch ? 'Passwords match perfectly' : (hasConfirm ? 'Passwords do not match yet' : 'At least 8 characters with letters and numbers'),
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInput(
          label: 'Current Password',
          placeholder: 'Enter current password',
          icon: Icons.lock_outline,
          controller: _currPassController,
          focusNode: _currFocus,
          visible: _showCurrent,
          onToggle: () => setState(() => _showCurrent = !_showCurrent),
          showForgot: true,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInput(
              label: 'New Password',
              placeholder: 'Create strong password',
              icon: Icons.lock_open_outlined,
              controller: _newPassController,
              focusNode: _newFocus,
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            _buildStrengthMeter(),
          ],
        ),
        const SizedBox(height: 16),
        _buildInput(
          label: 'Confirm Password',
          placeholder: 'Re-enter new password',
          icon: Icons.lock_outline,
          controller: _confirmPassController,
          focusNode: _confirmFocus,
          visible: _showConfirm,
          onToggle: () => setState(() => _showConfirm = !_showConfirm),
        ),
        const SizedBox(height: 16),
        _buildHintBanner(),
      ],
    );
  }

  Widget _buildBottom(bool canSubmit) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: canSubmit || _isSubmitting ? _blue : _blue.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: canSubmit
                  ? [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: -1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: canSubmit ? _changePassword : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.verified_user_outlined, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Update Password',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: _slate500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _isMatch && _currPassController.text.isNotEmpty && !_isSubmitting;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(_sidePadding, 0, _sidePadding, 24 + bottomInset),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),
                                  _buildTitleBlock(),
                                  const SizedBox(height: 32),
                                  _buildForm(),
                                ],
                              ),
                              _buildBottom(canSubmit),
                            ],
                          ),
                        ),
                      ),
                    ],
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