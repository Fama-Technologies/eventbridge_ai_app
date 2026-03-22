import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/shared/widgets/customer_bottom_navbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

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
      body: Stack(
        children: [
          _buildBackgroundAura(context),
          CustomScrollView(
            slivers: [
              _buildHeader(context, matches.length, matchingState.request?.eventType),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _buildSectionHeader('Top AI Matches'),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTopPicksCarousel(matches.take(3).toList())
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: 0.1),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Verified for You'),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary01.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tune_rounded,
                                  size: 14, color: AppColors.primary01),
                              const SizedBox(width: 6),
                              Text(
                                'Filter',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary01,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final v = matches[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: _VerifiedVendorTile(vendor: v)
                          .animate()
                          .fadeIn(delay: (400 + (i * 100)).ms)
                          .slideY(begin: 0.1),
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
                      child: Text('No matches found for your criteria.', style: GoogleFonts.outfit(color: Colors.black38)),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
      bottomNavigationBar:
          const CustomerBottomNavbar(currentRoute: '/ai-results'),
    );
  }

  Widget _buildBackgroundAura(BuildContext context) {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary01.withValues(alpha: 0.08),
              AppColors.primary01.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count, String? eventType) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.primary01),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary01, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'AI ANALYSIS COMPLETE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary01,
                          letterSpacing: 1,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .shimmer(duration: 2.seconds, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              count > 0 ? 'We found $count matches for your ${eventType ?? 'Event'}' : 'Analyzing results...',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primary01,
                height: 1.1,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.primary01.withValues(alpha: 0.6),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTopPicksCarousel(List<MatchVendor> topPicks) {
    return SizedBox(
      height: 380,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemCount: topPicks.length,
        itemBuilder: (context, i) => _TopPickCard(pick: topPicks[i]),
      ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  final MatchVendor pick;
  const _TopPickCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                child: Image.network(
                  pick.portfolio.isNotEmpty ? pick.portfolio.first : 'https://via.placeholder.com/400',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary01, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${(90 + (pick.rating * 2)).toInt()}% MATCH',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary01,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick.name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary01,
                  ),
                ),
                Text(
                  pick.services.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/vendor-public/${pick.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary01,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Profile',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/customer-chat/${pick.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.primary01.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Text(
                              'Chat',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary01,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedVendorTile extends StatelessWidget {
  final MatchVendor vendor;
  const _VerifiedVendorTile({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendor-public/${vendor.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                vendor.portfolio.isNotEmpty ? vendor.portfolio.first : 'https://via.placeholder.com/150',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary01,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor.rating} (${vendor.reviews.length} reviews)',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Starting at Shs ${vendor.minPackagePrice}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary01,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF), size: 24),
          ],
        ),
      ),
    );
  }
}
