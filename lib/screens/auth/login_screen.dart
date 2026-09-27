// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_card.dart';
import '../../core/components/soft_input_field.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _fillDemo(String role) {
    setState(() {
      _emailController.text = '$role@aquaops.com';
      _passController.text = 'password123';
    });
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      String email = _emailController.text.trim().toLowerCase();

      if (email.contains('owner')) {
        currentUserRoleNotifier.value = 'owner';
        Navigator.pushReplacementNamed(context, '/owner_dashboard');
      } else if (email.contains('staff') || email.contains('pos')) {
        currentUserRoleNotifier.value = 'staff';
        Navigator.pushReplacementNamed(context, '/pos');
      } else if (email.contains('rider')) {
        currentUserRoleNotifier.value = 'rider';
        Navigator.pushReplacementNamed(context, '/dispatch');
      } else {
        currentUserRoleNotifier.value = 'customer';
        Navigator.pushReplacementNamed(context, '/customer');
      }
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
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 32),
                    const Text('DEMO ROLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDemoPill('Owner', isDark),
                        _buildDemoPill('Staff', isDark),
                        _buildDemoPill('Rider', isDark),
                        _buildDemoPill('Customer', isDark),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoPill(String label, bool isDark) {
    return GestureDetector(
      onTap: () => _fillDemo(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(100)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
      ),
    );
  }
}