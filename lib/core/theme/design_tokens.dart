import 'package:flutter/material.dart';

/// Spacing values following 8pt grid system
class SpacingTokens {
  static const double xs = 4.0;    // 0.5x
  static const double sm = 8.0;    // 1x
  static const double md = 12.0;   // 1.5x
  static const double lg = 16.0;   // 2x
  static const double xl = 20.0;   // 2.5x
  static const double xxl = 24.0;  // 3x
  static const double xxxl = 32.0; // 4x
  static const double huge = 40.0; // 5x
  static const double massive = 48.0; // 6x
}

/// Border radius tokens
class RadiusTokens {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 28.0;
  static const double round = 32.0;
}

/// Shadow definitions
class ShadowTokens {
  // Subtle elevation
  static final BoxShadow sm = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8.0,
    offset: const Offset(0, 2),
  );

  // Slight elevation (cards, chips)
  static final BoxShadow md = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 12.0,
    offset: const Offset(0, 4),
  );

  // Medium elevation (modals, overlays)
  static final BoxShadow lg = BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 16.0,
    offset: const Offset(0, 8),
  );

  // Strong elevation (floating elements)
  static final BoxShadow xl = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 24.0,
    offset: const Offset(0, 12),
  );

  // Dark mode variations
  static final BoxShadow smDark = BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 8.0,
    offset: const Offset(0, 2),
  );

  static final BoxShadow mdDark = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 12.0,
    offset: const Offset(0, 4),
  );

  static final BoxShadow lgDark = BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 16.0,
    offset: const Offset(0, 8),
  );

  static final BoxShadow xlDark = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 24.0,
    offset: const Offset(0, 12),
  );

  // Get appropriate shadow based on theme
  static BoxShadow getShadow(double elevation, {bool isDark = false}) {
    if (isDark) {
      if (elevation < 2) return smDark;
      if (elevation < 4) return mdDark;
      if (elevation < 8) return lgDark;
      return xlDark;
    } else {
      if (elevation < 2) return sm;
      if (elevation < 4) return md;
      if (elevation < 8) return lg;
      return xl;
    }
  }
}

/// Typography tokens
class TypographyTokens {
  // Display/Hero
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.3,
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.4,
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // Captions
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
  );
}

/// Common gap widgets
class Gaps {
  static const SizedBox xs = SizedBox(height: SpacingTokens.xs);
  static const SizedBox sm = SizedBox(height: SpacingTokens.sm);
  static const SizedBox md = SizedBox(height: SpacingTokens.md);
  static const SizedBox lg = SizedBox(height: SpacingTokens.lg);
  static const SizedBox xl = SizedBox(height: SpacingTokens.xl);
  static const SizedBox xxl = SizedBox(height: SpacingTokens.xxl);
  static const SizedBox xxxl = SizedBox(height: SpacingTokens.xxxl);
  static const SizedBox huge = SizedBox(height: SpacingTokens.huge);

  static const SizedBox hXs = SizedBox(width: SpacingTokens.xs);
  static const SizedBox hSm = SizedBox(width: SpacingTokens.sm);
  static const SizedBox hMd = SizedBox(width: SpacingTokens.md);
  static const SizedBox hLg = SizedBox(width: SpacingTokens.lg);
  static const SizedBox hXl = SizedBox(width: SpacingTokens.xl);
  static const SizedBox hXxl = SizedBox(width: SpacingTokens.xxl);
  static const SizedBox hXxxl = SizedBox(width: SpacingTokens.xxxl);
}
