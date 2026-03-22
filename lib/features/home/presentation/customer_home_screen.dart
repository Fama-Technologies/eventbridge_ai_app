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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // Bottom padding for floating nav
            children: [
              _buildHeroCard(),
              const SizedBox(height: 32),
              _buildSectionHeader('Recommended for You', 'AI RANKED', 'View History', () => context.push('/matches')),
              const SizedBox(height: 16),
              _buildRecommendedList(),
              const SizedBox(height: 32),
              _buildSectionHeader('AI Features & Pro Vendors', null, 'See All', () => context.push('/matches')),
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
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Evening,',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary01.withValues(alpha: 0.6),
            ),
          ),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary01,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {}, // Future toggle theme or notifications
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: AppColors.primary01, size: 24),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.primary01, // Using theme primary for the badge
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary01.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5))
                     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary01, // Orange
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary01.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY EVENT PLANNER',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active Projects',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/match-intake'),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primary01, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Find\nVendors',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary01,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/matches'),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'View Past\nMatches',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary01,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary01, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary01,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary01,
            ),
          ),
        ),
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
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary01, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'TOP MATCH',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary01,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary01,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary01,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4338CA), // Deep Indigo/Purple
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEW FEATURE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'AI Smart Matching',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instantly find vendors that match your unique style and budget constraints.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Try Now',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Dark Pro Card (Show a generic pro vendor tip or just hide if no data)
          FutureBuilder<List<dynamic>>(
            future: _recommendedVendorsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.length > 1) {
                final v = snapshot.data![1];
                return GestureDetector(
                  onTap: () => context.push('/vendor-public/${v['id']}'),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary01,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PRO HIGHLY RATED',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          v['name'] ?? 'Elite Vendor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          v['business_overview'] ?? 'Premium quality services.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'View Profile',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
