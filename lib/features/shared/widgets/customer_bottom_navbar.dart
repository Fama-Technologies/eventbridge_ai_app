import 'package:eventbridge/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/messaging/presentation/providers/unread_messages_provider.dart';

class CustomerBottomNavbar extends ConsumerWidget {
  final String currentRoute;

  const CustomerBottomNavbar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(totalUnreadCountProvider);

    final items = [
      const FloatingBottomNavItem(icon: Icons.home_rounded, label: 'Home'),
      const FloatingBottomNavItem(
        icon: Icons.favorite_border_rounded,
        label: 'Saved',
      ),
      const FloatingBottomNavItem(label: 'Matches', isLogo: true),
      FloatingBottomNavItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        badge: unreadCount,
      ),
      const FloatingBottomNavItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
      ),
    ];

    final routes = [
      '/customer-home',
      '/customer-home', // Mapping Saved to Home with index handling if needed
      '/ai-results',
      '/customer-chats',
      '/customer-profile',
    ];

    int currentIndex = routes.indexOf(currentRoute);
    if (currentIndex == -1) {
      if (currentRoute == '/customer-explore') currentIndex = 0;
      else currentIndex = 0;
    }

    return FloatingBottomNavBar(
      items: items,
      currentIndex: currentIndex,
      onTap: (index) {
        // Handle Saved specially if it's just a tab in Home
        if (index == 1) {
          // If we had a specific /saved route we'd use it, for now go to home
          context.go('/customer-home'); 
        } else {
          context.go(routes[index]);
        }
      },
    );
  }
}

