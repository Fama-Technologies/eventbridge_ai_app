import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary01,
        primary: AppColors.primary01,
        surface: AppColors.backgroundLight,
        error: AppColors.errorsMain,
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary01,
        primary: AppColors.primary01,
        brightness: Brightness.dark,
        surface: AppColors.darkNeutral02,
        error: Color(0xFFFF6B4F),
      ),
      fontFamily: 'Raleway',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPremium,
          fontFamily: 'WorkSans',
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPremium,
          fontFamily: 'WorkSans',
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPremium,
          fontFamily: 'WorkSans',
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.textPremium),
        bodyMedium: TextStyle(color: AppColors.textPremium),
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardTheme: CardThemeData(
        color: AppColors.darkNeutral02,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static const double borderRadius = 12.0;
}
