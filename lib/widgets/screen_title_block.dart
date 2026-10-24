import 'package:flutter/material.dart';

/// Reusable title block header shared across Customer Orders and Owner Request screens.
class ScreenTitleBlock extends StatelessWidget {
  final String badgeText;
  final String title;
  final IconData icon;

  const ScreenTitleBlock({
    super.key,
    required this.badgeText,
    required this.title,
    this.icon = Icons.shopping_bag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFF0284C7), size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}