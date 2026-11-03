import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validators.dart';
import '../../main.dart'; // for currentUserRoleNotifier
import '../../services/auth_service.dart';
import '../../widgets/auth_brand_header.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  static const String _font = 'Plus Jakarta Sans';

  // Role -> route. Roles not listed here are rejected at login.
  static const Map<String, String> _roleRoutes = {
    'owner': '/owner_dashboard',
    'staff': '/pos',
    'rider': '/dispatch',
    'customer': '/customer',
  };

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Validate inputs
    setState(() {
      _emailError = Validators.validateEmail(email);
      _passwordError = password.isEmpty ? 'Password is required.' : null;
    });

    if (_emailError != null || _passwordError != null) {
      AppToast.showError(
        context,
        'Please check the highlighted fields.',
        title: 'Validation Error',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // 1. Sign in + load Firestore profile (signIn signs out if no profile)
      final profile = await _authService.signIn(email, password);
      if (profile == null) {
        throw Exception('Account profile not found. Please contact support.');
      }

      // 2. Map role enum -> route (rejects unknown roles)
      final role = profile.role.name; // 'owner' | 'staff' | 'rider' | 'customer'
      final route = _roleRoutes[role];
      if (route == null) {
        await _authService.signOut();
        throw Exception('Account has no valid role assigned.');
      }

      // 3. Save role so shellAt() picks the right tabs
      currentUserRoleNotifier.value = role;

      if (!mounted) return;
      AppToast.showSuccess(context, 'Welcome back!', title: 'Login Successful');

      // 4. Go to home and clear the login screen from the back stack
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        getAuthErrorMessage(e),
        title: 'Login Failed',
      );
    } finally {
      // Always stop the spinner (no-op if screen was already replaced)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reusable text field with icon, label and inline error
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
                child: Icon(
                  icon,
                  color: hasError ? AppColors.error : const Color(0xFF707881),
                  size: 18,
                ),
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
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthBrandHeader(
                    title: 'Welcome Back',
                    subtitle: 'Sign in to manage orders & water delivery',
                  ),
                  const SizedBox(height: 28),

                  // Email field
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
                  const SizedBox(height: 14),

                  // Password field with show/hide toggle
                  _buildInputField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: () {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF707881),
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Forgot password (push, so Back returns to login)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign in button (disabled + spinner while loading)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                        'Sign In',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign up link (named route, replaces login)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Color(0xFF3F4850),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text(
                          'Sign Up',
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