import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge_ai/core/theme/app_theme.dart';
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
    // use GoRouter to change route so that the navigator stack is cleared
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
                title: 'Grow Your Business',
                description:
                    'Join an elite network and get matched with high-value event leads automatically.',
                imageType: _ImageType.fullImageCover,
                imageUrl: 'assets/images/image111.png',
              ),
              _OnboardingPage(
                title: 'AI-Powered Matching',
                description:
                    'Stop hunting for leads. Our AI analyzes your expertise and budget to find the perfect clients for you.',
                imageType: _ImageType.roundedCard,
                imageUrl: 'assets/images/image22.png',
              ),
              _OnboardingPage(
                title: 'Secure & Fast Payments',
                description:
                    'Get paid securely through our integrated payment system as soon as your match is confirmed.',
                imageType: _ImageType.circularIcon,
                iconData: PhosphorIconsRegular.money,
              ),
            ],
          ),

          // ── Bottom Controls ──
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.primary01,
                    dotColor: isDark
                        ? AppColors.darkNeutral04
                        : AppColors.neutral03,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                  ),
                ),
                const SizedBox(height: 32),

                // Next / Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNextTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary01,
                      foregroundColor: AppColors.shadesWhite,
                      shape: RoundedRectangleBorder(
                        // padding: const EdgeInsets.symmetric(horizontal: 24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip Button
                if (!isLastPage)
                  TextButton(
                    onPressed: _onSkipTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.neutral06,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    height: 48,
                  ), // Padding equivalent to Skip button height
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ImageType { fullImageCover, roundedCard, circularIcon }

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final _ImageType imageType;
  final String? imageUrl;
  final IconData? iconData;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imageType,
    this.imageUrl,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.foregroundDark
        : const Color(0xFF0F172A); // Extra dark navy for title
    final descColor = isDark
        ? AppColors.darkNeutral06
        : const Color(0xFF64748B); // Slate grey

    return Column(
      children: [
        // ── Top Graphic (Dynamic based on type) ──
        Expanded(flex: 55, child: _buildGraphicBox(context, isDark)),

        // ── Text Content ──
        Expanded(
          flex: 45,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              bottom: 180.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: descColor,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphicBox(BuildContext context, bool isDark) {
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    if (imageType == _ImageType.fullImageCover) {
      // Screen 1: Image covering top half with gradient fade to background
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // Gradient fade to blend into the background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgColor.withValues(alpha: 0),
                    bgColor.withValues(alpha: 0.1),
                    bgColor.withValues(alpha: 0.8),
                    bgColor,
                  ],
                  stops: const [0.5, 0.7, 0.9, 1.0],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (imageType == _ImageType.roundedCard) {
      // Screen 2: Floating rounded card with image inside
      return Center(
        child: Container(
          width: 280,
          height: 280,
          margin: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2420) : const Color(0xFFFBF4EB),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl!, fit: BoxFit.cover),
          ),
        ),
      );
    } else {
      // Screen 3: Circular placeholder icon on a peach background
      return Center(
        child: Container(
          width: 200,
          height: 200,
          margin: const EdgeInsets.only(top: 40),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3ED), // Very light peach
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              iconData ?? PhosphorIconsRegular.money,
              size: 80,
              color: AppColors.primary01,
            ),
          ),
        ),
      );
    }
  }
}
