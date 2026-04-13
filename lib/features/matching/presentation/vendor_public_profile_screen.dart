import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/home/presentation/providers/vendor_provider.dart';
import 'package:eventbridge/features/matching/presentation/widgets/inquiry_bottom_sheet.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';
import 'package:intl/intl.dart';

class VendorPublicProfileScreen extends ConsumerStatefulWidget {
  const VendorPublicProfileScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  ConsumerState<VendorPublicProfileScreen> createState() => _VendorPublicProfileScreenState();
}

class _VendorPublicProfileScreenState extends ConsumerState<VendorPublicProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  late Future<MatchVendor?> _vendorFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });

    _vendorFuture = _loadVendor();
  }

  Future<MatchVendor?> _loadVendor() async {
    // Try to get from matching controller (which checks state first)
    return await ref.read(matchingControllerProvider.notifier).getVendorById(widget.vendorId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateVendorList = ref.watch(matchingControllerProvider.select(
      (s) => s.matches.where((v) => v.id == widget.vendorId).toList(),
    ));
    final stateVendor = stateVendorList.isNotEmpty ? stateVendorList.first : null;

    return FutureBuilder<MatchVendor?>(
      future: _vendorFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We couldn\'t load this vendor\'s profile. Please try again later.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary01,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Go Back', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && stateVendor == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.primary01,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading vendor profile...',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final vendor = stateVendor ?? snapshot.data;
        if (vendor == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              ),
              title: Text('Not Found', style: GoogleFonts.outfit(color: Colors.black)),
            ),
            body: const Center(child: Text('This vendor profile is unavailable.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroSection(context, vendor),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildMainInfo(vendor),
                          const SizedBox(height: 24),
                          _buildStatsCard(vendor),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorColor: AppColors.primary01,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Packages'),
                          Tab(text: 'Reviews'),
                          Tab(text: 'Portfolio'),
                        ],
                      ),
                    ),
                  ),
                  _buildTabContent(vendor),
                ],
              ),
              _buildHeaderBar(context, vendor),
            ],
          ),
          bottomNavigationBar: _buildStickyBottomBar(context, ref, vendor),
        );
      },
    );
  }

  Widget _buildTabContent(MatchVendor vendor) {
    switch (_tabController.index) {
      case 0:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          sliver: SliverToBoxAdapter(child: _OverviewTab(vendor: vendor)),
        );
      case 1:
        return _buildPackagesSliver(vendor);
      case 2:
        return _buildReviewsSliver(vendor);
      case 3:
        return _PortfolioTabView(vendor: vendor);
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  Widget _buildHeaderBar(BuildContext context, MatchVendor vendor) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, child) {
        final double opacity = (offset / 200).clamp(0.0, 1.0);
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).padding.top + 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              boxShadow: [
                if (opacity > 0.8)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: opacity > 0.5 ? Colors.transparent : Colors.white,
                    elevation: opacity > 0.5 ? 0 : 4,
                  ),
                  if (opacity > 0.5)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          vendor.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  Consumer(
                    builder: (context, ref, child) {
                      final isFavorite = ref.watch(matchingControllerProvider.select(
                        (s) => s.favoriteIds.contains(vendor.id),
                      ));
                      return _buildCircleButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: isFavorite ? Colors.red : Colors.black,
                        backgroundColor: opacity > 0.5 ? Colors.transparent : Colors.white,
                        elevation: opacity > 0.5 ? 0 : 4,
                        onPressed: () => ref.read(matchingControllerProvider.notifier).toggleFavorite(vendor.id),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context, MatchVendor vendor) {
    // If portfolio is empty, use avatar as a fallback for the hero section
    final List<String> heroImages = vendor.portfolio.isNotEmpty 
        ? vendor.portfolio 
        : (vendor.avatarUrl != null ? [vendor.avatarUrl!] : []);

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _buildCircleButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Consumer(
            builder: (context, ref, child) {
              final isFavorite = ref.watch(matchingControllerProvider.select(
                (s) => s.favoriteIds.contains(vendor.id),
              ));
              return _buildCircleButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: isFavorite ? Colors.red : Colors.black,
                onPressed: () => ref.read(matchingControllerProvider.notifier).toggleFavorite(vendor.id),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _HeroCarousel(images: heroImages),
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black,
    Color backgroundColor = Colors.white,
    double elevation = 8,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: elevation,
              offset: Offset(0, elevation / 4),
            ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMainInfo(MatchVendor vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                vendor.name,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (vendor.matchScore > 0)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8430A), Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8430A).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(vendor.matchScore * 100).toInt()}% Match',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (vendor.services.isNotEmpty)
              Text(
                vendor.services.first,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            if (vendor.location.isNotEmpty) ...[
              if (vendor.services.isNotEmpty)
                Padding(

                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('•', style: TextStyle(color: const Color(0xFF64748B))),
              ),
              Text(
                vendor.location,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(MatchVendor vendor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: (vendor.avatarUrl?.isNotEmpty == true)
                        ? NetworkImage(vendor.avatarUrl!)
                        : (vendor.portfolio.isNotEmpty
                            ? NetworkImage(vendor.portfolio.first)
                            : const NetworkImage('https://i.pravatar.cc/150')) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (vendor.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary01,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildStatItem(vendor.reviews.length.toString(), 'Reviews'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildStatItem('${vendor.rating} ★', 'Rating'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildStatItem('8', 'Years hosting'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }


  Widget _buildPackagesSliver(MatchVendor vendor) {
    if (vendor.packages.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No packages available.',
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text(
              'Popular Packages',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(
            height: 380,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: vendor.packages.length,
              itemBuilder: (context, index) {
                final isHighlighted = index == 1 || (index == 0 && vendor.packages.length == 1);
                return _buildPackageCard(context, vendor, vendor.packages[index], isHighlighted: isHighlighted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSliver(MatchVendor vendor) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildRecommendationScore(vendor),
          const SizedBox(height: 32),
          Text(
            'What couples are saying',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...vendor.reviews.map((r) => _buildReviewCard(r)),
        ]),
      ),
    );
  }

  Widget _buildRecommendationScore(MatchVendor vendor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            vendor.rating.toString(),
            style: GoogleFonts.outfit(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
            ),
          ),
          Text(
            'Top Recommended',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'High and positive reviews from the clients.\nDelivers with efficiency',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement show all reviews logic
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Text(
                    'All (${vendor.reviews.length}) Reviews',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/submit-review/${vendor.id}'),
                  icon: const Icon(Icons.rate_review_outlined, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    elevation: 0,
                  ),
                  label: Text(
                    'Write Review',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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


  // --- Re-using and slightly modifying existing builders ---



  Widget _buildPackageCard(BuildContext context, MatchVendor vendor, VendorPackage p, {bool isHighlighted = false}) {
    final features = p.description.split('\n').where((s) => s.trim().length > 3).toList();
    if (features.isEmpty || features.length == 1) {
       features.addAll(['Branded Photo Booths', 'Stage Design', 'Table Linens & Runners']);
    }
    final displayFeatures = features.take(4).toList();

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFF7A51) : const Color(0xFFE2E8F0),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: const Color(0xFFFF7A51).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Text(
              p.description,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                if (p.price > 0)
                  Text(
                    'UGX ${p.price.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                  )
                else
                  Text(
                    'Custom',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                  ),
                if (p.price == 0)
                  Padding(
                     padding: const EdgeInsets.only(bottom: 2, left: 6),
                     child: Text('pricing', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B))),
                  )
             ]
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayFeatures.length,
              itemBuilder: (context, idx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                       const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFF7A51), size: 18),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           displayFeatures[idx],
                           style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  InquiryBottomSheet.show(context, vendor, package: p);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7A51), width: 1.5),
                  backgroundColor: isHighlighted ? const Color(0xFFFF7A51) : Colors.white,
                  foregroundColor: isHighlighted ? Colors.white : const Color(0xFFFF7A51),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Make Request',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(VendorReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: r.userImageUrl != null && r.userImageUrl!.isNotEmpty
                    ? NetworkImage(r.userImageUrl!)
                    : null,
                child: r.userImageUrl == null || r.userImageUrl!.isEmpty
                    ? Text(r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : 'U')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          if (index < r.rating.floor()) {
                            return const Icon(Icons.star, color: Color(0xFFFFB800), size: 14);
                          } else if (index < r.rating) {
                            return const Icon(Icons.star_half, color: Color(0xFFFFB800), size: 14);
                          } else {
                            return const Icon(Icons.star_border, color: Color(0xFFFFB800), size: 14);
                          }
                        }),
                        const SizedBox(width: 8),
                        Text(
                          r.date != null ? DateFormat('MMMM yyyy').format(r.date!) : 'Recent Review',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.comment,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }


  Widget _buildStickyBottomBar(BuildContext context, WidgetRef ref, MatchVendor vendor) {
    final isSubmitting = ref.watch(matchingControllerProvider).isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting from',
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'UGX ${vendor.minPackagePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextSpan(
                        text: ' / event',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(32),
            ),
            child: IconButton(
              onPressed: () {
                TopNotificationOverlay.show(
                  context: context,
                  title: 'Messaging Locked',
                  message: 'Please match with ${vendor.name} to activate messaging.',
                  onTap: () {},
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF475569)),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ElevatedButton(
              onPressed: () => InquiryBottomSheet.show(context, vendor),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A51), // Coral color from design
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 0,
              ),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Match with Business', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _OverviewTab extends StatefulWidget {
  final MatchVendor vendor;
  const _OverviewTab({required this.vendor});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendor.businessOverview,
                      maxLines: _isExpanded ? null : 3,
                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'Read less' : 'Read more',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary01,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 20,
                            color: AppColors.primary01,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Use the parent's _buildSimilarServices (we can't call it here easily, 
              // so let's move it to a shared place or pass it)
              // For simplicity, I'll implement it here or call a static-like helper
              _SimilarServicesSection(currentVendor: widget.vendor),
            ],
          ),
        );
      },
    );
  }
}

class _SimilarServicesSection extends ConsumerWidget {
  final MatchVendor currentVendor;
  const _SimilarServicesSection({required this.currentVendor});

  int _calculateSimilarityScore(MatchVendor candidate, MatchVendor current) {
    int score = 0;
    
    // Service Match (+10 per shared service)
    for (final service in current.services) {
      if (candidate.services.contains(service)) {
        score += 10;
      }
    }
    
    // Pro Plan prioritization (+20)
    final planLower = candidate.plan.toLowerCase();
    if (planLower.contains('pro') || planLower.contains('premium')) {
      score += 20;
    }
    
    // Highest Packages weight (+2 per package)
    score += candidate.packages.length * 2;
    
    // Highest Packages weight - High price packages (+5)
    if (candidate.minPackagePrice > 500000) {
      score += 5;
    }
    
    // Ratings prioritization (up to +25)
    score += (candidate.rating * 5).toInt();
    
    return score;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchingControllerProvider).matches;
    final recommendedAsync = ref.watch(recommendedVendorsProvider);
    
    final List<MatchVendor> allCandidates = [...matches];
    
    // Add recommended vendors as fallbacks
    recommendedAsync.whenData((recommendedList) {
      for (final v in recommendedList) {
        if (!allCandidates.any((existing) => existing.id == v.id)) {
          // Parse price string to double for similarity logic
          double parsedPrice = 0;
          if (v.price != null) {
            final numericString = v.price!.replaceAll(RegExp(r'[^0-9]'), '');
            parsedPrice = double.tryParse(numericString) ?? 0;
          }

          allCandidates.add(MatchVendor(
            id: v.id,
            name: v.businessName,
            businessOverview: '',
            services: v.serviceCategories,
            location: v.location,
            plan: 'pro',
            rating: v.rating,
            isVerified: true,
            portfolio: v.images,
            avatarUrl: v.avatarUrl,
            projects: [],
            packages: parsedPrice > 0 ? [VendorPackage(id: 'default', title: 'Basic', description: '', price: parsedPrice)] : [],
            reviews: [],
            socialLinks: {},
            availableDates: [],
          ));
        }
      }
    });

    final candidates = allCandidates.where((v) => v.id != currentVendor.id).toList();
    
    if (candidates.isEmpty && recommendedAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary01)),
      );
    }

    candidates.sort((a, b) {
      final scoreA = _calculateSimilarityScore(a, currentVendor);
      final scoreB = _calculateSimilarityScore(b, currentVendor);
      return scoreB.compareTo(scoreA); // Descending
    });
    
    final similarVendors = candidates.take(10).toList();

    if (similarVendors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Similar services',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: similarVendors.length,
            itemBuilder: (context, index) {
              return _SimilarVendorCard(vendor: similarVendors[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarVendorCard extends StatelessWidget {
  final MatchVendor vendor;
  const _SimilarVendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/vendor-public/${vendor.id}');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      (vendor.avatarUrl?.isNotEmpty == true)
                          ? vendor.avatarUrl!
                          : (vendor.portfolio.isNotEmpty
                              ? vendor.portfolio.first
                              : 'https://picsum.photos/400/300'),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vendor.services.isNotEmpty ? vendor.services.first : "Service",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vendor.minPackagePrice > 0 
                      ? 'UGX ${vendor.minPackagePrice.toStringAsFixed(0)}'
                      : 'Custom',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        vendor.rating.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
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
}

class _HeroCarousel extends StatefulWidget {
  final List<String> images;
  const _HeroCarousel({required this.images});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return Image.network(widget.images[index], fit: BoxFit.cover);
          },
        ),
        Positioned(
          bottom: 48,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1}/${widget.images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioTabView extends StatefulWidget {
  final MatchVendor vendor;
  const _PortfolioTabView({required this.vendor});

  @override
  State<_PortfolioTabView> createState() => _PortfolioTabViewState();
}

class _PortfolioTabViewState extends State<_PortfolioTabView> {
  VendorProject? _selectedProject;

  _CategoryStyle _categoryStyle(String category) {
    switch (category) {
      case 'Weddings':
        return const _CategoryStyle(
          label: 'Weddings',
          icon: Icons.favorite_rounded,
          accent: Color(0xFFFF7A51),
          surface: Color(0xFFFFF1EB),
          gradient: [Color(0xFFFF7A51), Color(0xFFFF9E7E)],
        );
      case 'Corporate':
        return const _CategoryStyle(
          label: 'Corporate',
          icon: Icons.business_center_rounded,
          accent: Color(0xFF5194FF),
          surface: Color(0xFFEBF3FF),
          gradient: [Color(0xFF5194FF), Color(0xFF7EACFF)],
        );
      case 'Parties':
        return const _CategoryStyle(
          label: 'Parties',
          icon: Icons.celebration_rounded,
          accent: Color(0xFFFFB451),
          surface: Color(0xFFFFF7EB),
          gradient: [Color(0xFFFFB451), Color(0xFFFFC87E)],
        );
      default:
        return const _CategoryStyle(
          label: 'Specialty',
          icon: Icons.auto_awesome_rounded,
          accent: Color(0xFFB451FF),
          surface: Color(0xFFF7EBFF),
          gradient: [Color(0xFFB451FF), Color(0xFFC87EFF)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProject != null) {
      return _buildProjectDetailSliver(_selectedProject!);
    }
    return _buildProjectsGridSliver();
  }

  Widget _buildProjectsGridSliver() {
    final projects = widget.vendor.projects;
    if (projects.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: Text('No projects yet.')),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final project = projects[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final category = project.category;
            final style = _categoryStyle(category);

            return _CustomerPortfolioFolderCard(
              project: project,
              projectIndex: index,
              categoryStyle: style,
              isDark: isDark,
              onTap: () => setState(() => _selectedProject = project),
            );
          },
          childCount: projects.length,
        ),
      ),
    );
  }

  Widget _buildProjectDetailSliver(VendorProject project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _categoryStyle(project.category).accent;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedProject = null),
              icon: Icon(Icons.arrow_back_rounded, size: 18, color: accentColor),
              label: Text(
                'Back to Gallery',
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: project.images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusTokens.xl),
                  child: Image.network(
                    project.images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}

class _CustomerPortfolioFolderCard extends StatelessWidget {
  const _CustomerPortfolioFolderCard({
    required this.project,
    required this.projectIndex,
    required this.categoryStyle,
    required this.isDark,
    required this.onTap,
  });

  final VendorProject project;
  final int projectIndex;
  final _CategoryStyle categoryStyle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final folderColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final accentColor = categoryStyle.accent;
    final displayTags = project.tags.take(2).toList();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Tab
          Container(
            margin: const EdgeInsets.only(left: 14),
            width: 70,
            height: 18,
            decoration: BoxDecoration(
              color: folderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Folder Body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: folderColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : accentColor).withValues(
                      alpha: isDark ? 0.2 : 0.08,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail grid
                    _FolderThumbnailPreviews(
                      images: project.images,
                      accentColor: accentColor,
                    ),
                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Bottom info layer
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tags
                          if (displayTags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: displayTags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    tag.toUpperCase(),
                                    style: GoogleFonts.manrope(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 4),
                          // Title
                          Text(
                            project.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Count + Arrow
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${project.images.length} item${project.images.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 10,
                                  color: Colors.white,
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
            ),
          ),
        ],
      ),
    )
    .animate(delay: (projectIndex * 50).ms)
    .fadeIn(duration: 350.ms)
    .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuint);
  }
}

class _FolderThumbnailPreviews extends StatelessWidget {
  const _FolderThumbnailPreviews({
    required this.images,
    required this.accentColor,
  });

  final List<String> images;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: accentColor.withValues(alpha: 0.05),
        child: Center(
          child: Icon(
            Icons.photo_library_outlined,
            size: 32,
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    if (images.length == 1) {
      return Image.network(
        images.first,
        fit: BoxFit.cover,
      );
    }

    // Grid of up to 4 images
    final displayImages = images.take(4).toList();
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: displayImages.length,
      itemBuilder: (context, index) {
        return Image.network(
          displayImages[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: accentColor.withValues(alpha: 0.05),
          ),
        );
      },
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.gradient,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color surface;
  final List<Color> gradient;
}
