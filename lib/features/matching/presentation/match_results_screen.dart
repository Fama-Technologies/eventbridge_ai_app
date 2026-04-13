import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';

class MatchResultsScreen extends ConsumerWidget {
  const MatchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingControllerProvider);
    final ctrl = ref.read(matchingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Column(
        children: [
          AppHeader(
            title: 'Your AI Matches',
            showBack: true,
          ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary01),
                  )
                : state.matches.isEmpty
                    ? _buildEmptyState()
                    : AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemCount: state.matches.length + 3, // Header + Results + Suggestions + Padding
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildHeader(state.matches.length);
                            }
                            if (index == state.matches.length + 1) {
                              return _buildSuggestions();
                            }
                            if (index == state.matches.length + 2) {
                              return const SizedBox(height: 120);
                            }

                            final vendor = state.matches[index - 1];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _VendorMatchCard(
                                    vendor: vendor,
                                    isSubmitting: state.isLoading,
                                    onViewProfile: () =>
                                        context.push('/vendor-public/${vendor.id}'),
                                      onInquiry: () async {
                                        final leadId = await ctrl.sendInquiry(vendor: vendor);
                                        if (!context.mounted) return;
                                        
                                        if (leadId != null) {
                                          context.push('/customer-chat/$leadId?otherUserId=${vendor.id}&otherUserName=${Uri.encodeComponent(vendor.name)}');
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Failed to start chat. Please try again.'),
                                              backgroundColor: AppColors.errorsMain,
                                            ),
                                          );
                                        }
                                      },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.primary01,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No matches found',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any vendors matching your exact preferences. Try adjusting your budget or available dates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary01,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We found $count matches',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
                Text(
                  'Based on your preferences and AI analysis',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = ['MC / Host', 'Decor', 'Venue', 'Makeup Artist', 'Cake'];
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People also search for:',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A24),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Center(
                    child: Text(
                      suggestions[index],
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorMatchCard extends StatefulWidget {
  const _VendorMatchCard({
    required this.vendor,
    required this.onViewProfile,
    required this.onInquiry,
    required this.isSubmitting,
  });

  final MatchVendor vendor;
  final VoidCallback onViewProfile;
  final VoidCallback onInquiry;
  final bool isSubmitting;

  @override
  State<_VendorMatchCard> createState() => _VendorMatchCardState();
}

class _VendorMatchCardState extends State<_VendorMatchCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    
    // Flatten images from portfolio and avatar for the carousel
    final List<String> images = [
      if (vendor.avatarUrl != null) vendor.avatarUrl!,
      ...vendor.portfolio.where((url) => url != vendor.avatarUrl),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Carousel & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: images.isEmpty
                      ? Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.storefront_outlined, size: 64, color: Color(0xFF94A3B8)),
                        )
                      : PageView.builder(
                          onPageChanged: (idx) => setState(() => _currentIndex = idx),
                          itemCount: images.length,
                          itemBuilder: (context, idx) => Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                ),
              ),
              // Match Score Badge
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary01,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary01.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${(vendor.matchScore * 100).toInt()}% Match',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite Button
              Positioned(
                top: 20,
                right: 20,
                child: Consumer(
                  builder: (context, ref, child) {
                    final isFavorite = ref.watch(matchingControllerProvider.select((s) => s.favoriteIds.contains(vendor.id)));
                    return GestureDetector(
                      onTap: () => ref.read(matchingControllerProvider.notifier).toggleFavorite(vendor.id),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? const Color(0xFFD64545) : AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Carousel Indicators
              if (images.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length.clamp(0, 5), (idx) {
                      final isActive = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 14 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                vendor.location,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFE0A100), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            vendor.rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  vendor.businessOverview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF475569),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                if (vendor.matchReasons.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vendor.matchReasons.take(3).map((reason) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          reason,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STARTING AT',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          vendor.minPackagePrice > 0 
                              ? 'Shs ${vendor.minPackagePrice.toStringAsFixed(0)}'
                              : 'Price on request',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: widget.onViewProfile,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: Text(
                            'Profile',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: widget.isSubmitting ? null : widget.onInquiry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary01,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          child: widget.isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Message',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ],
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
