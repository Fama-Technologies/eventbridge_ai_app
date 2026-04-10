import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Terms of Service', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40, // Account for padding
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkNeutral02 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLastUpdated(isDark),
                    const SizedBox(height: 24),
                    _buildSection('1. Acceptance of Terms', 'By downloading, installing, or using the EventBridge application, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.', isDark),
                    _buildSection('2. Service Description', 'EventBridge is an AI-powered event planning marketplace that connects customers with vetted vendors across categories such as catering, photography, décor, and entertainment. The platform provides intelligent matching, real-time communication, and lead management tools.', isDark),
                    _buildSection('3. User Accounts', 'You must provide accurate, complete information when creating an account. You are responsible for maintaining the confidentiality of your login credentials and for all activity under your account. EventBridge reserves the right to suspend or terminate accounts that violate these terms.', isDark),
                    _buildSection('4. Privacy Policy', 'Your privacy matters to us. We collect and process personal data in accordance with our Privacy Policy. By using the app, you consent to the collection and use of information as described therein, including analytics, usage patterns, and communication logs.', isDark),
                    _buildSection('5. Vendor Responsibilities', 'Vendors listed on EventBridge are independent service providers. EventBridge does not guarantee the quality, timeliness, or accuracy of services rendered by any vendor. Users engage vendors at their own discretion and risk.', isDark),
                    _buildSection('6. Intellectual Property', 'All content, designs, logos, and software within the EventBridge platform are the intellectual property of EventBridge Technologies Ltd. Unauthorized reproduction, distribution, or modification is prohibited.', isDark),
                    _buildSection('7. Limitation of Liability', 'To the fullest extent permitted by law, EventBridge shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the platform.', isDark),
                    _buildSection('8. Modifications', 'EventBridge reserves the right to modify these Terms at any time. Continued use of the app after changes constitutes acceptance of the updated Terms.', isDark),
                    const Spacer(),
                    const SizedBox(height: 24),
                    Center(
                      child: Text('© 2026 EventBridge Technologies Ltd.', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white24 : Colors.black26)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLastUpdated(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.primary01.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Text('Last Updated: April 1, 2026', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary01)),
    );
  }

  Widget _buildSection(String title, String body, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : const Color(0xFF64748B), height: 1.6)),
        ],
      ),
    );
  }
}
