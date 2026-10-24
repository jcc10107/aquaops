import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  /// Standard font family name for AquaOps components
  static const String fontFamily = 'Plus Jakarta Sans';

  /// Unified Plus Jakarta Sans text style helper used across AquaOps screens.
  static TextStyle ts({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}