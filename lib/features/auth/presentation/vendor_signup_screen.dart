import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';
import 'package:eventbridge/features/auth/presentation/widgets/social_auth_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart' as gap;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';

class VendorSignupScreen extends ConsumerStatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  ConsumerState<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends ConsumerState<VendorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  
  @override
  void initState() {
    super.initState();
    // Pre-save the VENDOR role for Google Sign-In listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).saveUserRole('VENDOR');
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final mutedColor = theme.brightness == Brightness.dark
        ? AppColors.darkNeutral06
        : AppColors.neutrals07;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        AppToast.show(
          context,
          message: state.error.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary01, // Solid Orange Background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Branding Section (Orange) ──
            _buildHero(context),

            // ── White Bottom Sheet ──
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
                          _buildAnimated(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vendor Signup',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const gap.Gap(8),
                                Text(
                                  'Grow your business',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkNeutral06,
                                  ),
                                ),
                              ],
                            ),
                            delay: 100,
                          ),
                          const gap.Gap(40),
                          _buildAnimated(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Username'),
                                const gap.Gap(10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _firstNameCtrl,
                                        hint: 'First name',
                                        icon: Icons.person_outline_rounded,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    const gap.Gap(12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _lastNameCtrl,
                                        hint: 'Last name',
                                        icon: Icons.person_outline_rounded,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            delay: 140,
                          ),
                          const gap.Gap(24),                    _buildAnimated(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          const gap.Gap(10),
                          _buildField(
                            controller: _emailCtrl,
                            hint: 'Enter your business email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? 'Enter a valid email'
                                : null,
                          ),
                        ],
                      ),
                      delay: 180,
                    ),
                    const gap.Gap(24),
                    _buildAnimated(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Input Password'),
                          const gap.Gap(10),
                          _buildField(
                            controller: _passCtrl,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'Password too short'
                                : null,
                          ),
                        ],
                      ),
                      delay: 260,
                    ),
                    const gap.Gap(16),
                    _buildAnimated(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) => setState(
                                () => _agreedToTerms = value ?? false,
                              ),
                              activeColor: AppColors.primary01,
                              side: const BorderSide(
                                color: Color(0xFF555555),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const gap.Gap(10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedColor,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppColors.primary01,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.primary01,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      delay: 320,
                    ),
                    const gap.Gap(32),
                    _buildAnimated(
                      ElevatedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                if (!_agreedToTerms) {
                                  AppToast.show(
                                    context,
                                    message: 'Please agree to the Terms of Service.',
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                if (_formKey.currentState?.validate() == true) {
                                  final fullName =
                                      '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signup(
                                        fullName,
                                        _emailCtrl.text.trim(),
                                        _passCtrl.text,
                                        role: 'vendor',
                                      );

                                  if (!context.mounted) return;
                                  if (ref
                                      .read(authControllerProvider)
                                      .hasValue) {
                                    context.go('/vendor-signup-success');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary01,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      delay: 380,
                    ),
                    const gap.Gap(24),

                    // Divider
                    _buildAnimated(
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade200)),
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
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                        ],
                      ),
                      delay: 420,
                    ),
                    const gap.Gap(24),

                    // Social Icons (Google + Apple placeholder)
                    _buildAnimated(
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authControllerProvider);
                          return SocialAuthIcons(
                            isLoading: authState.isLoading,
                            onGooglePressed: () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .continueWithGoogle(role: 'VENDOR');
                              if (!context.mounted) return;
                              if (!ref.read(authControllerProvider).hasError) {
                                final repo = ref.read(authRepositoryProvider);
                                if (repo.isOnboardingCompleted()) {
                                  context.go('/vendor-home');
                                } else {
                                  context.go('/vendor-onboarding');
                                }
                              } else {
                                AppToast.show(
                                  context,
                                  message: ref
                                      .read(authControllerProvider)
                                      .error
                                      .toString()
                                      .replaceAll('Exception: ', ''),
                                  type: ToastType.error,
                                );
                              }
                            },
                          );
                        },
                      ),
                      delay: 460,
                    ),
                    const gap.Gap(32),
                    _buildAnimated(
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already have account? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNeutral06,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Log In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary01,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      delay: 440,
                    ),
                  ],
                ),
              ),
            ),
          ),
                  ),
        ).animate().slideY(
              begin: 1.0,
              duration: 600.ms,
              curve: Curves.easeOutCirc,
            ),
      ],
    ),
  ),
);
}

  Widget _buildHero(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompactHeight = size.height < 700;

    return Container(
      height: isCompactHeight ? 180 : 240,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EventBridge',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
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
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF222222),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: AppColors.darkNeutral04),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkNeutral02 
            : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF333333) 
                : Colors.grey.shade100
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF333333) 
                : Colors.grey.shade100
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary01, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildAnimated(Widget child, {required int delay}) {
    return child
        .animate()
        .fadeIn(delay: delay.ms, duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          delay: delay.ms,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
