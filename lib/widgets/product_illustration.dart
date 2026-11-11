import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A simple generated illustration (not a photo) used as the default product
/// image until the owner uploads a real one — fills whatever box it is
/// given with a large, bold icon (not a small one lost in empty padding),
/// varied by product id so the four products stay distinguishable.
class ProductIllustration extends StatelessWidget {
  final String productId;

  const ProductIllustration({super.key, required this.productId});

  bool get _isNew => productId.startsWith('n_');

  IconData get _icon {
    switch (productId) {
      case 'r_slim':
        return Icons.water_drop_rounded;
      case 'r_round':
        return Icons.local_drink_rounded;
      case 'n_slim':
        return Icons.propane_tank_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = _isNew ? AppColors.primarySky : AppColors.sky50;
    final Color iconColor = _isNew ? Colors.white : AppColors.primarySky;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.75)],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.cover,
        child: Icon(_icon, size: 120, color: iconColor),
      ),
    );
  }
}
