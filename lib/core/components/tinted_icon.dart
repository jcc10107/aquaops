import 'package:flutter/material.dart';

class TintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const TintedIcon({
    super.key,
    required this.icon,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}