import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class LeadMilestoneCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const LeadMilestoneCard({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.primary01.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary01.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary01.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary01,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Request Accepted',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A24),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Inquiry details confirmed',
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
          const SizedBox(height: 24),
          _buildInfoRow(Icons.event_available_rounded, 'Event', data['title'] ?? 'Inquiry'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_rounded, 'Date', data['date'] ?? 'TBD'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoRow(Icons.people_rounded, 'Guests', '${data['guests'] ?? 0}')),
              Expanded(child: _buildInfoRow(Icons.location_on_rounded, 'Location', data['location'] ?? 'Remote')),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message Preview',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['message'] ?? 'No message provided',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Budget',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black54,
                ),
              ),
              Text(
                'UGX ${data['amount']?.toInt() ?? 0}',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary01,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
