import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart' as gap;
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eventbridge_ai/features/auth/presentation/auth_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  bool _stayLoggedIn = false;

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
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkNeutral06 : AppColors.neutrals07;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const gap.Gap(8),
                                Text(
                                  'Join the community',
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

                          // Full Name
                          _buildAnimated(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Full Name'),
                                const gap.Gap(10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _firstNameCtrl,
                                        hint: 'First name',
                                        icon: Icons.person_outline_rounded,
                                        validator: (v) => v == null || v.trim().isEmpty
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
                                        validator: (v) => v == null || v.trim().isEmpty
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
                          const gap.Gap(24),
                    // Email
                    _buildAnimated(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          const gap.Gap(10),
                          _buildField(
                            controller: _emailCtrl,
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Enter a valid email'
                                : null,
                          ),
                        ],
                      ),
                      delay: 180,
                    ),
                    const gap.Gap(24),

                    // Password
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
                            validator: (v) => v == null || v.length < 6
                                ? 'Password too short'
                                : null,
                          ),
                        ],
                      ),
                      delay: 260,
                    ),
                    const gap.Gap(16),

                    // Stay Logged In
                    _buildAnimated(
                      Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _stayLoggedIn,
                              onChanged: (v) =>
                                  setState(() => _stayLoggedIn = v ?? false),
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
                          Text(
                            'Stay Logged In',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      delay: 320,
                    ),
                    const gap.Gap(32),

                    // Sign Up Button
                    _buildAnimated(
                      ElevatedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() == true) {
                                  final fullName =
                                      '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signup(
                                        fullName,
                                        _emailCtrl.text.trim(),
                                        _passCtrl.text,
                                      );
                                  if (!context.mounted) return;
                                  if (ref
                                      .read(authControllerProvider)
                                      .hasValue) {
                                    context.go('/signup-success');
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

                    // Social Button
                    _buildAnimated(
                      _buildSocialButton(
                        'Continue with Google',
                        'assets/icons/google.png',
                        () {},
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

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );

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
        color: isDark ? AppColors.darkNeutral01 : const Color(0xFF222222),
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
                  color: Colors.black54,
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
