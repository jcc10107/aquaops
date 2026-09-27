import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: AppColors.primaryLight,
    fontFamily: 'Plus Jakarta Sans',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textLight,
      outline: Colors.transparent,
      surfaceContainerHighest: Color(0xFFF2F3FF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textLight),
      titleTextStyle: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        )),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primaryDark,
    fontFamily: 'Plus Jakarta Sans',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
      outline: Colors.transparent,
      surfaceContainerHighest: Color(0xFF0F172A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        )),
  );
}