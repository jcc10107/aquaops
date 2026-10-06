import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ResetPasswordScreen({super.key, required this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late TextEditingController _resetEmailController;
  final AuthService _authService = AuthService();
  final FocusNode _emailFocus = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resetEmailController = TextEditingController(text: widget.initialEmail);
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _resetEmailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String _resetErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
        return 'No account found with that email.';
      default:
        return e.message ?? 'Failed to send reset link. Please try again.';
    }
  }

  Future<void> _handleReset() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _authService.sendPasswordReset(email);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email.'),
          backgroundColor: AppColors.primaryLight,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_resetErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Color(0xFF475569), size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Back to Login',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 384),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida/AEtjO1Vas2R0e1buuUvrIGqWLEEG0V0H59JlDQkO7FLkBmQzzjU6g26vP8Vv7gwG-zwqNkOL5Vt1aieuZmY-keD-332BDvKo4Z8ch1r2Z7W3pz6ghvbkWPY-sQm-2ontpVO2Z0b9NvfhmBnHq1jLSXB2mnbFWuM3sUEcZ_TJ5j4mVJ5lkfDlfHOyIawrb8SIKfLdFmrE0s7ClNCu5B6QaR2lQJbjdb5uK7kB164Ivpb7blvt0VqnGXTiGtHdeq0',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.blueGrey,
                              child: const Icon(Icons.water_drop, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AquaOps',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 30,
                            height: 1.26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.9,
                            color: Color(0xFF171C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Secure dispatch & station portal',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF404751),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF005E9F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your email address to receive passcode reset instructions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF404751),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 2, bottom: 6),
                              child: Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _emailFocus.hasFocus ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: _emailFocus.hasFocus
                                    ? [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    blurRadius: 0,
                                    spreadRadius: 2,
                                  )
                                ]
                                    : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 16, right: 12),
                                    child: Icon(Icons.mail_outline, color: Color(0xFF94A3B8), size: 20),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _resetEmailController,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'user@aquaops.com',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF94A3B8),
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
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9999),
                                  onTap: _isSending ? null : _handleReset,
                                  child: Center(
                                    child: _isSending
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Send Reset Link',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
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
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Remember your password? ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF0284C7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}