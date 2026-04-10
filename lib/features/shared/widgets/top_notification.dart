import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopNotificationOverlay {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onTap,
    String? imageUrl,
  }) {
    // Dismiss previous if any
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _currentEntry?.remove();
                _currentEntry = null;
                onTap();
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _currentEntry?.remove();
                  _currentEntry = null;
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A24).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary01.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary01),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'now',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate()
               .slideY(begin: -2.0, end: 0, curve: Curves.easeOutBack, duration: const Duration(milliseconds: 600))
               .fadeIn(),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentEntry == entry) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}
