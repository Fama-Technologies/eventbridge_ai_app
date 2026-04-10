import 'package:flutter/material.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:eventbridge/core/widgets/plan_upgrade_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet.dart';
import 'package:eventbridge/features/vendors_screen/widgets/vendor_card_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';
import 'dart:ui';

class VendorHomeScreenImproved extends ConsumerStatefulWidget {
  const VendorHomeScreenImproved({super.key});

  @override
  ConsumerState<VendorHomeScreenImproved> createState() =>
      _VendorHomeScreenImprovedState();
}

class _VendorHomeScreenImprovedState extends ConsumerState<VendorHomeScreenImproved>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _hasNotifications = true;
  String? _planName;
  String? _serviceCategory;
  bool _isVerified = false;
  late AnimationController _meshController;
  int _totalLeadsCount = 0;
  int _profileViewsCount = 0;
  int _bookingsCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDashboardData();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _loadDashboardData() {
    _loadPlan();
    _fetchLeads();
    _fetchStats();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;
      final result = await ApiService.instance.getVendorBookings(userId);
      if (mounted && result['success'] == true) {
        final List bookings = result['bookings'] ?? [];
        setState(() => _bookingsCount = bookings.length);
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  Future<void> _fetchLeads() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      await ref.read(sharedLeadStateProvider.notifier).fetchLeads(userId);
    } catch (e) {
      debugPrint('Error fetching leads: $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorDashboardStats(userId);
      if (mounted && result['success'] == true) {
        setState(() {
          _totalLeadsCount = int.tryParse(
                  result['stats']['totalLeads']?.toString() ?? '0') ??
              0;
          _profileViewsCount = int.tryParse(
                  result['stats']['profileViews']?.toString() ?? '0') ??
              0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  void _loadPlan() {
    final storage = StorageService();
    setState(() => _planName = storage.getString('vendor_plan'));
    if (_planName == null) _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    try {
      final storage = StorageService();
      final userId = storage.getString('user_id');
      if (userId == null) return;
      final result = await ApiService.instance.getVendorProfile(userId);
      if (result['success'] == true && result['profile'] != null) {
        final plan = result['profile']['subscriptionPlan'] ?? 'Basic';
        if (mounted) {
          final List<dynamic> categories =
              result['profile']['serviceCategories'] ?? [];
          setState(() {
            _planName = plan;
            _serviceCategory = categories.isNotEmpty
                ? categories.first.toString()
                : 'Vendor';
            _isVerified = result['profile']['isVerifiedBadge'] == true;
          });
          storage.setString('vendor_plan', plan);
          if (categories.isNotEmpty) {
            storage.setString('vendor_category', categories.first.toString());
          }
        }
      }
    } catch (_) {}
  }

  bool _isRestricted() => _planName?.toLowerCase() == 'free';

  void _showUpgradeOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const PlanUpgradeOverlay(),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storage = StorageService();
    final userName = storage.getString('user_name') ?? 'Vendor';
    final userImage = storage.getString('user_image');

    // Watch the provider for leads
    final leads = ref.watch(sharedLeadStateProvider);
    final filteredLeads = leads.where((l) {
      if (_searchController.text.isEmpty) return true;
      return l.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
             l.clientName.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primary01,
      body: Column(
        children: [
          _buildHeader(isDark, userName, userImage),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(RadiusTokens.round)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: Gaps.xl),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySearchBarDelegate(
                      child: Container(
                        color: isDark
                            ? AppColors.backgroundDark
                            : const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xxl,
                          vertical: SpacingTokens.lg,
                        ),
                        child: _buildSearchBar(isDark),
                      ),
                    ),
                  ),
                  Gaps.lg,
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_searchController.text.isEmpty) ...[
                          _buildSectionHeader(context, "Business Insights", isDark),
                          Gaps.lg,
                          _buildInsightsDashboard(isDark),
                          Gaps.xxxl,
                          _buildSectionHeader(
                              context, "Quick Actions", isDark),
                          Gaps.lg,
                          _buildBusinessHub(context, isDark),
                          Gaps.xxxl,
                        ],
                        _buildSectionHeader(
                          context,
                          _searchController.text.isEmpty
                              ? "Recent Leads"
                              : "Search Results",
                          isDark,
                          showViewAll: _searchController.text.isEmpty,
                        ),
                        Gaps.lg,
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                    sliver: filteredLeads.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildEmptyLeadsState(isDark),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return PremiumLeadCard(
                                  clientImage: filteredLeads[index]
                                      .clientImageUrl,
                                  clientName:
                                      filteredLeads[index].clientName,
                                  leadTitle: filteredLeads[index].title,
                                  date: filteredLeads[index].date,
                                  guestCount: filteredLeads[index].guests,
                                  budget: filteredLeads[index].budget,
                                  isHighValue:
                                      filteredLeads[index].isHighValue,
                                  isDark: isDark,
                                  onTap: () {
                                    if (_isRestricted()) {
                                      _showUpgradeOverlay();
                                      return;
                                    }
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor:
                                          Colors.transparent,
                                      builder: (context) =>
                                          LeadDetailsBottomSheet(
                                            leadId:
                                                filteredLeads[index].id,
                                          ),
                                    );
                                  },
                                )
                                    .animate()
                                    .fadeIn(
                                      delay:
                                          (index * 100).ms,
                                      duration: 400.ms,
                                    )
                                    .slideX(
                                      begin: 0.1,
                                      end: 0,
                                    );
                              },
                              childCount: filteredLeads.length,
                            ),
                          ),
                  ),
                  SliverToBoxAdapter(child: Gaps.huge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, String userName, String? userImage) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary01,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF97316),
            Color(0xFFEA580C),
            Color(0xFFFF5722),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: MeshPainter()),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.xxl,
                SpacingTokens.lg,
                SpacingTokens.xxl,
                SpacingTokens.xxxl,
              ),
              child: Row(
                children: [
                  _buildAvatar(userImage, userName),
                  Gaps.hLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_isVerified) ...[
                              Gaps.hSm,
                              const Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                        Gaps.xs,
                        Text(
                          "${_serviceCategory ?? 'Vendor'} | $_bookingsCount bookings",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationBell(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? userImage, String userName) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            boxShadow: [ShadowTokens.xl],
          ),
          child: ClipOval(
            child: (userImage != null && userImage.isNotEmpty)
                ? Image.network(userImage, fit: BoxFit.cover)
                : _buildInitialsPlaceholder(userName),
          ),
        ),
        if (_planName?.toLowerCase() == 'business_pro')
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.king_bed_rounded,
                  size: 12, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () {
        if (_isRestricted()) {
          _showUpgradeOverlay();
          return;
        }
        context.push('/vendor-notifications');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26),
          ),
          if (_hasNotifications)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () {
        if (_isRestricted()) {
          _showUpgradeOverlay();
          return;
        }
        context.push('/vendor-search');
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: isDark ? Colors.white60 : Colors.black45, size: 24),
            Gaps.hMd,
            Expanded(
              child: Text(
                "Search leads...",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: AppColors.primary01, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsDashboard(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: "Total Leads",
            value: "$_totalLeadsCount",
            accentColor: const Color(0xFFF59E0B),
            isDark: isDark,
            icon: const Icon(PhosphorIconsFill.chartBar,
                color: Color(0xFFF59E0B), size: 32),
          ),
        ),
        Gaps.hMd,
        Expanded(
          child: MetricCard(
            label: "Profile Views",
            value: "$_profileViewsCount",
            accentColor: const Color(0xFF10B981),
            isDark: isDark,
            icon: const Icon(PhosphorIconsFill.chartLineUp,
                color: Color(0xFF10B981), size: 32),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildBusinessHub(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          HubActionTile(
            label: "Packages",
            subtitle: "Manage services",
            backgroundColor: const Color(0xFFEEF2FF),
            icon: SvgPicture.asset(
              'assets/icons/package-box-premium.svg',
              width: 32,
              height: 32,
              colorFilter: const ColorFilter.mode(
                  Color(0xFF4F46E5), BlendMode.srcIn),
            ),
            onTap: () {
              if (_isRestricted()) {
                _showUpgradeOverlay();
                return;
              }
              context.push('/vendor-packages');
            },
            isDark: isDark,
          ),
          HubActionTile(
            label: "Calendar",
            subtitle: "View bookings",
            backgroundColor: Colors.white,
            icon: SvgPicture.asset(
              'assets/icons/calendar-5-premium.svg',
              width: 32,
              height: 32,
              colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
            ),
            onTap: () {
              if (_isRestricted()) {
                _showUpgradeOverlay();
                return;
              }
              context.push('/vendor-calendar');
            },
            isDark: isDark,
            hasBorder: true,
          ),
          HubActionTile(
            label: "Portfolio",
            subtitle: "Show your work",
            backgroundColor: const Color(0xFFFFF1F2),
            icon: SvgPicture.asset(
              'assets/icons/briefcase-premium.svg',
              width: 32,
              height: 32,
              colorFilter: const ColorFilter.mode(
                  Color(0xFFE11D48), BlendMode.srcIn),
            ),
            onTap: () {
              if (_isRestricted()) {
                _showUpgradeOverlay();
                return;
              }
              context.push('/vendor-portfolio');
            },
            isDark: isDark,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyLeadsState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.lg),
      padding: const EdgeInsets.all(SpacingTokens.xxxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(RadiusTokens.round),
        border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/megaphone-premium.svg',
            width: 80,
            height: 80,
            colorFilter: const ColorFilter.mode(
                AppColors.primary01, BlendMode.srcIn),
          ),
          Gaps.xxl,
          Text(
            "No leads yet 👋",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Gaps.lg,
          Text(
            "Share your profile or add packages to get started.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
          Gaps.xxl,
          PrimaryButton(
            label: "Create Package",
            onTap: () => context.push('/vendor-packages'),
            isDark: isDark,
            icon: Icons.add_rounded,
            width: double.infinity,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark,
      {bool showViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        if (showViewAll)
          Text(
            "View all",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary01,
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsPlaceholder(String name) {
    String initials = 'V';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }
    return Container(
      color: const Color(0xFF1E1E2E),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySearchBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 76;
  @override
  double get minExtent => 76;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < 10; i++) {
      path.moveTo(0, i * size.height / 8);
      path.quadraticBezierTo(
        size.width / 2,
        (i + 1) * size.height / 8,
        size.width,
        i * size.height / 8,
      );
    }
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 20; i++) {
      final x = (i * 123) % size.width;
      final y = (i * 321) % size.height;
      canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
