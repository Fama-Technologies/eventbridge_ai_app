import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/shared/widgets/customer_bottom_navbar.dart';

/// A premium results screen shown after AI analysis.
class AiResultsScreen extends ConsumerWidget {
  const AiResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingState = ref.watch(matchingControllerProvider);
    final List<MatchVendor> matches = matchingState.matches;
    final hasResults = matches.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, matches.length, matchingState.request?.eventType, hasResults),

          // Top picks horizontal scroll
          if (hasResults) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  'TOP AI PICKS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutrals07,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemCount: matches.take(3).length,
                  itemBuilder: (context, i) => _TopPickCard(pick: matches[i]),
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ALL MATCHES',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutrals07,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutrals03),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 14, color: AppColors.neutrals08),
                        const SizedBox(width: 6),
                        Text(
                          'Filter',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutrals08,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vendor list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final v = matches[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: _VendorTile(vendor: v)
                      .animate()
                      .fadeIn(delay: (200 + (i * 80)).ms)
                      .slideY(begin: 0.08),
                );
              },
              childCount: matches.length,
            ),
          ),

          if (!hasResults)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.neutrals04),
                      const SizedBox(height: 16),
                      Text(
                        'No matches found for your criteria.',
                        style: GoogleFonts.outfit(color: AppColors.neutrals07, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavbar(currentRoute: '/ai-results'),
    );
  }

  Widget _buildHeader(BuildContext context, int count, String? eventType, bool hasResults) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/customer-home');
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutrals08),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary01, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'AI COMPLETE',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary01,
                          letterSpacing: 1,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .shimmer(duration: 2.seconds, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasResults)
                  GestureDetector(
                    onTap: () => context.push('/ai-results-map'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                        ],
                      ),
                      child: const Icon(Icons.map_outlined, size: 18, color: AppColors.primary01),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count > 0 ? 'We found $count matches for your ${eventType ?? 'Event'}' : 'No matches found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.neutrals08,
                height: 1.2,
              ),
            ).animate().fadeIn().slideX(begin: -0.05),
          ],
        ),
      ),
    );
  }
}

/// Clean vendor list tile
class _VendorTile extends StatelessWidget {
  final MatchVendor vendor;
  const _VendorTile({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final matchPercent = (vendor.matchScore * 100).toInt();

    return GestureDetector(
      onTap: () => context.push('/vendor-public/${vendor.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vendor image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                vendor.portfolio.isNotEmpty ? vendor.portfolio.first : 'https://via.placeholder.com/150',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 72,
                  height: 72,
                  color: AppColors.neutrals02,
                  child: const Icon(Icons.broken_image_rounded, color: AppColors.neutrals06, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutrals08,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary01.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$matchPercent%',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary01,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    vendor.services.take(3).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutrals07,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warningAmber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        vendor.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutrals08,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.neutrals06),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          vendor.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.neutrals07,
                          ),
                        ),
                      ),
                      if (vendor.minPackagePrice > 0)
                        Text(
                          'UGX ${vendor.minPackagePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary01,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutrals06, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal top pick card
class _TopPickCard extends StatelessWidget {
  final MatchVendor pick;
  const _TopPickCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    final matchPercent = (pick.matchScore * 100).toInt();

    return GestureDetector(
      onTap: () => context.push('/vendor-public/${pick.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    pick.portfolio.isNotEmpty ? pick.portfolio.first : 'https://via.placeholder.com/300',
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      color: AppColors.neutrals02,
                      child: const Center(child: Icon(Icons.image_not_supported_rounded, color: AppColors.neutrals06, size: 24)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary01, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          '$matchPercent%',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutrals08,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutrals08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pick.services.take(2).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.neutrals07,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warningAmber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        pick.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.neutrals08),
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
}
