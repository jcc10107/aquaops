import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable top back-navigation header used across profile sub-screens.
/// Standardizes the back arrow icon, typography, touch target padding,
/// and pop navigation behavior.
class SubScreenHeader extends StatelessWidget {
  /// The label displayed next to the back arrow (defaults to 'Back to Profile')
  final String title;

  /// Optional custom tap handler. Defaults to `Navigator.maybePop(context)`.
  final VoidCallback? onBack;

  const SubScreenHeader({
    super.key,
    this.title = 'Back to Profile',
    this.onBack,
  });

  static const String _font = 'Plus Jakarta Sans';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, color: AppColors.slate600, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _font,
                      color: AppColors.slate600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}