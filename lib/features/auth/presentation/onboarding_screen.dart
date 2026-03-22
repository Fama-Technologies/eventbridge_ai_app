import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge/core/theme/app_theme.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!isLastPage && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else if (isLastPage && _pageController.hasClients) {
        // Optional: loop back to the first page if you want continuous auto-scroll
        // _pageController.animateToPage(
        //   0,
        //   duration: const Duration(milliseconds: 600),
        //   curve: Curves.easeInOut,
        // );
        _timer?.cancel(); // Stop scrolling when reaching the end
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onBackTap() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onNextTap() {
    if (isLastPage) {
      _navigateToLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkipTap() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Scrollable Pages ──
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                isLastPage = index == 2;
              });
            },
            children: const [
              _OnboardingPage(

                title: 'Seamless Event Planning',
                // ----- so we going  to use the images  in the /assets/onboarding/
                description:
                    'Connect with elite vendors and plan your dream event with AI-powered precision and effortless coordination.',
                imageUrl: 'assets/onboarding/onboarding1.',
              ),
              _OnboardingPage(
                title: 'AI-Powered Matching',
                description:
                    'Our advanced algorithms pair you with perfectly suited vendors for your specific needs, budget, and aesthetic.',
                imageUrl: 'https://images.unsplash.com/photo-1551818255-e6e10975bc17?auto=format&fit=crop&q=80&w=800',
              ),
              _OnboardingPage(
                title: 'Track Every Detail',
                description:
                    'Monitor your event progress in real-time, manage bookings, and stay ahead of every deadline with one intelligent platform.',
                imageUrl: 'https://images.unsplash.com/photo-1475721027187-402473394b8e?auto=format&fit=crop&q=80&w=800',
              ),
            ],
          ),

          // ── Bottom Controls ──
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                _CircularNavigationButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _onBackTap,
                  enabled: _pageController.hasClients && _pageController.page != 0,
                ),

                // Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.shadesWhite,
                    dotColor: AppColors.darkNeutral04.withValues(alpha: 0.5),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 8,
                  ),
                ),

                // Next Button
                _CircularNavigationButton(
                  icon: isLastPage ? Icons.check_rounded : Icons.chevron_right_rounded,
                  onTap: _onNextTap,
                  isPrimary: true,
                ),
              ],
            ),
          ),
          
          // Skip Button top right
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: _onSkipTap,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.darkNeutral06,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isPrimary;

  const _CircularNavigationButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled && !isPrimary) return const SizedBox(width: 56, height: 56);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary01 : AppColors.darkNeutral02.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.shadesWhite,
          size: 28,
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  Widget _buildPlaceholderImage(String imageUrl) {
    IconData icon;
    Color color;
    if (imageUrl.contains('photo-1540575861501')) {
      icon = Icons.event_available_rounded;
      color = AppColors.primary01;
    } else if (imageUrl.contains('photo-1551818255')) {
      icon = Icons.psychology_rounded;
      color = const Color(0xFF6366F1);
    } else {
      icon = Icons.track_changes_rounded;
      color = const Color(0xFF10B981);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/Icon.svg',
              height: 120,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 20),
            Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // ── Top Curved Graphic Placeholder ──
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFD9D9D9) : const Color(0xFFE5E5E5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.elliptical(500, 250),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.elliptical(500, 250),
                  ),
                  child: _buildPlaceholderImage(imageUrl),
                ),
              ),
              // Optional: Add a subtle overlay for the curve effect if needed
            ],
          ),
        ),

        // ── Text Content ──
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.shadesWhite,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkNeutral06,
                    height: 1.4,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
