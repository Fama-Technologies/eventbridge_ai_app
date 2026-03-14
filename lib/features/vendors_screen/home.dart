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

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Lead> _filteredLeads = MockLeadRepository.leads;
  bool _hasNotifications = true; // Demonstration purpose
  String? _planName;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPlan();
  }

  void _loadPlan() {
    final storage = StorageService();
    setState(() {
      _planName = storage.getString('vendor_plan');
    });
    // Optional: fetch if missing
    if (_planName == null) {
      _fetchPlan();
    }
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = StorageService();
    final userName = storage.getString('user_name') ?? 'Vendor';
    final userImage = storage.getString('user_image');

    // Neutral header colors based on theme tokens
    final headerBg = isDark ? AppColors.backgroundDark : AppColors.neutrals01;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF7F7F8);
    final cardBg = isDark ? AppColors.darkNeutral02 : Colors.white;
    final textPrimary = isDark ? AppColors.foregroundDark : const Color(0xFF1A1A24);
    final textSecondary = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);
    final borderColor = isDark ? AppColors.darkNeutral03 : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Static Header ──────────────────────────────
            _buildHeader(context, isDark, userName, userImage, textPrimary, headerBg),

            // ── Scrolling Content ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24), // Spacing after search bar

                    // ── Analytics ──────────────────────────────────
                    if (_searchController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildAnalyticsCards(isDark, cardBg, textPrimary, borderColor),
                      ),

                    if (_searchController.text.isEmpty) const SizedBox(height: 28),

                    // ── Business Hub ───────────────────────────────
                    if (_searchController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildBusinessHub(context, isDark, cardBg, textPrimary, borderColor),
                      ),

                    if (_searchController.text.isEmpty) const SizedBox(height: 24),

                    // ── Upgrade Banner ─────────────────────────────
                    if (_searchController.text.isEmpty && _planName?.toLowerCase() != 'business_pro')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildUpgradeBanner(context, isDark),
                      ),

                    if (_searchController.text.isEmpty) const SizedBox(height: 28),

                    // ── Recent Leads ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecentLeadsHeader(context, textPrimary, _searchController.text.isNotEmpty),
                    ),
                    const SizedBox(height: 14),
                    
                    if (_filteredLeads.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No matching leads found'),
                        ),
                      )
                    else
                      ..._filteredLeads.map(
                        (lead) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: _buildLeadCard(context, lead: lead, isDark: isDark, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, borderColor: borderColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String userName, String? userImage, Color textPrimary, Color headerBg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: headerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with fallback to mock/initials
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Pro Plan Crown
                  if (_planName?.toLowerCase() == 'business_pro')
                    Positioned(
                      top: -12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Icon(
                          Icons.king_bed_rounded,
                          color: const Color(0xFFFFD700),
                          size: 18,
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                         .shimmer(delay: 2.seconds),
                      ),
                    ),
                  
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkNeutral02 : AppColors.neutrals02,
                      border: Border.all(
                        color: _planName?.toLowerCase() == 'business_pro' 
                            ? const Color(0xFFFFD700) 
                            : AppColors.neutrals02, 
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: (userImage != null && userImage.isNotEmpty)
                          ? Image.network(
                              userImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildInitialsPlaceholder(userName);
                              },
                            )
                          : _buildInitialsPlaceholder(userName),
                    ),
                  ),

                  // Free Plan White Bubble Badge (Exterior Tab Look)
                  if (_planName != null && _planName?.toLowerCase() != 'business_pro')
                    Positioned(
                      left: 58, // Almost tangent to the 64px avatar edge
                      top: 28,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEA580C), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'FREE',
                          style: GoogleFonts.roboto(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEA580C),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 44), // Increased to give room for exterior badge

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF999999) : AppColors.neutrals07,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => _hasNotifications = false);
                  // Fixed: context.push('/vendor-settings') might be better if we want to go to notifications
                  // but for now keeping as is or changing to settings
                  context.push('/vendor-settings');
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primary01,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                )
                .animate(target: _hasNotifications ? 1 : 0, onPlay: (controller) => controller.repeat())
                .shake(duration: 1.seconds, hz: 4)
                .custom(
                    duration: 1.5.seconds,
                    builder: (context, value, child) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary01.withOpacity(0.5 * (1 - value)),
                            blurRadius: 15 * value,
                            spreadRadius: 8 * value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pill-shaped Search bar (Exact match to screenshot)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black, fontSize: 16), // Reduced font
              decoration: InputDecoration(
                hintText: 'Search Workouts...',
                hintStyle: const TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w400, fontSize: 16),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(Icons.search_rounded, color: Color(0xFF999999), size: 24), // Reduced Icon
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48), 
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.tune_rounded, color: Colors.black, size: 24), // Reduced Icon
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14), // Reduced height
              ),
            ),
          ),
          const SizedBox(height: 12), // Extra padding at the bottom of the header
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ANALYTICS CARDS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsCards(bool isDark, Color cardBg, Color textPrimary, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A14) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary01.withValues(alpha: isDark ? 0.2 : 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary01,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary01,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'New Leads',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '12',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkNeutral03 : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    color: isDark ? AppColors.darkNeutral06 : const Color(0xFF4B5563),
                    size: 18,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Profile Views',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '1.2k',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUSINESS HUB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBusinessHub(BuildContext context, bool isDark, Color cardBg, Color textPrimary, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Business Hub',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.darkNeutral06 : const Color(0xFF9CA3AF)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildHubCard(context, isDark: isDark, cardBg: cardBg, textPrimary: textPrimary, borderColor: borderColor,
              icon: Icons.local_offer_rounded,
              label: 'Packages',
              bgColor: isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF0F9FF),
              iconColor: const Color(0xFF0EA5E9),
              onTap: () => context.push('/vendor-packages'),
            ),
            const SizedBox(width: 12),
            _buildHubCard(context, isDark: isDark, cardBg: cardBg, textPrimary: textPrimary, borderColor: borderColor,
              icon: Icons.calendar_month_rounded,
              label: 'Calendar',
              bgColor: isDark ? const Color(0xFF0F2A1A) : const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF22C55E),
              onTap: () => context.push('/vendor-calendar'),
            ),
            const SizedBox(width: 12),
            _buildHubCard(context, isDark: isDark, cardBg: cardBg, textPrimary: textPrimary, borderColor: borderColor,
              icon: Icons.image_rounded,
              label: 'Portfolio',
              bgColor: isDark ? const Color(0xFF2A1414) : const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              onTap: () => context.push('/vendor-profile-settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHubCard(BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color borderColor,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPGRADE BANNER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildUpgradeBanner(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/subscription'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A24), const Color(0xFF252536)]
                : [const Color(0xFF1A1A24), const Color(0xFF2D2D3A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: AppColors.primary01, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Upgrade to Pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Boost your visibility with '),
                  TextSpan(
                    text: 'Top AI Ranking',
                    style: TextStyle(color: AppColors.primary01, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' and unlock advanced matching algorithms.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563), // Darker gray for better contrast
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  RECENT LEADS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRecentLeadsHeader(BuildContext context, Color textPrimary, bool isSearching) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSearching ? 'Search Results' : 'Recent Leads',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        if (!isSearching)
          TextButton(
            onPressed: () {},
            child: Row(
              children: [
                const Text(
                  'View all',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary01),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.primary01),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLeadCard(BuildContext context, {
    required Lead lead,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(lead.date, style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(lead.location, style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MATCH',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textSecondary, letterSpacing: 0.5),
                  ),
                  Text(
                    '${lead.matchScore}%',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary01),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => context.push('/lead-details/${lead.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkNeutral03 : const Color(0xFFFFF1F0),
                    foregroundColor: textPrimary,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                  label: const Text('Accept'),
                  onPressed: () => context.push('/vendor-chat/${lead.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    AppToast.show(context, message: 'Lead declined and customer notified.', type: ToastType.info);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkNeutral03 : const Color(0xFFF3F4F6),
                    foregroundColor: isDark ? AppColors.foregroundDark : const Color(0xFF1F2937),
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
