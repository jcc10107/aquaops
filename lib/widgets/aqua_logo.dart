import 'package:flutter/material.dart';

/// Displays the official Aqua Ops brand logo from the raster PNG asset.
class AquaOpsLogo extends StatelessWidget {
  /// The overall width of the logo. The height will scale proportionally
  /// to preserve the exact design and aspect ratio.
  final double size;

  const AquaOpsLogo({
    super.key,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/aqua_ops_logo.png',
      width: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high, // Ensures the PNG stays sharp when scaled
      semanticLabel: 'Aqua Ops Official Logo',
    );
  }
}