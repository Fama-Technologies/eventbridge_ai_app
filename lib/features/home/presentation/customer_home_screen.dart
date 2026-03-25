import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/shared/widgets/customer_bottom_navbar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:eventbridge/features/auth/presentation/auth_provider.dart';
import 'package:eventbridge/core/services/suggestion_service.dart';
import 'package:eventbridge/core/services/notification_service.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;
  Future<List<dynamic>>? _recommendedVendorsFuture;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedVendors();
  }

  void _fetchRecommendedVendors() {
    setState(() {
      _recommendedVendorsFuture = ApiService.instance.getCustomerRecommendedVendors()
          .then((res) => res['success'] == true ? res['vendors'] as List<dynamic> : [])
          .catchError((_) => <dynamic>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Friend';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Very light grey/white background
      appBar: _buildAppBar(firstName),
      body: Stack(
        children: [
          _buildBackgroundAura(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildSectionHeader('Recommended for you', null, '', () {}),
              const SizedBox(height: 16),
              _buildRecommendedList(),
              const SizedBox(height: 32),
              _buildSectionHeader('AI Features & Pro Vendors', null, '', () {}),
              const SizedBox(height: 16),
              _buildAIFeaturesList(),
              const SizedBox(height: 32),
              _buildInfoBox(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavbar(currentRoute: '/customer-home'),
    );
  }

  AppBar _buildAppBar(String name) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 90,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          Text(
            '$name',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final user = ref.read(authStateChangesProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Friend';
    
    String greeting;
    if (hour < 12) greeting = 'Good morning,';
    else if (hour < 17) greeting = 'Good afternoon,';
    else greeting = 'Good evening,';
    
    return '$greeting $firstName';
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4F0), // Soft cream/peach
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan your next\nevent faster',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 180,
                  child: Text(
                    'AI helps you find the\nbest vendors instantly',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/match-intake'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary01,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary01.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Find Vendors',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Illustration Placeholder
          Positioned(
            right: 0,
            bottom: 0,
            top: 20,
            child: Container(
              width: 190,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=400&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                  alignment: Alignment(-0.2, 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCard('Find\nVendors', Icons.search_rounded, const Color(0xFFFEF2EC), AppColors.primary01, () => context.push('/match-intake')),
        _buildActionCard('Past\nMatches', Icons.access_time_rounded, const Color(0xFFF8F9FA), Colors.black45, () => context.push('/matches')),
        _buildActionCard('Saved\nVendors', Icons.favorite_border_rounded, const Color(0xFFF8F9FA), Colors.black45, () {}),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 3,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const Icon(Icons.more_horiz_rounded, color: Colors.black26),
      ],
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 240,
      child: FutureBuilder<List<dynamic>>(
        future: _recommendedVendorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary01));
          }
          final vendors = snapshot.data ?? [];
          if (vendors.isEmpty) {
            return Center(
              child: Text(
                'No recommendations found yet.',
                style: GoogleFonts.outfit(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final v = vendors[index];
              final String id = v['id']?.toString() ?? '';
              final String name = v['name'] ?? 'Vendor';
              final List services = v['services'] is List ? v['services'] as List : [];
              final String category = services.isNotEmpty ? services.first.toString().toUpperCase() : 'VENDOR';
              final String rating = v['rating']?.toString() ?? 'New';
              
              String imageUrl = 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=400&auto=format&fit=crop';
              if (v['avatar'] != null && v['avatar'].toString().isNotEmpty) {
                 imageUrl = v['avatar'];
              } else if (v['portfolio'] != null && v['portfolio'] is List && (v['portfolio'] as List).isNotEmpty) {
                 imageUrl = (v['portfolio'] as List).first.toString();
              }

              return _buildVendorCard(id, category, name, rating, imageUrl);
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(String id, String category, String name, String rating, String imageUrl) {
    return GestureDetector(
      onTap: () => context.push('/vendor-public/$id'),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary01, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Top Match',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary01,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, color: Colors.black45, size: 18),
                  ),
                )
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        children: List.generate(4, (i) => const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14)),
                      ),
                      const Spacer(),
                      Text(
                        '5 mi away',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAIFeaturesList() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          // Purple AI Card
          GestureDetector(
            onTap: () => context.push('/match-intake'),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC0B1FF), Color(0xFF9E8BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0B1FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    'AI Smart\nMatching',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let AI find the best vendors\nfor your unique events',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Dark Blue Card
          Container(
            width: 280,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D3E6E), Color(0xFF1B2647)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2647).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_outline_rounded, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Text(
                  'Great\nServices',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse our top-rated\npro vendors instantly',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.lightbulb_rounded, color: AppColors.primary01, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why automated matching?',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary01,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save up to 15 hours of manual searching.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _buildBackgroundAura() {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary01.withValues(alpha: 0.1),
                  AppColors.primary01.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -150,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary01.withValues(alpha: 0.08),
                  AppColors.primary01.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
