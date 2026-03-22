import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class CustomerBottomNavbar extends StatelessWidget {
  final String currentRoute;

  const CustomerBottomNavbar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home', '/customer-home'),
      (Icons.auto_awesome_rounded, 'Matches', '/matches'),
      (Icons.hub_rounded, 'Bridge', '/match-intake'), // Starts the AI flow
      (Icons.chat_bubble_rounded, 'Chats', '/customer-chats'),
      (Icons.person_rounded, 'Profile', '/customer-profile'),
    ];

    return Container(
      height: 85,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final isSelected = currentRoute == item.$3;
          final isBridge = item.$2 == 'Bridge';

          if (isBridge) {
            return GestureDetector(
              onTap: () => context.go(item.$3),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary01,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary01.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: Colors.white, size: 20),
                    Text(
                      'Explore',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => context.go(item.$3),
            child: SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.$1,
                    color: isSelected ? AppColors.primary01 : const Color(0xFF9CA3AF),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary01 : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
