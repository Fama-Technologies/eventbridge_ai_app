import 'package:flutter/material.dart';
import 'package:gap/gap.dart' as gap;
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/features/auth/presentation/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _stayLoggedIn = false;
  bool _isPasswordVisible = false;

  Widget _buildEntranceAnimation(
    Widget child, {
    required int delayMs,
    double beginOffsetY = 0.08,
  }) {
    return child
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 450.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: beginOffsetY,
          end: 0,
          delay: delayMs.ms,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompactHeight = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.primary01, // Solid Orange Background
      body: SafeArea(
        bottom: false, // Let the white card go to the bottom
        child: Column(
          children: [
            // ── Top Branding Section (Orange) ──
            Container(
              height: isCompactHeight ? 180 : 240,
              width: double.infinity,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EventBridge',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontSize: 36,
                    ),
                  ),
                  const gap.Gap(8),
                  SvgPicture.asset(
                    'assets/icons/Icon.svg',
                    height: 48,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            ),

            // ── Animated White Bottom Sheet ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEntranceAnimation(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const gap.Gap(8),
                                Text(
                                  'Log in to continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkNeutral06,
                                  ),
                                ),
                              ],
                            ),
                            delayMs: 100,
                          ),
                          const gap.Gap(40),

                          // Inputs
                          _buildEntranceAnimation(
                            _buildGlovoTextField(
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v == null || !v.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            delayMs: 200,
                          ),
                          const gap.Gap(16),

                          _buildEntranceAnimation(
                            _buildGlovoTextField(
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (v) =>
                                  v == null || v.length < 6
                                      ? 'Password too short'
                                      : null,
                            ),
                            delayMs: 280,
                          ),
                          const gap.Gap(32),

                          // Login Button
                          _buildEntranceAnimation(
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.go('/login-success');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary01,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            delayMs: 360,
                          ),
                          const gap.Gap(24),

                          // Sign up redirect
                          _buildEntranceAnimation(
                            Center(
                              child: GestureDetector(
                                onTap: () => _showRoleSelectionSheet(context),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(
                                      color: AppColors.darkNeutral06,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Sign up here",
                                        style: TextStyle(
                                          color: AppColors.primary01,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            delayMs: 440,
                          ),
                          const gap.Gap(24),

                          // Divider
                          _buildEntranceAnimation(
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: AppColors.darkNeutral06,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            delayMs: 520,
                          ),
                          const gap.Gap(24),

                          // Social Button
                          _buildEntranceAnimation(
                            Consumer(
                              builder: (context, ref, child) {
                                final authState = ref.watch(authControllerProvider);
                                
                                return _buildSocialButton(
                                  authState.isLoading ? 'Connecting...' : 'Continue with Google',
                                  'assets/icons/google.png',
                                  authState.isLoading ? () {} : () async {
                                    await ref.read(authControllerProvider.notifier).continueWithGoogle(role: 'CUSTOMER');
                                    if (!context.mounted) return;
                                    if (!ref.read(authControllerProvider).hasError) {
                                      context.go('/login-success');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ref.read(authControllerProvider).error.toString().replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }
                            ),
                            delayMs: 600,
                          ),
                          const gap.Gap(32),

                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutCirc),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? AppColors.darkNeutral02 : Colors.white;
        final handleColor = isDark ? AppColors.darkNeutral03 : Colors.grey.shade300;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const gap.Gap(24),
            Text(
              'Join EventBridge',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const gap.Gap(8),
            const Text(
              'Select how you want to join our community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.darkNeutral06,
                fontWeight: FontWeight.w500,
              ),
            ),
            const gap.Gap(32),
            _buildRoleTile(
              context,
              title: 'I am a Customer',
              subtitle: 'Find and book the best vendors',
              icon: Icons.person_outline_rounded,
              onTap: () {
                Navigator.pop(context);
                context.push('/create-account');
              },
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
            const gap.Gap(16),
            _buildRoleTile(
              context,
              title: 'I am a Vendor',
              subtitle: 'Grow your business with us',
              icon: Icons.storefront_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/vendor-signup');
              },
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          ],
        ),
      );
    },
    );
  }

  Widget _buildRoleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkNeutral03.withValues(alpha: 0.4) : Colors.grey.shade50.withValues(alpha: 0.5);
    final borderColor = isDark ? AppColors.darkNeutral03 : Colors.grey.shade100;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(20),
          color: cardBg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary01, size: 28),
            ),
            const gap.Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const gap.Gap(4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, 
                 size: 16, 
                 color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.shadesWhite,
      ),
    );
  }

  Widget _buildGlovoTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.darkNeutral01;

    return TextFormField(
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.darkNeutral04, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: AppColors.darkNeutral04),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.darkNeutral04,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkNeutral02 
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF333333) 
                : Colors.grey.shade200
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF333333) 
                : Colors.grey.shade200
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary01, width: 2),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, String iconPath, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: isDark ? const Color(0xFF333333) : AppColors.neutrals03,
          ),
          backgroundColor: isDark
              ? const Color(0xFF222222)
              : AppColors.backgroundLight,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath.endsWith('.svg'))
              SvgPicture.asset(iconPath, height: 24)
            else
              Image.asset(iconPath, height: 24),
            const gap.Gap(12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkNeutral01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

