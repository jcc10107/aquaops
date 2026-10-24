import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized feedback service for showing success, error, and info toasts/snackbars.
class AppToast {
  static const Duration _defaultDuration = Duration(milliseconds: 2800);

  /// Displays a floating success toast with an emerald background.
  static void showSuccess(
      BuildContext context,
      String message, {
        String? title,
        Duration duration = _defaultDuration,
      }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      backgroundColor: const Color(0xFF006C49),
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Displays a floating error toast with the standardized error color.
  static void showError(
      BuildContext context,
      String message, {
        String? title,
        Duration duration = _defaultDuration,
      }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Displays a floating informational toast with a primary blue background.
  static void showInfo(
      BuildContext context,
      String message, {
        String? title,
        Duration duration = _defaultDuration,
      }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      backgroundColor: const Color(0xFF0284C7),
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  static void _showSnackBar(
      BuildContext context, {
        required String message,
        String? title,
        required Color backgroundColor,
        required IconData icon,
        required Duration duration,
      }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}