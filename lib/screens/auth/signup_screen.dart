import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart'; // Added centralized layout constants
import '../../core/utils/app_toast.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_brand_header.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  static const String _font = 'Plus Jakarta Sans';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() {
      _nameError = name.isEmpty ? 'Full name is required.' : null;
      _emailError = Validators.validateEmail(email);
      _phoneError = Validators.validateGCash(
        phone,
        requiredMessage: 'Mobile number is required.',
        invalidMessage: 'Enter a valid 11-digit mobile number.',
      );
      _passwordError = password.length < 6
          ? 'Password must be at least 6 characters.'
          : null;
    });

    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null) {
      AppToast.showError(
        context,
        'Please fix the highlighted fields.',
        title: 'Validation Error',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Account created successfully!',
        title: 'Welcome to AquaOps',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(
        context,
        getAuthErrorMessage(e),
        title: 'Signup Failed',
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    VoidCallback? onChanged,
  }) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
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
            border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
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
                child: Icon(icon, color: hasError ? AppColors.error : const Color(0xFF707881), size: 18),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  onChanged: (_) => onChanged?.call(),
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
              if (suffixIcon != null) suffixIcon,
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
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
                    title: 'Create Account',
                    subtitle: 'Sign up for fast water delivery & tracking',
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    hint: 'e.g. Maria Santos',
                    keyboardType: TextInputType.name,
                    errorText: _nameError,
                    onChanged: () {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    icon: Icons.mail_outline,
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: () {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _phoneCtrl,
                    label: 'Mobile Number',
                    icon: Icons.call_outlined,
                    hint: '0917 123 4567',
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: () {
                      if (_phoneError != null) setState(() => _phoneError = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    hint: 'At least 6 characters',
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: () {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF707881),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
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
                        'Create Account',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Color(0xFF3F4850),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
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
    );
  }
}