import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A237E); // Deep Navy (header)
  static const Color accent =
      Color(0xFF3A7DC9); // Brand Blue (primary button / links)
  static const Color secondary = Color(0xFF3A7DC9);
  static const Color danger = Color(0xFFC0392B); // Delete / danger
  static const Color background = Color(0xFFF4F6FB); // Page background
  static const Color cardBg = Color(0xFFFFFFFF); // Cards / sheets white
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E); // Primary text / titles
  static const Color textMid = Color(0xFF555555);
  static const Color textLight = Color(0xFF888888);
  static const Color success = Color(0xFF4CAF50);

  // Status indicators
  static const Color inProgressBg = Color(0xFFEBF3FC);
  static const Color inProgressText = Color(0xFF3A7DC9);

  static const Color todoBg = Color(0xFFF3EAFB);
  static const Color todoText = Color(0xFF9C4DB8);

  static const Color doneBg = Color(0xFFEAF3DE);
  static const Color doneText = Color(0xFF4CAF50);

  static const Color overdueBg = Color(0xFFFFF3E8);
  static const Color overdueText = Color(0xFFE8702A);

  static const Color tagBlue = Color(0xFFBBDEFB);
  static const Color tagGreen = Color(0xFFC8E6C9);
  static const Color tagOrange = Color(0xFFFFE0B2);
  static const Color progressBlue = Color(0xFF3A7DC9);
  static const Color divider = Color(0xFFDDDDDD);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      );
}
