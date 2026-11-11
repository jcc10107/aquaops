import 'package:flutter/material.dart';
import 'aqua_logo.dart';

/// Reusable brand header block featuring the Aqua logo, screen title, and subtitle
class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double logoSize;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoSize = 120.0, // Increased default size to accommodate the new stacked wordmark
  });

  static const String _fontFamily = 'Plus Jakarta Sans';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AquaOpsLogo(size: logoSize),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.44,
            color: Color(0xFF131B2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3F4850),
          ),
        ),
      ],
    );
  }
}