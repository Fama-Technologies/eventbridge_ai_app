import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:eventbridge/core/theme/app_colors.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer-home');
            }
          },
        ),
        title: Text(
          'Your AI Matches',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: state.isLoading
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
                    itemCount: state.matches.length + 2, // Header + Results + Suggestions
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeader(state.matches.length);
                      }
                      if (index == state.matches.length + 1) {
                        return _buildSuggestions();
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
                                await ctrl.sendInquiry(vendor);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Inquiry sent successfully to ${vendor.name}!',
                                    ),
                                    backgroundColor: const Color(0xFF22C55E),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

class _VendorMatchCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioStrip(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF3F4F6),
                      backgroundImage: vendor.portfolio.isNotEmpty
                          ? NetworkImage(vendor.portfolio.first)
                          : null,
                      child: vendor.portfolio.isEmpty
                          ? Text(
                              vendor.name.substring(0, 1),
                              style: const TextStyle(color: Color(0xFF9CA3AF)),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vendor.name,
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A24),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (vendor.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: vendor.rating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                ),
                                itemCount: 5,
                                itemSize: 14.0,
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                vendor.rating.toString(),
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              Text(
                                ' (${vendor.reviews.length})',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  vendor.businessOverview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vendor.services.take(3).map((svc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        svc.toUpperCase(),
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STARTING AT',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Shs ${vendor.minPackagePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1A24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : onInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary01,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Inquire',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  Widget _buildPortfolioStrip() {
    if (vendor.portfolio.isEmpty) return const SizedBox.shrink();

    // Take up to 3 images, skipping the first one used for avatar
    final images = vendor.portfolio.skip(1).take(3).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                  ),
                ),
              ),
              if (images.length > 1) ...[
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          images[1],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 16),
                          ),
                        ),
                      ),
                      if (images.length > 2) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                images[2],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 16),
                                ),
                              ),
                              if (vendor.portfolio.length > 4)
                                Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: Text(
                                      '+${vendor.portfolio.length - 4}',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
