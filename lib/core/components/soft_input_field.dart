import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SoftInputField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final bool isObscure;

  const SoftInputField({super.key, required this.label, required this.icon, this.controller, this.isObscure = false, String? initialValue});

  @override
  State<SoftInputField> createState() => _SoftInputFieldState();
}

class _SoftInputFieldState extends State<SoftInputField> {
  late bool _obscureText = widget.isObscure;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textLight, fontSize: 16),
      decoration: InputDecoration(
        hintText: widget.label,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 16),
        prefixIcon: Icon(widget.icon, size: 24, color: isDark ? Colors.white54 : AppColors.primaryLight),
        suffixIcon: widget.isObscure
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 20, color: isDark ? Colors.white54 : AppColors.textSecondary),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF2F3FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.primaryDark : AppColors.cyanElectric, width: 1.5)),
      ),
    );
  }
}
