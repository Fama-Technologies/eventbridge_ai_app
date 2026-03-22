import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SignupSuccessScreen extends StatefulWidget {
  const SignupSuccessScreen({
    super.key,
    required this.title,
    required this.message,
    required this.nextRoute,
  });

  final String title;
  final String message;
  final String nextRoute;

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go(widget.nextRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.titleLarge?.color ?? Colors.white;
    final textMuted = isDark ? AppColors.darkNeutral06 : AppColors.neutrals07;
    final surfaceColor = isDark ? AppColors.darkNeutral02 : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Icon(Icons.close_rounded, color: textPrimary),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.26 : 0.08,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6A2A),
                                    AppColors.primary01,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary01.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            )
                            .animate()
                            .scale(duration: 420.ms, curve: Curves.easeOutBack)
                            .fadeIn(duration: 280.ms),
                        const SizedBox(height: 28),
                        Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                                letterSpacing: -0.8,
                                color: textPrimary,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 320.ms)
                            .slideY(
                               begin: 0.12,
                               end: 0,
                               delay: 120.ms,
                               duration: 320.ms,
                            ),
                        const SizedBox(height: 14),
                        Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.55,
                                color: textMuted,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 320.ms)
                            .slideY(
                               begin: 0.12,
                               end: 0,
                               delay: 200.ms,
                               duration: 320.ms,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
