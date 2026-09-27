// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_card.dart';
import '../../core/components/soft_input_field.dart';
import '../../widgets/custom_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;

  void _handleRegister() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      currentUserRoleNotifier.value = 'customer';
      Navigator.pushNamedAndRemoveUntil(context, '/customer', (route) => false);
    });
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
                      const SoftInputField(icon: Icons.person, label: 'e.g. Elena Santos'),
                      const SizedBox(height: 16),
                      _buildLabel('Mobile Phone', isDark),
                      const SoftInputField(icon: Icons.phone_iphone, label: '+63 917 123 4567'),
                      const SizedBox(height: 16),
                      _buildLabel('Delivery Address', isDark),
                      const SoftInputField(icon: Icons.location_on, label: 'Barangay & Street Address'),
                      const SizedBox(height: 16),
                      _buildLabel('Email Address', isDark),
                      const SoftInputField(icon: Icons.email, label: 'elena@aquaops.com'),
                      const SizedBox(height: 16),
                      _buildLabel('Password', isDark),
                      const SoftInputField(icon: Icons.lock, label: 'At least 8 characters', isObscure: true),
                      const SizedBox(height: 24),
                      _buildLabel('Have empty gallons?', isDark),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.sync, color: Colors.white, size: 16), label: const Text('Yes (1:1 Swap)', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                          const SizedBox(width: 12),
                          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.shopping_cart, color: isDark ? Colors.white : AppColors.textLight, size: 16), label: Text('No (New)', style: TextStyle(color: isDark ? Colors.white : AppColors.textLight)), style: OutlinedButton.styleFrom(backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF2F3FF), side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
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