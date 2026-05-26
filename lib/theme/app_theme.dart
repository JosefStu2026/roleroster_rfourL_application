import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A237E); // dark navy
  static const Color accent = Color(0xFFE65100);  // orange
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFE8E8E8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMid = Color(0xFF555555);
  static const Color textLight = Color(0xFF888888);
  static const Color success = Color(0xFF4CAF50);
  static const Color inProgress = Color(0xFFFF7043);
  static const Color todo = Color(0xFF90CAF9);
  static const Color tagBlue = Color(0xFFBBDEFB);
  static const Color tagGreen = Color(0xFFC8E6C9);
  static const Color tagOrange = Color(0xFFFFE0B2);
  static const Color progressBlue = Color(0xFF2196F3);
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
