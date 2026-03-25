import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class PlanUpgradeOverlay extends StatelessWidget {
  const PlanUpgradeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary01.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: AppColors.primary01,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unlock Premium Features',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade your plan to access Leads, Packages, Portfolio, and advanced business tools.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _UpgradeButton(
              title: 'Basic Vendor',
              price: '\$15/mo',
              icon: Icons.business_center_rounded,
              onPressed: () => context.push('/subscription'),
              isPremium: false,
            ),
            const SizedBox(height: 12),
            _UpgradeButton(
              title: 'Premium Vendor',
              price: '\$30/mo',
              icon: Icons.military_tech_rounded,
              onPressed: () => context.push('/subscription'),
              isPremium: true,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final String title;
  final String price;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPremium;

  const _UpgradeButton({
    required this.title,
    required this.price,
    required this.icon,
    required this.onPressed,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPremium
                ? AppColors.primary01
                : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPremium
                  ? AppColors.primary01
                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPremium ? Colors.white24 : AppColors.primary01.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPremium ? Colors.white : AppColors.primary01,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPremium ? Colors.white : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isPremium ? Colors.white70 : (isDark ? Colors.white38 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isPremium ? Colors.white70 : (isDark ? Colors.white24 : Colors.black26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
