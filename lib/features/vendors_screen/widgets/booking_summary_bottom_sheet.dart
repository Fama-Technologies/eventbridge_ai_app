import 'dart:ui' as ui;

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingSummaryBottomSheet extends StatelessWidget {
  const BookingSummaryBottomSheet({
    super.key,
    required this.booking,
    required this.onMessageTap,
    required this.onViewFullDetailsTap,
  });

  final Lead booking;
  final VoidCallback onMessageTap;
  final VoidCallback onViewFullDetailsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkNeutral01 : Colors.white;
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8FAFC);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _ClientAvatar(imageUrl: booking.clientImageUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Booked',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.event_rounded,
                          label: 'Date',
                          value: booking.date.isNotEmpty ? booking.date : 'TBD',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                          value: booking.time.isNotEmpty ? booking.time : 'TBD',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.location_on_rounded,
                          label: 'Venue',
                          value: _venueText(booking),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.groups_rounded,
                          label: 'Guests',
                          value: booking.guests > 0
                              ? '${booking.guests} guests'
                              : 'Not set',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.payments_rounded,
                          label: 'Budget',
                          value: booking.budget > 0
                              ? 'UGX ${booking.budget.toInt()}'
                              : 'Not set',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  if (booking.clientMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Notes',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        booking.clientMessage,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetButton(
                          label: 'Message Client',
                          isPrimary: true,
                          onTap: onMessageTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetButton(
                          label: 'View Full Details',
                          isPrimary: false,
                          isDark: isDark,
                          onTap: onViewFullDetailsTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _venueText(Lead booking) {
    final venue = booking.venueName.trim();
    final address = booking.venueAddress.trim();
    final location = booking.location.trim();

    if (venue.isNotEmpty && address.isNotEmpty) {
      return '$venue, $address';
    }
    if (venue.isNotEmpty) {
      return venue;
    }
    if (address.isNotEmpty) {
      return address;
    }
    if (location.isNotEmpty) {
      return location;
    }
    return 'Venue pending';
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.black12,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.primary01.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: AppColors.primary01),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary01.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary01),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    this.isDark = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary ? AppColors.primary01 : Colors.transparent,
          foregroundColor: isPrimary
              ? Colors.white
              : (isDark ? Colors.white : const Color(0xFF334155)),
          side: isPrimary
              ? null
              : BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
