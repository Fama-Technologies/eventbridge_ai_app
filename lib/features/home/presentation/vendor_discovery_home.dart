import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';

class VendorDiscoveryHome extends ConsumerStatefulWidget {
  const VendorDiscoveryHome({super.key});

  @override
  ConsumerState<VendorDiscoveryHome> createState() =>
      _VendorDiscoveryHomeState();
}

class _VendorDiscoveryHomeState extends ConsumerState<VendorDiscoveryHome> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Sarah';
    final lastName = user?.displayName?.split(' ').last ?? 'James';
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Dark header section
          _buildDarkHeader(greeting, '$firstName $lastName'),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildQuickSearchSection(),
                  const SizedBox(height: 28),
                  _buildRecentMatchesSection(),
                  const SizedBox(height: 28),
                  _buildAIRecommendationsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildDarkHeader(String greeting, String fullName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row with avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Avatar
                  GestureDetector(
                    onTap: () => context.go('/customer-profile'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary01,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Plan your event card
              _buildPlanEventCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanEventCard() {
    return GestureDetector(
      onTap: () => context.go('/match-intake'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary01,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Your Next',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Event',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let AI find the perfect vendors',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchSection() {
    final categories = [
      ('Wedding', Icons.favorite, const Color(0xFFFF6B6B)),
      ('Birthday', Icons.cake, AppColors.primary01),
      ('Corporate', Icons.business_center, AppColors.primary01),
      ('Party', Icons.celebration, AppColors.primary01),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Search by Category',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to category search
                    context.go('/match-intake');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.$2, size: 20, color: cat.$3),
                        const SizedBox(width: 8),
                        Text(
                          cat.$1,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent vendor matches',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/matches'),
                child: Text(
                  'View all',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary01,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildVendorCard(
                initial: 'G',
                name: 'Golden Hour Stu...',
                category: 'Photography',
                rating: 4.9,
                color: Colors.grey[300]!,
              ),
              const SizedBox(width: 16),
              _buildVendorCard(
                initial: 'E',
                name: 'Elite Catering',
                category: 'Catering',
                rating: 4.7,
                color: Colors.grey[300]!,
              ),
              const SizedBox(width: 16),
              _buildVendorCard(
                initial: 'A',
                name: 'Amanda Events',
                category: 'Event Planner',
                rating: 4.8,
                color: Colors.blue[100]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard({
    required String initial,
    required String name,
    required String category,
    required double rating,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => context.go('/vendor-public/demo-vendor-id'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with initial
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Name
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Category
            Text(
              category,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            // Rating
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'AI Recommendations',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => context.go('/match-intake'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary01,
                    AppColors.primary01.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get AI-Powered Matches',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your budget, location & preferences',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.search_rounded, Icons.search_rounded, 'Search'),
      (Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Bookings'),
      (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Messages'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedNavIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNavIndex = index);
                  switch (index) {
                    case 0:
                      // Already on home
                      break;
                    case 1:
                      context.go('/match-intake');
                      break;
                    case 2:
                      context.go('/matches');
                      break;
                    case 3:
                      context.go('/customer-chats');
                      break;
                    case 4:
                      context.go('/customer-profile');
                      break;
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.$1 : item.$2,
                      color: isSelected
                          ? AppColors.primary01
                          : Colors.grey[400],
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary01
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
