import 'package:flutter/material.dart';

class AppColors {
  // ---------------------------------------------------------------------------
  // Brand & Primary Palette
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF006194);
  static const Color primaryContainer = Color(0xFF007BB9);
  static const Color primaryDark = Color(0xFF38BDF8);
  static const Color primarySky = Color(0xFF0284C7);
  static const Color primarySkyDark = Color(0xFF0369A1);
  static const Color tertiary = Color(0xFF0051D5);

  // ---------------------------------------------------------------------------
  // Neutrals, Text & Theme Backgrounds
  // ---------------------------------------------------------------------------
  static const Color backgroundLight = Color(0xFFFAF8FF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);

  static const Color textLight = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF3F4850);
  static const Color textDark = Color(0xFFF8FAFC);

  static const Color outline = Color(0xFF707881);
  static const Color borderLight = Color(0xFFBFC7D2);

  // ---------------------------------------------------------------------------
  // Surfaces & Containers
  // ---------------------------------------------------------------------------
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFF6FAFC);
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color surfaceIce = Color(0xFFF0F9FF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceFaint = Color(0xFFF8F9FE);
  static const Color surfaceDim = Color(0xFFD2D9F4);

  // ---------------------------------------------------------------------------
  // Slate Neutral Scale
  // ---------------------------------------------------------------------------
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ---------------------------------------------------------------------------
  // Sky Blue Scale
  // ---------------------------------------------------------------------------
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE6FD);

  // ---------------------------------------------------------------------------
  // Amber / Warning Scale
  // ---------------------------------------------------------------------------
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // ---------------------------------------------------------------------------
  // Emerald / Success Scale
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);

  // ---------------------------------------------------------------------------
  // Red & Rose Alert Scale
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color errorText = Color(0xFF93000A);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red700 = Color(0xFFB91C1C);

  // ---------------------------------------------------------------------------
  // Blue, Cyan & Teal Status Scales
  // ---------------------------------------------------------------------------
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue700 = Color(0xFF1D4ED8);

  static const Color cyan50 = Color(0xFFECFEFF);
  static const Color cyan200 = Color(0xFFA5F3FC);
  static const Color cyan700 = Color(0xFF0E7490);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color cyanHighlight = Color(0xFF22D3EE);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal800 = Color(0xFF115E59);
  static const Color accentTeal = Color(0xFF14B8A6);

  // ---------------------------------------------------------------------------
  // Functional UI Accents & Badges
  // ---------------------------------------------------------------------------
  static const Color badgeNavy = Color(0xFF283044);
  static const Color routeGreen = Color(0xFF4EDEA3);
  static const Color mintBadge = Color(0xFF6FFBBE);
  static const Color onMint = Color(0xFF002113);
  static const Color accentBlueSoft = Color(0xFFDAE2FD);
  static const Color buttonSecondary = Color(0xFFF1F1F9);
  static const Color buttonSubtle = Color(0xFFF3F4FA);

  // ---------------------------------------------------------------------------
  // Standardized Token Aliases (Point to canonical tokens to avoid duplication)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = primary;
  static const Color secondaryLight = secondary;
  static const Color background = backgroundLight;
  static const Color surfaceLowest = surfaceLight;
  static const Color textMain = textLight;
  static const Color textVariant = textSecondary;
  static const Color outlineVariant = borderLight;
  static const Color tealAccent = accentTeal;

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const LinearGradient vividGradient = LinearGradient(
    colors: [primary, cyanElectric],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}