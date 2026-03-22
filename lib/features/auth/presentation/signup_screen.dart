import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';
import 'package:eventbridge/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/foundation.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isVendor = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutrals08,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),
                const Gap(8),
                Text(
                  'Join EventBridge AI to start matching',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.neutrals07),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const Gap(32),

                // Role Selection
                Text(
                  'I am a...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutrals08,
                  ),
                ),
                const Gap(12),
                Row(
                  children: [
                    _buildRoleCard(
                      'Customer',
                      Icons.person_rounded,
                      !_isVendor,
                    ),
                    const Gap(16),
                    _buildRoleCard('Vendor', Icons.store_rounded, _isVendor),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const Gap(32),

                _buildTextField(
                  label: 'Full Name',
                  hint: 'enter your name',
                  controller: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                if (_isVendor) ...[
                  const Gap(20),
                  _buildTextField(
                    label: 'Business Name',
                    hint: 'enter your business name',
                    controller: _businessCtrl,
                    icon: Icons.business_center_rounded,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Business name is required'
                        : null,
                  ),
                ],
                const Gap(20),
                _buildTextField(
                  label: 'Email Address',
                  hint: 'enter your email',
                  controller: _emailCtrl,
                  icon: Icons.alternate_email_rounded,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const Gap(20),
                _buildTextField(
                  label: 'Password',
                  hint: 'create a password',
                  controller: _passCtrl,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (value) => value == null || value.length < 6
                      ? 'Password too short'
                      : null,
                ),

                const Gap(40),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final repo = ref.read(authRepositoryProvider);
                        await repo.signup(
                          _nameCtrl.text.trim(),
                          _emailCtrl.text.trim(),
                          _passCtrl.text,
                          role: _isVendor ? 'VENDOR' : 'CUSTOMER',
                        );
                        if (!context.mounted) return;
                        if (_isVendor) {
                          context.go('/vendor-onboarding');
                        } else {
                          context.go('/customer-home');
                        }
                      } catch (e) {
                         // show toast
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),

                const Gap(32),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.neutrals05,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const Gap(24),

                Consumer(
                  builder: (context, ref, child) {
                    if (kIsWeb) {
                      return Column(
                        children: [
                          _buildEntranceAnimation(
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: buildGoogleSignInButton(),
                            ),
                            delayMs: 700,
                          ),
                          const Gap(8),
                          const Text(
                            'Use the button above to continue with Google',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }

                    final authState = ref.watch(authControllerProvider);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: authState.isLoading ? () {} : () async {
                          await ref.read(authControllerProvider.notifier).continueWithGoogle(role: _isVendor ? 'VENDOR' : 'CUSTOMER');
                          if (!context.mounted) return;
                          
                          if (ref.read(authControllerProvider).hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ref.read(authControllerProvider).error.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            if (_isVendor) {
                               final repo = ref.read(authRepositoryProvider);
                               if (repo.isOnboardingCompleted()) {
                                 context.go('/vendor-home');
                               } else {
                                 context.go('/vendor-onboarding');
                               }
                            } else {
                               context.go('/customer-home');
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: AppColors.neutrals03),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/google.png', height: 24),
                            const Gap(12),
                            Text(
                              authState.isLoading ? 'Connecting...' : 'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutrals08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ).animate().scale(delay: 700.ms, curve: Curves.elasticOut),

                const Gap(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: AppColors.neutrals07),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary01,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _isVendor = title == 'Vendor');
          ref.read(authControllerProvider.notifier).saveUserRole(_isVendor ? 'VENDOR' : 'CUSTOMER');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary01.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary01 : AppColors.neutrals02,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary01 : AppColors.neutrals04,
                size: 32,
              ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary01
                      : AppColors.neutrals07,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.neutrals08,
          ),
        ),
        const Gap(8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.neutrals05),
            prefixIcon: Icon(icon, color: AppColors.neutrals04),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutrals02),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutrals02),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary01, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntranceAnimation(Widget child, {required int delayMs}) {
    return child.animate().fadeIn(delay: delayMs.ms).slideY(
          begin: 0.1,
          end: 0,
          delay: delayMs.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
