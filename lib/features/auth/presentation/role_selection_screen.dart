import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutrals01,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.neutrals08),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: CircleAvatar(
          backgroundColor: AppColors.primary01,
          radius: 16,
          child: Icon(Icons.link, color: Colors.white, size: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How will you use\nEventBridge?',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select your role to get started with automated\nvendor matching.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            _buildRoleCard(
              title: 'I am a Customer',
              subtitle: 'I am planning an event and looking\nfor vendors.',
              icon: Icons.celebration,
              iconColor: AppColors.primary01,
              iconBackground: const Color(0xFFFFEBE6),
              value: 'customer',
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              title: 'I am a Vendor',
              subtitle:
                  'I provide services for events and want\nto find clients.',
              icon: Icons.storefront,
              iconColor: const Color(0xFF4B5563),
              iconBackground: const Color(0xFFF3F4F6),
              value: 'vendor',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedRole == null
                  ? null
                  : () {
                      context.push('/create-account');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                disabledBackgroundColor: AppColors.primary01.withValues(
                  alpha: 0.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String value,
  }) {
    final isSelected = selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary01 : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary01.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.primary01)
                  : const Icon(Icons.circle_outlined, color: Color(0xFFE5E7EB)),
            ),
          ],
        ),
      ),
    );
  }
}
