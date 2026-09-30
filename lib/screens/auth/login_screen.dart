// lib/screens/auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_card.dart';
import '../../core/components/soft_input_field.dart';
import '../../widgets/custom_button.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

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
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your account email. We\'ll send a link to reset your password.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() => isSending = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _authService.sendPasswordReset(email);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(SnackBar(content: Text('Password reset link sent to $email.'), backgroundColor: AppColors.primaryLight));
                      } on FirebaseAuthException catch (e) {
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(SnackBar(content: Text(_resetErrorMessage(e)), backgroundColor: AppColors.error));
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: AppColors.error));
                      }
                    },
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SoftCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          gradient: AppColors.vividGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text('AquaOps Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textLight)),
                    const SizedBox(height: 8),
                    Text('Secure dispatch & station portal', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 32),
                    SoftInputField(icon: Icons.email, label: 'Email', controller: _emailController),
                    const SizedBox(height: 16),
                    SoftInputField(icon: Icons.lock, label: 'Password', controller: _passController, isObscure: true),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Log In',
                      icon: Icons.arrow_forward,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("New to AquaOps? ", style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text('Sign Up', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}