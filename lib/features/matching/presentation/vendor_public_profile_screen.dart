import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/shared/report_bottom_sheet.dart';

class VendorPublicProfileScreen extends ConsumerWidget {
  const VendorPublicProfileScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MatchVendor?>(
      future: ref.read(matchingControllerProvider.notifier).getVendorById(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F7F8),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary01)),
          );
        }

        final vendor = snapshot.data;
        if (vendor == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vendor not found')),
            body: const Center(child: Text('This vendor profile is unavailable.')),
          );
        }

        final isSubmitting = ref.watch(matchingControllerProvider).isLoading;

        return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, vendor),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 70), // offset for avatar overlap
                _buildHeaderInfo(vendor)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutQuad),
                const SizedBox(height: 32),
                _sectionTitle('About the Business'),
                const SizedBox(height: 12),
                Text(
                  vendor.businessOverview,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Portfolio'),
                    Text(
                      '${vendor.portfolio.take(vendor.maxPortfolioItems).length} items',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary01,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPortfolioGrid(vendor).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Service Packages'),
                    if (vendor.plan == 'business_pro')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'BUSINESS PRO',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...vendor.packages
                    .take(vendor.plan == 'business_pro' ? 6 : 3)
                    .map((p) => _buildPackageCard(p)
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideX(begin: 0.1)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Reviews & Ratings'),
                    TextButton.icon(
                      onPressed: () => context.push('/submit-review/${vendor.id}'),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Write Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary01,
                        textStyle: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...vendor.reviews.map((r) => _buildReviewCard(r)),
                const SizedBox(height: 32),
                _sectionTitle('Connect & Socials'),
                const SizedBox(height: 12),
                _buildSocialLinks(vendor.socialLinks),
                const SizedBox(height: 120), // Bottom bar safe area
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildStickyBottomBar(context, ref, vendor, isSubmitting),
    );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, MatchVendor vendor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A24),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer-home');
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => ReportBottomSheet.show(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (vendor.portfolio.isNotEmpty)
              Image.network(vendor.portfolio.first, fit: BoxFit.cover)
            else
              Container(color: const Color(0xFFCBD5E1)),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Avatar positioned on bottom left extending out
            Positioned(
              left: 24,
              bottom: -50,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F8),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary01.withValues(alpha: 0.2),
                  backgroundImage: vendor.portfolio.length > 1
                      ? NetworkImage(vendor.portfolio[1])
                      : null,
                  child: vendor.portfolio.length <= 1
                      ? Text(
                          vendor.name.substring(0, 1),
                          style: GoogleFonts.roboto(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary01,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(MatchVendor vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                vendor.name,
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A24),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (vendor.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(
              vendor.location,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            RatingBarIndicator(
              rating: vendor.rating,
              itemBuilder: (context, _) => const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
              ),
              itemCount: 5,
              itemSize: 16.0,
            ),
            const SizedBox(width: 6),
            Text(
              '${vendor.rating} (${vendor.reviews.length} views)',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vendor.services.map((svc) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                svc.toUpperCase(),
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B5563),
                  letterSpacing: 0.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A24),
      ),
    );
  }

  Widget _buildPortfolioGrid(MatchVendor vendor) {
    final items = vendor.portfolio.take(vendor.maxPortfolioItems).toList();
    if (items.isEmpty) return const Text('No portfolio items yet.');

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            items[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, p) {
              if (p == null) return child;
              return Container(color: const Color(0xFFF3F4F6));
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFF3F4F6),
              child: const Icon(Icons.broken_image_rounded, color: Color(0xFF9CA3AF), size: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(VendorPackage p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary01.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary01, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  p.title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            p.description,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Starting Price',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Shs ${p.price.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(
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

  Widget _buildReviewCard(VendorReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  r.customerName.substring(0, 1),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r.customerName,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
              ),
              RatingBarIndicator(
                rating: r.rating,
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                ),
                itemCount: 5,
                itemSize: 14.0,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${r.comment}"',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks(Map<String, String> links) {
    if (links.isEmpty) return const Text('No social links provided.');

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: links.entries.map((e) {
        return InkWell(
          onTap: () => _openUrl(e.value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSocialIcon(e.key),
                  size: 18,
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 8),
                Text(
                  _capitalize(e.key),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getSocialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'website':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    WidgetRef ref,
    MatchVendor vendor,
    bool isSubmitting,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/customer-chat/${vendor.id}'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF0369A1),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      await ref
                          .read(matchingControllerProvider.notifier)
                          .sendInquiry(vendor);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Inquiry sent to ${vendor.name}!'),
                          backgroundColor: const Color(0xFF22C55E),
                        ),
                      );
                      context.pop(); // Go back to match results
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Send Inquiry',
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
