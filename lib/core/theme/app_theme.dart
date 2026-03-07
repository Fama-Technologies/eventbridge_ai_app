import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors
  static const Color primary01 = Color(0xFFFF3C00);
  static const Color primary02 = Color(0xFFFF451A);
  static const Color primary012 = Color(0x66FF7043);

  // Neutrals (Light Mode)
  static const Color neutrals01 = Color(0xFFF7F7F7);
  static const Color neutrals02 = Color(0xFFEBEBEB);
  static const Color neutrals03 = Color(0xFFDDDDDD);
  static const Color neutrals04 = Color(0xFFD3D3D3);
  static const Color neutrals05 = Color(0xFFC2C2C2);
  static const Color neutrals06 = Color(0xFFB0B0B0);
  static const Color neutrals07 = Color(0xFF717171);
  static const Color neutrals08 = Color(0xFF5E5E5E);

  // Errors
  static const Color errorsBg = Color(0xFFFEF8F6);
  static const Color errorsMain = Color(0xFFC13515);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF222222);
}

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
      textTheme: GoogleFonts.interTextTheme(),
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary01,
        primary: Color(0xFFFF7043), // Primary dark mode from spec
        brightness: Brightness.dark,
        surface: AppColors.backgroundDark,
        error: Color(0xFFFF6B4F), // Error main dark mode from spec
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
