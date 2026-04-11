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
        secondary: AppColors.accentOrange,
        surface: AppColors.backgroundLight,
        error: AppColors.errorsMain,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.primary01,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary01),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.neutrals03.withValues(alpha: 0.5),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary01,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary01,
          side: const BorderSide(color: AppColors.primary01, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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

// ────────────────────────────────────────────────────────────────────────────
// EventBridge design-system token classes
// (canonical spec: claude_prompt/eventbridge_flutter_prompt.md)
//
// These mirror the prompt's named API. They intentionally live alongside
// the existing SpacingTokens / RadiusTokens / TypographyTokens in
// design_tokens.dart so the new shared widgets can import a single file.
// ────────────────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppRadius {
  static const double chip = 20.0;
  static const double button = 12.0;
  static const double card = 14.0;
  static const double banner = 16.0;
  static const double pill = 40.0;
}

class AppTextStyles {
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle cardTitleWhite = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );
  static const TextStyle tagWhite = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(0xBFFFFFFF),
    letterSpacing: 0.5,
  );
}
