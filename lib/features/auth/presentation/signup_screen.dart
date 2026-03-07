import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isVendor = false;

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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.neutrals07,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const Gap(32),

                // Role Selection
                Text('I am a...', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.neutrals08)),
                const Gap(12),
                Row(
                  children: [
                    _buildRoleCard('Customer', PhosphorIcons.user(), !_isVendor),
                    const Gap(16),
                    _buildRoleCard('Vendor', PhosphorIcons.storefront(), _isVendor),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const Gap(32),

                _buildTextField(
                  label: 'Full Name',
                  hint: 'enter your name',
                  icon: PhosphorIcons.user(),
                  validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                ),
                if (_isVendor) ...[
                  const Gap(20),
                  _buildTextField(
                    label: 'Business Name',
                    hint: 'enter your business name',
                    icon: PhosphorIcons.briefcase(),
                    validator: (value) => value == null || value.isEmpty ? 'Business name is required' : null,
                  ),
                ],
                const Gap(20),
                _buildTextField(
                  label: 'Email Address',
                  hint: 'enter your email',
                  icon: PhosphorIcons.at(),
                  validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                ),
                const Gap(20),
                _buildTextField(
                  label: 'Password',
                  hint: 'create a password',
                  icon: PhosphorIcons.lock(),
                  isPassword: true,
                  validator: (value) => value == null || value.length < 6 ? 'Password too short' : null,
                ),
                
                const Gap(40),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Perform Signup
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ).animate().scale(delay: 600.ms, curve: Curves.backOut),
                
                const Gap(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: AppColors.neutrals07)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text('Sign In', style: TextStyle(color: AppColors.primary01, fontWeight: FontWeight.bold)),
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
        onTap: () => setState(() => _isVendor = title == 'Vendor'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary012.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary01 : AppColors.neutrals02,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary01 : AppColors.neutrals04, size: 32),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primary01 : AppColors.neutrals07,
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
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.neutrals08)),
        const Gap(8),
        TextFormField(
          obscureText: isPassword && !_isPasswordVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.neutrals05),
            prefixIcon: Icon(icon, color: AppColors.neutrals04),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordVisible ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash()),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutrals02),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutrals02),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary01, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
