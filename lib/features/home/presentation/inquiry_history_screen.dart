import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class InquiryHistoryScreen extends StatelessWidget {
  const InquiryHistoryScreen({super.key});

  static const _mockInquiries = [
    _Inquiry('Wedding Reception Setup', 'Elegant Events Co.', 'Apr 3, 2026', 'Accepted', Color(0xFF4CAF50)),
    _Inquiry('Corporate Gala Dinner', 'Kampala Luxe Catering', 'Mar 28, 2026', 'Pending', Color(0xFFFFC107)),
    _Inquiry('Birthday Photoshoot', 'Visual Stories UG', 'Mar 20, 2026', 'Declined', Color(0xFFEF5350)),
    _Inquiry('Garden Party Décor', 'Pearl Floral Designs', 'Mar 15, 2026', 'Accepted', Color(0xFF4CAF50)),
    _Inquiry('Graduation Party DJ', 'SoundWave Entertainment', 'Feb 28, 2026', 'Completed', Color(0xFF2196F3)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Inquiry History', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _mockInquiries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final inq = _mockInquiries[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkNeutral02 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(inq.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: inq.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(inq.status, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: inq.statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 16, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(inq.vendor, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    const SizedBox(width: 4),
                    Text(inq.date, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Inquiry {
  final String title;
  final String vendor;
  final String date;
  final String status;
  final Color statusColor;
  const _Inquiry(this.title, this.vendor, this.date, this.status, this.statusColor);
}
