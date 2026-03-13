import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:eventbridge_ai/core/theme/app_colors.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upgrade Plan',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Free Trial Active: 1 month free for new vendors',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildPlanCard(
              context: context,
              title: 'Pro',
              priceUsd: '15',
              priceUgx: 'UGX 54,750',
              icon: Icons.business_center_rounded,
              features: [
                'Up to 3 Service Packages',
                'Basic Availability Calendar',
                'Limited AI Matches per month',
                '12 Portfolio Images',
              ],
              buttonLabel: 'Current Plan',
              isActive: true,
              isPremium: false,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              context: context,
              title: 'Business Pro',
              priceUsd: '30',
              priceUgx: 'UGX 109,500',
              icon: Icons.military_tech_rounded,
              features: [
                'Up to 6 Service Packages',
                'Unlimited Calendar & Booking Control',
                'Top Recommendations in AI Matches',
                '20 Portfolio Images',
                'Priority Support',
              ],
              buttonLabel: 'Upgrade to Business Pro',
              isActive: false,
              isPremium: true,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String priceUsd,
    required String priceUgx,
    required IconData icon,
    required List<String> features,
    required String buttonLabel,
    required bool isActive,
    required bool isPremium,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? const Color(0xFF1A1A24) : const Color(0xFFE5E7EB),
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFF1A1A24).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPremium
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPremium ? const Color(0xFFF59E0B) : const Color(0xFF4B5563),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isPremium ? Colors.white : const Color(0xFF1A1A24),
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$$priceUsd',
                style: GoogleFonts.roboto(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isPremium ? Colors.white : const Color(0xFF1A1A24),
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/month',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            priceUgx,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: isPremium
                  ? Colors.white.withValues(alpha: 0.5)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: isPremium ? const Color(0xFFF59E0B) : AppColors.primary01,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: isPremium
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plan upgrade to $title initiated.'),
                          backgroundColor: const Color(0xFF22C55E),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? AppColors.primary01
                    : const Color(0xFFF3F4F6),
                foregroundColor: isPremium
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
