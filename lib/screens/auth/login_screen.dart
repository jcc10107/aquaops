import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/aqua_logo.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isEmailValid = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);

    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onEmailChanged() {
    final valid = _emailController.text.trim().length > 4;
    if (_isEmailValid != valid) {
      setState(() {
        _isEmailValid = valid;
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.signIn(email, password);
      if (!mounted) return;

      if (user == null) {
        _showError('Account not found. Please contact your station owner.');
        setState(() => _isLoading = false);
        return;
      }

      currentUserRoleNotifier.value = user.role.name;
      switch (user.role) {
        case UserRole.owner:
          Navigator.pushReplacementNamed(context, '/owner_dashboard');
          break;
        case UserRole.staff:
          Navigator.pushReplacementNamed(context, '/pos');
          break;
        case UserRole.rider:
          Navigator.pushReplacementNamed(context, '/dispatch');
          break;
        case UserRole.customer:
          Navigator.pushReplacementNamed(context, '/customer');
          break;
      }
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
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  Widget _buildInputContainer({
    required FocusNode focusNode,
    required Widget child,
  }) {
    final bool isFocused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? const Color(0xFF0284C7) : const Color(0xFFE5E9EB).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ]
            : [],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 384),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AquaLogo(size: 80),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _pulseAnimation.value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0284C7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SYSTEM ONLINE',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF005E9F),
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
                        padding: EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF404751),
                          ),
                        ),
                      ),
                      _buildInputContainer(
                        focusNode: _emailFocus,
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline, color: Color(0xFF005E9F), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  color: Color(0xFF171C1E),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'user@aquaops.com',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFC0C7D3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isEmailValid ? 1.0 : 0.0,
                              child: const Icon(Icons.check_circle, color: Color(0xFF006B5F), size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF404751),
                          ),
                        ),
                      ),
                      _buildInputContainer(
                        focusNode: _passwordFocus,
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: Color(0xFF005E9F), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _passController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  color: Color(0xFF171C1E),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFC0C7D3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF404751),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, right: 4),
                          child: GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF005E9F),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9999),
                            onTap: _isLoading ? null : _handleLogin,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              child: _isLoading
                                  ? const Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New to AquaOps? ',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF404751),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF005E9F),
                              ),
                            ),
                          ),
                        ],
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