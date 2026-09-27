import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SoftCard({super.key, required this.child, this.padding, this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}