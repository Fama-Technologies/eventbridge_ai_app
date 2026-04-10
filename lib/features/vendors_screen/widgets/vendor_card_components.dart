import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Reusable metric card for displaying KPIs and stats
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final Color accentColor;
  final String? trend;
  final bool isDark;
  final VoidCallback? onTap;

  const MetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
    this.icon,
    this.trend,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
              ),
              child: icon ?? SizedBox(width: 24, height: 24),
            ),
            Gaps.md,
            // Label
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            Gaps.xs,
            // Value and trend
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (trend != null) ...[
                  Gaps.hSm,
                  Text(
                    trend!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium lead card with better visual hierarchy
class PremiumLeadCard extends StatelessWidget {
  final String clientImage;
  final String clientName;
  final String leadTitle;
  final String date;
  final int guestCount;
  final double budget;
  final bool isHighValue;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  const PremiumLeadCard({
    required this.clientImage,
    required this.clientName,
    required this.leadTitle,
    required this.date,
    required this.guestCount,
    required this.budget,
    this.isHighValue = false,
    required this.isDark,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [ShadowTokens.getShadow(8, isDark: isDark)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.primary01.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar + Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RadiusTokens.lg),
                            boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
                            image: DecorationImage(
                              image: NetworkImage(clientImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Gaps.hLg,
                        // Title section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leadTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (isHighValue)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEF3C7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFD97706),
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              Gaps.xs,
                              Text(
                                clientName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Gaps.xl,
                    // Metrics row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricBadge(
                          Icons.calendar_today_rounded,
                          date,
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.people_alt_rounded,
                          '$guestCount Guests',
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.payments_rounded,
                          'UGX ${budget.toInt()}',
                          isDark,
                        ),
                      ],
                    ),
                    if (trailingWidget != null) ...[
                      Gaps.lg,
                      trailingWidget!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text, bool isDark) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            Gaps.hXs,
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Business Hub quick action tile
class HubActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isDark;
  final bool hasBorder;

  const HubActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    required this.isDark,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: SpacingTokens.lg),
        width: 128,
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: hasBorder
                    ? Border.all(color: const Color(0xFFE0E7FF), width: 1)
                    : null,
              ),
              child: icon,
            ),
            Gaps.md,
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Gaps.xs,
            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button variants for actions
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary01,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          boxShadow: [ShadowTokens.getShadow(8, isDark: isDark)],
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    Gaps.hSm,
                  ],
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary button variant
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 18),
              Gaps.hSm,
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge for bookings/leads
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget? icon;

  const StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            Gaps.hXs,
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
