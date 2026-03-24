import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActiveBookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  const ActiveBookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<ActiveBookingDetailsScreen> createState() => _ActiveBookingDetailsScreenState();
}

class _ActiveBookingDetailsScreenState extends State<ActiveBookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final booking = MockLeadRepository.getById(widget.bookingId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Not Found')),
        body: const Center(child: Text('The requested booking could not be found.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, booking, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildStatusBanner(isDark),
                      const SizedBox(height: 32),
                      _buildBookingStats(booking, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Event Schedule', isDark),
                      const SizedBox(height: 16),
                      _buildScheduleItem(
                        icon: Icons.event_available_rounded,
                        label: 'Event Date',
                        value: booking.date,
                        subValue: 'Arrival: 8:00 AM',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildVenueSection(booking, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Financial Overview', isDark),
                      const SizedBox(height: 16),
                      _buildPaymentCard(booking, isDark),
                      const SizedBox(height: 120), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActions(context, booking, isDark),
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
            onTap: () {},
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, required bool isDark}) {
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
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, Lead booking, bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(booking.clientImageUrl, fit: BoxFit.cover),
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
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'CONFIRMED BOOKING',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  Text(
                    booking.title,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary01.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary01.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary01, shape: BoxShape.circle),
            child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preparation Phase',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                ),
                Text(
                  'Event starts in 5 days. Ensure all equipment is ready.',
                  style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildBookingStats(Lead booking, bool isDark) {
    return Row(
      children: [
        _buildStatCard('Total Amount', 'UGX ${booking.budget.toInt()}', Icons.payments_rounded, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Deposit Paid', 'UGX ${(booking.budget * 0.3).toInt()}', Icons.account_balance_wallet_rounded, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary01, size: 24),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }

  Widget _buildScheduleItem({required IconData icon, required String label, required String value, required String subValue, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary01.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary01, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
                Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                Text(subValue, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueSection(Lead booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VENUE', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
                    Text(booking.venueName.isEmpty ? 'To Be Determined' : booking.venueName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                    if (booking.venueAddress.isNotEmpty) Text(booking.venueAddress, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Lead booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary01, AppColors.primary01.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.primary01.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outstanding Balance', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('UGX ${(booking.budget * 0.7).toInt()}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Final payment due 2 days before event.', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Lead booking, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [(isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)).withValues(alpha: 0), isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/vendor-chat/${booking.id}'),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.primary01.withValues(alpha: 0.2))),
                  child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary01, size: 20), const SizedBox(width: 8), Text('Message Client', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary01))])),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
