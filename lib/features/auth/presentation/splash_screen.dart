import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final storage = StorageService();
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        // User is logged in — redirect based on role
        final role = storage.getString('user_role');
        if (mounted) {
          if (role == 'VENDOR') {
            final onboarded = storage.getString('onboarding_completed');
            if (onboarded == 'true') {
              context.go('/vendor-home');
            } else {
              context.go('/vendor-onboarding');
            }
          } else {
            context.go('/customer-home');
          }
        }
      } else {
        if (mounted) context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary01,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EventBridge',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/Icon.svg',
                  height: 56,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(curve: Curves.easeOutBack),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
