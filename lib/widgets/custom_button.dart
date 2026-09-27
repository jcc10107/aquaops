import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // USE THEME ENGINE HERE
    final themeColor = Theme.of(context).colorScheme.primary;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? themeColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}