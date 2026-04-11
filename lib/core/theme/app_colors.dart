import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (New Brand Color: #E8430A)
  static const Color primary01 = Color(0xFFE8430A);
  static const Color primary02 = Color(0xFFB8340A);
  static const Color primary012 = Color(0x66E8430A);

  // Accent Colors (Orange for High-Impact Highlights)
  static const Color accentOrange = Color(0xFFE8430A);
  static const Color accentOrangeLight = Color(0xFFFFF0EB);

  // Neutrals (Light Mode)
  static const Color neutrals01 = Color(0xFFF7F7F7);
  static const Color neutrals02 = Color(0xFFEBEBEB);
  static const Color neutrals03 = Color(0xFFDDDDDD);
  static const Color neutrals04 = Color(0xFFD3D3D3);
  static const Color neutrals05 = Color(0xFFC2C2C2);
  static const Color neutrals06 = Color(0xFFB0B0B0);
  static const Color neutrals07 = Color(0xFF717171);
  static const Color neutrals08 = Color(0xFF5E5E5E);

  // Aliases for compatibility
  static const Color neutral03 = neutrals03;
  static const Color neutral06 = neutrals06;

  // Dark Mode Neutrals
  static const Color darkNeutral01 = Color(0xFF1E1E1E); // Deep background
  static const Color darkNeutral02 = Color(
    0xFF2D2D2D,
  ); // Card/Surface background
  static const Color darkNeutral03 = Color(0xFF3D3D3D); // Border/Divider
  static const Color darkNeutral04 = Color(0xFF888888);
  static const Color darkNeutral06 = Color(0xFFA0A0A0);

  // Text Colors
  static const Color shadesWhite = Color(0xFFFFFFFF);
  static const Color foregroundDark = Color(0xFFF5F5F5);
  static const Color textPremium = Color(0xFFE2E2E2);

  // Errors
  static const Color errorsBg = Color(0xFFFEF8F6);
  static const Color errorsMain = Color(0xFFC13515);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF141414); // Even deeper dark

  // Soft Design Colors from Mockup
  static const Color softPeach = Color(0xFFFEF4F0); // Hero section background
  static const Color warmCream = Color(0xFFFDF8F5); // Light peachy cream
  static const Color softYellow = Color(0xFFFFF8E1); // New Customer card
  static const Color lightYellow = Color(0xFFFFEB3B); // Yellow accent
  static const Color softPurple = Color(0xFFF3E5F5); // AI Features light
  static const Color mediumPurple = Color(0xFFBA68C8); // AI Features medium
  static const Color lightGray = Color(0xFFF8F9FA); // Neutral card backgrounds
  static const Color cardWhite = Color(0xFFFFFFFF); // Pure white for cards
  static const Color softOrange = Color(0xFFFFE0B2); // Light orange variation

  // Status and notification colors
  static const Color notificationBadge = Color(0xFFFF5722); // Notification dot
  static const Color successGreen = Color(0xFF4CAF50); // Success states
  static const Color warningAmber = Color(0xFFFFC107); // Warning states

  // Legacy aliases (if needed)
  static const Color primary = Color(0xFFE8430A);
  static const Color accent = accentOrange;
  static const Color greyIcon = Color(0xFFBDBDBD);

  // ──────────────────────────────────────────────────────────────────────────
  // EventBridge design-system tokens (see claude_prompt/eventbridge_flutter_prompt.md)
  // ──────────────────────────────────────────────────────────────────────────

  // Brand variants used by AppHeader / EventBannerCard / AiBadge
  static const Color primaryDark = Color(0xFFB8340A);
  static const Color primaryLight = Color(0xFFFF6B35);
  static const Color primaryTint = Color(0xFFFFF0EB);

  // Floating pill nav background
  static const Color navBackground = Color(0xFF1A1A1A);

  // Neutral surfaces & text used by the new screens
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color border = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);

  // Event category gradients (mapped from EventModel.category)
  static const List<Color> partyGradient = [
    Color(0xFFB8340A),
    Color(0xFFE8430A),
  ];
  static const List<Color> corporateGradient = [
    Color(0xFF1A237E),
    Color(0xFF3949AB),
  ];
  static const List<Color> travelGradient = [
    Color(0xFF004D40),
    Color(0xFF00897B),
  ];
  static const List<Color> weddingGradient = [
    Color(0xFF4A148C),
    Color(0xFF7B1FA2),
  ];
  static const List<Color> musicGradient = [
    Color(0xFF1A237E),
    Color(0xFF283593),
  ];

  // WhatsApp Theme Colors
  static const waChatBg = Color(0xFFEFEAE2);
  static const waChatBgDark = Color(0xFF0B141A);
  static const waOutgoing = Color(0xFFD9FDD3);
  static const waOutgoingDark = Color(0xFF005C4B);
  static const waIncoming = Color(0xFFFFFFFF);
  static const waIncomingDark = Color(0xFF1F2C33);
  static const waTickBlue = Color(0xFF53BDEB);
  static const waTickGray = Color(0xFF8696A0);
  static const waGreen = Color(0xFF25D366);
  static const waHeader = Color(0xFF008069);
  static const waHeaderDark = Color(0xFF1F2C33);
}
