import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/features/shared/report_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailsScreen({super.key, required this.leadId});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = MockLeadRepository.getById(widget.leadId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Not Found')),
        body: const Center(
          child: Text('The requested lead could not be found.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, lead, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildMatchGaugeSection(lead, isDark),
                      const SizedBox(height: 32),
                      _buildLeadStats(lead, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Event Details', isDark),
                      const SizedBox(height: 16),
                      _buildEventDetailItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value: lead.date,
                        subValue: lead.time,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildVenueCard(lead, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Client Message', isDark),
                      const SizedBox(height: 16),
                      _buildPremiumMessage(lead, isDark),
                      const SizedBox(height: 160), // Space for bottom sheet
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildFloatingActions(context, lead, isDark),
          _buildTopBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
            isDark: isDark,
          ),
          _buildGlassButton(
            icon: Icons.more_horiz_rounded,
            onTap: () => ReportBottomSheet.show(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, Lead lead, bool isDark) {
    return SliverAppBar(
      expandedHeight: 340,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              lead.clientImageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                  ],
                  stops: const [0.0, 0.4, 0.95],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lead.isHighValue)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary01.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'PREMIUM LEAD',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Text(
                    lead.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.2).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF22C55E),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline • Last active ${lead.lastActive}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchGaugeSection(Lead lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: lead.matchScore / 100,
                  strokeWidth: 10,
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary01),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${lead.matchScore.toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expert Match',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This client’s requirements perfectly align with your services.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadStats(Lead lead, bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          'Budget',
          'USh ${lead.budget.toInt().toString()}',
          Icons.payments_outlined,
          isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Size',
          '${lead.guests}',
          Icons.people_outline_rounded,
          isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Response',
          lead.responseTime,
          Icons.timer_outlined,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A24),
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary01, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A24),
                  ),
                ),
                Text(
                  subValue,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(Lead lead, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF22C55E), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VENUE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.venueName,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1A24),
                        ),
                      ),
                      Text(
                        lead.venueAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1524613032530-449a5d94c285?auto=format&fit=crop&q=80&w=600',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Open in Maps',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMessage(Lead lead, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.primary01.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary01.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: AppColors.primary01, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lead.clientMessage,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937),
              height: 1.6,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context, Lead lead, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)).withValues(alpha: 0.0),
              (isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)).withValues(alpha: 0.9),
              isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.2, 0.4],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      'Decline',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  _showPremiumSuccess(context);
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    context.push('/vendor-chat/${lead.id}');
                  });
                },
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary01, AppColors.primary01.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary01.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Accept Lead',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumSuccess(BuildContext context) {
    final entry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary01.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  'LEAD ACCEPTED',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opening your chat now...',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack).fadeIn().then().fadeOut(delay: const Duration(seconds: 1)),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }
}
