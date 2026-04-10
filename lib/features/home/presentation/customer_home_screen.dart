import 'dart:async';
import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

import 'providers/category_provider.dart';
import 'providers/match_provider.dart';
import 'providers/vendor_provider.dart';
import 'package:eventbridge/features/home/domain/models/vendor.dart';
import 'package:eventbridge/features/home/presentation/widgets/search_filter_bottom_sheet.dart';

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary01.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (double i = 10; i < size.width; i += 25) {
      for (double j = 10; j < size.height; j += 25) {
        canvas.drawCircle(Offset(i, j), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final recentMatchesAsync = ref.watch(recentMatchesProvider);
    final recommendedVendorsAsync = ref.watch(recommendedVendorsProvider);

    // Global loading state removed for lazy loading

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // SliverAppBar removed as requested ("remove the one ontop")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.grey[700]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'What are you planning today?',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // Color mapped by ShaderMask
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/customer-explore'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search for vendors, events...',
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                height: 20,
                                width: 1,
                                color: Colors.grey[200],
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        const SearchFilterBottomSheet(),
                                  );
                                },
                                child: Icon(
                                  Icons.tune,
                                  color: AppColors.primary01,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _AdsCarousel(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverAppBar(
                pinned: true,
                primary: false,
                elevation: 0,
                backgroundColor: AppColors.backgroundLight.withValues(
                  alpha: 0.95,
                ),
                toolbarHeight: 0,
                collapsedHeight: 0,
                expandedHeight: 65,
                flexibleSpace: FlexibleSpaceBar(
                  background: categoriesAsync.when(
                    data: (categories) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        SearchFilterBottomSheet(
                                          initialCategory: category.name,
                                        ),
                                  );
                                },
                                child: _buildCategoryChip(
                                  category.name,
                                  _getIconData(category.iconName),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Vendor Matches',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.push('/recent-matches'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'View All',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary01,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        recentMatchesAsync.when(
                          data: (matches) => matches.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      'No recent matches found',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 228,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior: Clip.none,
                                    itemCount: matches.length,
                                    itemBuilder: (context, index) {
                                      final match = matches[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: VendorCard(
                                          vendor: Vendor(
                                            id: match.vendorId,
                                            businessName: match.vendorName,
                                            location: match.location,
                                            serviceCategories: [
                                              match.eventType,
                                            ],
                                            avatarUrl: match.imageUrl,
                                            images: match.images,
                                            rating: match.rating,
                                            price: match.budget.toString(),
                                            matchScore: match.matchScore,
                                            matchReasons: match.matchReasons,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              const Text('Failed to load matches'),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AI Recommendations',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.push('/recommendations'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'View All',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary01,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        recommendedVendorsAsync.when(
                          data: (vendors) => vendors.isEmpty
                              ? const SizedBox.shrink()
                              : SizedBox(
                                  height: 228,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior: Clip.none,
                                    itemCount: vendors.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: VendorCard(
                                          vendor: vendors[index],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              const Text('Failed to load recommendations'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildHeader(BuildContext context) {
    final storage = StorageService();
    final fullName = storage.getString('user_name')?.trim();
    final imageUrl = storage.getString('user_image')?.trim();
    final displayName = (fullName == null || fullName.isEmpty)
        ? 'Customer'
        : fullName;
    final greeting = _getGreeting();
    final avatarLetter = displayName.characters.first.toUpperCase();

    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/customer-profile'),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildAvatarFallback(avatarLetter),
                      )
                    : _buildAvatarFallback(avatarLetter),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String avatarLetter) {
    return Center(
      child: Text(
        avatarLetter,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary01.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary01),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary01,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'favorite_border':
      case 'favorite_border_outlined':
        return Icons.favorite_border;
      case 'celebration_outlined':
        return Icons.celebration_outlined;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'cake_outlined':
        return Icons.cake_outlined;
      case 'restaurant':
        return Icons.restaurant;
      case 'music_note':
        return Icons.music_note;
      case 'camera_alt_outlined':
        return Icons.camera_alt_outlined;
      case 'videocam_outlined':
        return Icons.videocam_outlined;
      case 'local_florist':
        return Icons.local_florist;
      case 'event_available':
        return Icons.event_available;
      case 'location_city':
        return Icons.location_city;
      case 'format_paint':
        return Icons.format_paint_outlined;
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'mic':
        return Icons.mic_none_outlined;
      case 'flight':
        return Icons.flight_takeoff_outlined;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'event':
        return Icons.event;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'brush':
        return Icons.brush;
      default:
        return Icons.grid_view_outlined;
    }
  }
}

class _AdsCarousel extends StatefulWidget {
  const _AdsCarousel();

  @override
  State<_AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<_AdsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, String>> _ads = [
    {
      'title': 'Plan Your Dream Wedding',
      'subtitle': 'Find the best planners & venues',
      'image': 'assets/images/promo_wedding.png',
      'color': '#FFF5F5',
    },
    {
      'title': 'Corporate Excellence',
      'subtitle': 'Sleek venues for your next meeting',
      'image': 'assets/images/promo_corporate.png',
      'color': '#F0F7FF',
    },
    {
      'title': 'Artisanal Cakes',
      'subtitle': 'Sweeten your special moments',
      'image': 'assets/images/promo_cakes.png',
      'color': '#FFF9F0',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_controller.hasClients) {
        int nextIndex = (_currentIndex + 1) % _ads.length;
        _controller.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return AnimatedScale(
            scale: _currentIndex == index ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.asset(
                      ad['image']!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ad['title']!,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ad['subtitle']!,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary01,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Explore Now',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Unified VendorCard is now used.

// Unified VendorCard is now used.
