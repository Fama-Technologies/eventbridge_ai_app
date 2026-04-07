import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';

/// Main card for displaying leads in a grid/list
/// Shows client avatar, title, client name, metrics, message preview, and status badge
class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final bool isDark;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.isDark,
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
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar + Title + Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RadiusTokens.lg),
                            boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
                            image: DecorationImage(
                              image: NetworkImage(lead.clientImageUrl),
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
                                      lead.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (lead.isHighValue)
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
                                lead.clientName,
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
                          lead.date,
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.people_alt_rounded,
                          '${lead.guests} Guests',
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.payments_rounded,
                          'UGX ${lead.budget.toInt()}',
                          isDark,
                        ),
                      ],
                    ),
                    Gaps.lg,

                    // Recent message preview (if exists)
                    if (lead.clientMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client Message',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Gaps.sm,
                            Text(
                              lead.clientMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Gaps.lg,

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(lead.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Text(
                        lead.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(lead.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'completed':
        return const Color(0xFF3B82F6); // Blue
      default:
        return AppColors.primary01; // Orange
    }
  }
}

/// Lead header card for bottom sheet display
/// Shows premium badge, lead title, client info, and match score
class LeadHeaderCard extends StatelessWidget {
  final Lead lead;
  final bool isDark;

  const LeadHeaderCard({
    super.key,
    required this.lead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium badge
        if (lead.isHighValue)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: AppColors.primary01, size: 14),
                Gaps.hXs,
                Text(
                  'PREMIUM LEAD',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary01,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        if (lead.isHighValue) Gaps.md,

        // Lead title
        Text(
          lead.title,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        Gaps.md,

        // Client info row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                image: DecorationImage(
                  image: NetworkImage(lead.clientImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Gaps.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Gaps.xs,
                  Text(
                    'Match Score: ${lead.matchScore}%',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 3-column stat display for budget, guests, and response time
/// Each stat displayed in its own card with icon
class LeadStatsGrid extends StatelessWidget {
  final Lead lead;
  final bool isDark;

  const LeadStatsGrid({
    super.key,
    required this.lead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Budget',
            'UGX ${lead.budget.toInt()}',
            Icons.payments_rounded,
            isDark,
          ),
        ),
        Gaps.hMd,
        Expanded(
          child: _buildStatCard(
            'Guests',
            '${lead.guests}',
            Icons.people_alt_rounded,
            isDark,
          ),
        ),
        Gaps.hMd,
        Expanded(
          child: _buildStatCard(
            'Response',
            lead.responseTime,
            Icons.timer_rounded,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.lg,
        horizontal: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary01, size: 20),
          Gaps.md,
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Gaps.xs,
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
