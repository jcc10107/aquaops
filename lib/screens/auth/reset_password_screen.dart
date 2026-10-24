import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart'; // Added centralized layout constants
import '../../core/utils/app_toast.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_brand_header.dart';
import '../../widgets/sub_screen_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _emailError;

  static const String _font = 'Plus Jakarta Sans';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailCtrl.text.trim();

    setState(() {
      _emailError = Validators.validateEmail(email);
    });

    if (_emailError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      AppToast.showSuccess(
        context,
        'Reset link sent to $email.',
        title: 'Check Your Inbox',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(
        context,
        getAuthErrorMessage(e),
        title: 'Reset Failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SubScreenHeader(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth), // Using global content width constraint
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AuthBrandHeader(
                          title: 'Reset Password',
                          subtitle: 'Enter your email to receive a password reset link',
                        ),
                        const SizedBox(height: 28),
                        if (_emailSent) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.mark_email_read, size: 40, color: Color(0xFF0284C7)),
                                const SizedBox(height: 10),
                                const Text(
                                  'Instructions Sent',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF131B2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We have sent password reset instructions to ${_emailCtrl.text.trim()}.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 12,
                                    color: Color(0xFF3F4850),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const Text(
                                'Back to Sign In',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3F4850),
                                  ),
                                ),
                              ),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _emailError != null
                                      ? Border.all(color: AppColors.error, width: 1.5)
                                      : null,
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
                                      child: Icon(
                                        Icons.mail_outline,
                                        color: _emailError != null
                                            ? AppColors.error
                                            : const Color(0xFF707881),
                                        size: 18,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: (_) {
                                          if (_emailError != null) {
                                            setState(() => _emailError = null);
                                          }
                                        },
                                        style: const TextStyle(
                                          fontFamily: _font,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF131B2E),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'name@example.com',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF707881),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              if (_emailError != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 4),
                                  child: Text(
                                    _emailError!,
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0x330284C7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
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
}