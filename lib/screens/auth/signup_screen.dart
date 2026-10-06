import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (!_agreeToTerms) {
      _showError('Please agree to the Terms of Service & Privacy Policy.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: null,
        hasOwnContainers: null,
      );
      if (!mounted) return;
      currentUserRoleNotifier.value = 'customer';
      Navigator.pushNamedAndRemoveUntil(context, '/customer', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_authErrorMessage(e));
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'Sign up failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida/AEtjO1Vas2R0e1buuUvrIGqWLEEG0V0H59JlDQkO7FLkBmQzzjU6g26vP8Vv7gwG-zwqNkOL5Vt1aieuZmY-keD-332BDvKo4Z8ch1r2Z7W3pz6ghvbkWPY-sQm-2ontpVO2Z0b9NvfhmBnHq1jLSXB2mnbFWuM3sUEcZ_TJ5j4mVJ5lkfDlfHOyIawrb8SIKfLdFmrE0s7ClNCu5B6QaR2lQJbjdb5uK7kB164Ivpb7blvt0VqnGXTiGtHdeq0',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80, height: 80, color: Colors.blueGrey,
                              child: const Icon(Icons.water_drop, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AquaOps',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.44,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Secure dispatch & station portal',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3F4850),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006194),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Join the AquaOps network for easy refills and deliveries',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF707881),
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
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildInputField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Elena Gomez',
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildInputField(
                              controller: _phoneController,
                              icon: Icons.call_outlined,
                              hint: '0917 123 4567',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Email Address',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hint: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildPasswordField(
                              controller: _passwordController,
                              hint: 'Create password',
                              isObscure: _obscurePassword,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm password',
                              isObscure: _obscureConfirmPassword,
                              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              icon: Icons.lock_reset_outlined,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      margin: const EdgeInsets.only(top: 2, right: 10),
                                      decoration: BoxDecoration(
                                        color: _agreeToTerms ? const Color(0xFF006194) : const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _agreeToTerms ? const Color(0xFF006194) : const Color(0xFFBFC7D2),
                                          width: 1,
                                        ),
                                      ),
                                      child: _agreeToTerms
                                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'By signing up, you agree to our ',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            color: Color(0xFF3F4850),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms of Service',
                                              style: TextStyle(
                                                color: Color(0xFF006194),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(text: ' & '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: Color(0xFF006194),
                                                fontWeight: FontWeight.w600,
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
                            const SizedBox(height: 12),
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
                                  onTap: _isLoading ? null : _handleRegister,
                                  child: Center(
                                    child: _isLoading
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.13,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3FF),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Color(0xFF006C49), size: 12),
                              const SizedBox(width: 6),
                              const Text(
                                'Instant Setup',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBFC7D2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.water_drop, color: Color(0xFF006194), size: 12),
                              const SizedBox(width: 6),
                              const Text(
                                'Priority Delivery',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF3F4850),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3F4850),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.13,
                                  color: Color(0xFF006194),
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
                fontFamily: 'Plus Jakarta Sans',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
    IconData icon = Icons.lock_outline,
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
              obscureText: isObscure,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
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
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Icon(
                isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF707881),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}