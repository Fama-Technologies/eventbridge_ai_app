import 'package:flutter/material.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Lead> _filteredLeads = [];
  bool _hasNotifications = true;
  String? _planName;
  bool _isVerified = false;
  late AnimationController _meshController;
  bool _isLoadingLeads = true;
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
        setState(() {
          _bookingsCount = bookings.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  Future<void> _fetchLeads() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorLeads(userId);
      if (mounted && result['success'] == true) {
        final List<dynamic> leadsData = result['leads'] ?? [];
        setState(() {
          _filteredLeads = leadsData.map((json) => Lead(
            id: json['id'].toString(),
            title: json['title'] ?? 'Lead',
            date: json['date'] ?? 'TBD',
            time: json['time'] ?? 'TBD',
            location: json['location'] ?? 'TBD',
            matchScore: int.tryParse(json['matchScore']?.toString() ?? '0') ?? 0,
            budget: (json['budget'] is num) ? (json['budget'] as num).toDouble() : double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
            guests: int.tryParse(json['guests']?.toString() ?? '0') ?? 0,
            responseTime: json['responseTime'] ?? '2h',
            clientName: json['clientName'] ?? 'Client',
            clientMessage: json['clientMessage'] ?? '',
            venueName: json['venueName'] ?? '',
            venueAddress: json['venueAddress'] ?? '',
            clientImageUrl: json['clientImageUrl'] ?? 'https://via.placeholder.com/150',
            isHighValue: json['isHighValue'] ?? false,
            lastActive: json['lastActive'] ?? 'Active now',
            isAccepted: json['isAccepted'] ?? false,
          )).toList();
          _isLoadingLeads = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      if (mounted) setState(() => _isLoadingLeads = false);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorDashboardStats(userId);
      if (mounted && result['success'] == true) {
        setState(() {
          _totalLeadsCount = int.tryParse(result['stats']['totalLeads']?.toString() ?? '0') ?? 0;
          _profileViewsCount = int.tryParse(result['stats']['profileViews']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  void _loadPlan() {
    final storage = StorageService();
    setState(() {
      _planName = storage.getString('vendor_plan');
    });
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
          setState(() {
            _planName = plan;
            _isVerified = result['profile']['isVerifiedBadge'] == true;
          });
          storage.setString('vendor_plan', plan);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Search is handled locally for now but we could also search via API
    // Actually, since we only fetch a few, let's just use the current list
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = StorageService();
    final userName = storage.getString('user_name') ?? 'Vendor';
    final userImage = storage.getString('user_image');

    return Scaffold(
      backgroundColor: AppColors.primary01, // Orange behind the curve
      body: Column(
        children: [
          // ── STATIC ORANGE HEADER ──────────────────────────────
          _buildStaticHeader(isDark, userName, userImage),

          // ── BODY with rounded top ──────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // ── Relocated Search Bar ──────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildRelocatedSearchBar(isDark),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // ── Main Content Area ──────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Business Stats / Insights ──────────────────
                        if (_searchController.text.isEmpty) ...[
                          _buildSectionHeader(context, "Business Insights", isDark),
                          const SizedBox(height: 16),
                          _buildInsightsDashboard(isDark),
                          const SizedBox(height: 32),

                          // ── Quick Actions / Hub ───────────────────────
                          _buildSectionHeader(context, "Business Hub", isDark),
                          const SizedBox(height: 16),
                          _buildBusinessHub(context, isDark),
                          const SizedBox(height: 32),
                        ],

                        // ── Leads Section ─────────────────────────────
                        _buildSectionHeader(
                          context,
                          _searchController.text.isEmpty ? "Recent Leads" : "Search Results",
                          isDark,
                          showViewAll: _searchController.text.isEmpty,
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),

                  // ── Leads List ──────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _filteredLeads.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildEmptyLeadsState(isDark),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildPremiumLeadCard(context, _filteredLeads[index], isDark),
                                ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
                              },
                              childCount: _filteredLeads.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticHeader(bool isDark, String userName, String? userImage) {
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
          // Dynamic Mesh/Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: MeshPainter(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(userImage, userName),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (_isVerified) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                                ],
                                const SizedBox(width: 12),
                                _buildPlanBadge(),
                              ],
                            ),
                            Text(
                              "Photographer | $_bookingsCount bookings this month",
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: Text(
        _planName ?? "Free Plan",
        style: GoogleFonts.outfit(
          color: const Color(0xFFD97706),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
              child: const Icon(Icons.king_bed_rounded, size: 12, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () => context.push('/vendor-notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
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

  Widget _buildRelocatedSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/vendor-search'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: isDark ? Colors.white60 : Colors.black45, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Search leads, events...",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 24,
              width: 1,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Icon(Icons.tune_rounded, color: AppColors.primary01, size: 24),
          ],
        ),
      ),
    );
  }

  // ── INSIGHTS DASHBOARD ──────────────────────────
  Widget _buildInsightsDashboard(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            "Total Leads",
            "$_totalLeadsCount",
            null,
            const Color(0xFFF59E0B),
            isDark,
            "+ 12%",
            iconWidget: const Icon(PhosphorIconsFill.chartBar, color: Color(0xFFF59E0B), size: 32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            "Profile Views",
            "$_profileViewsCount",
            null,
            const Color(0xFF10B981),
            isDark,
            "+ 8%",
            iconWidget: const Icon(PhosphorIconsFill.chartLineUp, color: Color(0xFF10B981), size: 32),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInsightCard(String label, String value, String? iconPath, Color accentColor, bool isDark, String trend, {Widget? iconWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: iconWidget ?? (iconPath != null ? Image.asset(iconPath, width: 24, height: 24) : const SizedBox(width: 24, height: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trend,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
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

  // ── BUSINESS HUB ──────────────────────────────
  Widget _buildBusinessHub(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildHubTile(
            context,
            "Packages",
            'assets/icons/package-box-premium.svg',
            const Color(0xFFEEF2FF),
            () => context.push('/vendor-packages'),
            isDark,
            "Manage your services",
            iconColor: const Color(0xFF4F46E5),
          ),
          _buildHubTile(
            context,
            "Calendar",
            'assets/icons/calendar-5-premium.svg',
            Colors.white,
            () => context.push('/vendor-calendar'),
            isDark,
            "View bookings",
            iconColor: Colors.blue,
            hasBorder: true,
          ),
          _buildHubTile(
            context,
            "Portfolio",
            'assets/icons/briefcase-premium.svg',
            const Color(0xFFFFF1F2),
            () => context.push('/vendor-portfolio'),
            isDark,
            "Show your work",
            iconColor: const Color(0xFFE11D48),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildHubTile(BuildContext context, String label, String iconPath, Color bgColor, VoidCallback onTap, bool isDark, String subtitle, {Color? iconColor, bool hasBorder = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: hasBorder ? Border.all(color: const Color(0xFFE0E7FF), width: 1) : null,
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 32,
                height: 32,
                colorFilter: iconColor != null ? ColorFilter.mode(iconColor, BlendMode.srcIn) : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLeadCard(BuildContext context, Lead lead, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/lead-details/${lead.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      lead.clientImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitialsPlaceholder(lead.clientName),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (lead.isHighValue)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.clientName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildCardBadge(Icons.location_on_outlined, lead.location, isDark),
                const SizedBox(width: 12),
                _buildCardBadge(Icons.access_time_rounded, lead.responseTime, isDark),
                const Spacer(),
                _buildMatchPill(lead.matchScore.toInt()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeadsState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/megaphone-premium.svg',
            width: 80,
            height: 80,
            colorFilter: const ColorFilter.mode(AppColors.primary01, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          Text(
            "No leads yet 👋",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start by sharing your profile or adding packages.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/vendor-packages'),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: Text(
              "Create Package",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary01,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: AppColors.primary01.withOpacity(0.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMatchPill(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary01, Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$score% Match",
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCardBadge(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── HELPERS ────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, bool isDark, {bool showViewAll = false}) {
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
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
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

