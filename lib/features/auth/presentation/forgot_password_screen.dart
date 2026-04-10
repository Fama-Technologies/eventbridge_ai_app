import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(40),
                Center(
                  child: SvgPicture.asset(
                    'assets/icons/Icon.svg',
                    width: 70,
                    height: 70,
                    colorFilter: ColorFilter.mode(
                      AppColors.primary01,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const Gap(32),
                Text(
                  'Forgot Password?',
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF141E30),
                  ),
                ),
                const Gap(12),
                Text(
                  'Don\'t worry! It happens. Please enter the email address associated with your account.',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const Gap(40),

                // Email Field
                Text(
                  'Email Address',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF141E30),
                  ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: GoogleFonts.roboto(
                      color: const Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: AppColors.primary01,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const Gap(40),

                // Reset Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Show Success Message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification code sent to your email'),
                        ),
                      );
                      context.push('/verify-code');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primary01.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'Reset Password',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
