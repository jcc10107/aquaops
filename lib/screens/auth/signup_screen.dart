// lib/screens/auth/signup_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_card.dart';
import '../../core/components/soft_input_field.dart';
import '../../widgets/custom_button.dart';
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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool? _hasEmptyGallons;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address.isEmpty ? null : address,
        hasOwnContainers: _hasEmptyGallons,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(gradient: AppColors.vividGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.3), blurRadius: 20)]),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textLight)),
                const SizedBox(height: 8),
                Text('Sign up to order fresh, clinically purified\nwater delivered fast.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Full Name', isDark),
                      SoftInputField(icon: Icons.person, label: 'e.g. Elena Santos', controller: _nameController),
                      const SizedBox(height: 16),
                      _buildLabel('Mobile Phone', isDark),
                      SoftInputField(icon: Icons.phone_iphone, label: '+63 917 123 4567', controller: _phoneController),
                      const SizedBox(height: 16),
                      _buildLabel('Delivery Address', isDark),
                      SoftInputField(icon: Icons.location_on, label: 'Barangay & Street Address', controller: _addressController),
                      const SizedBox(height: 16),
                      _buildLabel('Email Address', isDark),
                      SoftInputField(icon: Icons.email, label: 'elena@aquaops.com', controller: _emailController),
                      const SizedBox(height: 16),
                      _buildLabel('Password', isDark),
                      SoftInputField(icon: Icons.lock, label: 'At least 8 characters', isObscure: true, controller: _passwordController),
                      const SizedBox(height: 24),
                      _buildLabel('Have empty gallons?', isDark),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _hasEmptyGallons = true),
                              icon: const Icon(Icons.sync, color: Colors.white, size: 16),
                              label: const Text('Yes (1:1 Swap)', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasEmptyGallons == true ? AppColors.primaryLight : (isDark ? AppColors.surfaceDark : const Color(0xFFCBD5E1)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _hasEmptyGallons = false),
                              icon: Icon(Icons.shopping_cart, color: _hasEmptyGallons == false ? Colors.white : (isDark ? Colors.white : AppColors.textLight), size: 16),
                              label: Text('No (New)', style: TextStyle(color: _hasEmptyGallons == false ? Colors.white : (isDark ? Colors.white : AppColors.textLight))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasEmptyGallons == false ? AppColors.primaryLight : (isDark ? AppColors.surfaceDark : const Color(0xFFF2F3FF)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      CustomButton(label: 'Create Account', onPressed: _handleRegister, isLoading: _isLoading, icon: Icons.arrow_forward),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Log In', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textLight)),
    );
  }
}