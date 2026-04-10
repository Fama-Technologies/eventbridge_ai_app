import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineFallback extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String subtitle;

  const OfflineFallback({
    super.key,
    required this.onRetry,
    this.title = 'No Internet Connection',
    this.subtitle = 'It seems you are offline. Please check your network settings or Wi-Fi connection.',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the new text-free premium illustration
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Image.asset(
                'assets/images/no_internet_v3.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            _buildRetryButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary01,
            AppColors.primary02,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary01.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Try Again',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Ensure "File" import is available
// Actually I need to add dart:io
