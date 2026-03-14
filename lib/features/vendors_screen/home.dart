import 'package:flutter/material.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge_ai/features/vendors_screen/models/lead_model.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Lead> _filteredLeads = MockLeadRepository.leads;
  bool _hasNotifications = true;
  String? _planName;
  late AnimationController _meshController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPlan();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
          setState(() => _planName = plan);
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
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLeads = MockLeadRepository.leads.where((lead) {
        return lead.title.toLowerCase().contains(query) ||
            lead.location.toLowerCase().contains(query);
      }).toList();
    });
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
          // ── STATIC ORANGE HEADER (like login) ──────────────
          _buildStaticHeader(isDark, userName, userImage),

          // ── BODY with rounded top (like login bottom sheet) ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // ── STATIC SEARCH BAR (pinned, never scrolls) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: _buildGlassSearchBar(),
                  ),

                  // ── SCROLLABLE CONTENT ──
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
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
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 40),
                                      child: Text(
                                        'No matching leads found',
                                        style: GoogleFonts.roboto(color: Colors.grey),
                                      ),
                                    ),
                                  ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATIC HEADER (like login screen) ───────────────────────────────
  Widget _buildStaticHeader(bool isDark, String userName, String? userImage) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
      ),
      child: Stack(
        children: [
          // Dots/Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: GridView.count(
                crossAxisCount: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  120,
                  (i) => const Icon(Icons.circle, size: 4, color: Colors.white),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Row(
                children: [
                  _buildAvatar(userImage, userName),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          userName,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
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
      onTap: () => setState(() => _hasNotifications = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
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

  Widget _buildGlassSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFEA580C), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: 15),
              decoration: InputDecoration(
                hintText: "Search leads, events...",
                hintStyle: GoogleFonts.outfit(color: Colors.black38, fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.tune_rounded, color: Color(0xFFEA580C), size: 22),
        ],
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
            "${MockLeadRepository.leads.length}",
            Icons.leaderboard_rounded,
            const Color(0xFF10B981),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            "Profile Views",
            "1,204",
            Icons.visibility_rounded,
            const Color(0xFFF59E0B),
            isDark,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
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
          _buildHubTile(context, "Packages", Icons.inventory_2_outlined, const Color(0xFF6366F1), () => context.push('/vendor-packages'), isDark),
          _buildHubTile(context, "Calendar", Icons.calendar_today_rounded, const Color(0xFF8B5CF6), () => context.push('/vendor-calendar'), isDark),
          _buildHubTile(context, "Portfolio", Icons.photo_library_outlined, const Color(0xFFEC4899), () => context.push('/vendor-profile-settings'), isDark),
          _buildHubTile(context, "Identity", Icons.badge_outlined, const Color(0xFFF43F5E), () {}, isDark),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildHubTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
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
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(lead.clientImageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
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
                const Spacer(),
                _buildMatchPill(lead.matchScore.toInt()),
              ],
            ),
          ],
        ),
      ),
    );
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

