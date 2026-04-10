import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/messaging/presentation/providers/unread_messages_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/presentation/customer_home_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_explore.dart';
import 'package:eventbridge/features/messaging/presentation/screens/chats_list_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/websocket_service.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';

class Bottomnavscreen extends StatefulWidget {
  const Bottomnavscreen({super.key});

  @override
  State<Bottomnavscreen> createState() => _BottomnavscreenState();
}

class _BottomnavscreenState extends State<Bottomnavscreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    CustomerExplore(),
    ChatsListScreen(),
    CustomerProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WebSocketService().connect();
    WebSocketService().addListener(_onNewMessage);
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onNewMessage);
    super.dispose();
  }

  void _onNewMessage(Map<String, dynamic> data) {
    if (data['type'] == 'NEW_MESSAGE') {
      final chatId = data['chatId'];
      if (chatId == null || WebSocketService.activeChatId == chatId) return;

      final senderName = data['senderName'] ?? 'Vendor';
      final text = data['text'] ?? data['message']?['text'] ?? 'New message';

      TopNotificationOverlay.show(
        context: context,
        title: senderName,
        message: text,
        onTap: () {
          context.push('/customer-chat/$chatId');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: bottomPadding > 0 ? 0 : 8),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                return Expanded(
                  child: _NavBarItem(
                    item: _navItems[i],
                    isSelected: _currentIndex == i,
                    isDark: isDark,
                    onTap: () => _onTabTapped(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Data ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─── Individual Nav Bar Item Widget ───────────────────────────────────────────
class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary01;
    final inactiveColor = isDark
        ? AppColors.darkNeutral06
        : const Color(0xFFB0B0B0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 24 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon with animated size/color
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: item.label == 'Messages'
                  ? Consumer(
                      builder: (context, ref, child) {
                        final unreadCount = ref.watch(totalUnreadCountProvider);
                        return Badge(
                          label: Text(unreadCount.toString()),
                          isLabelVisible: unreadCount > 0,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          largeSize: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey(isSelected),
                            color: isSelected ? activeColor : inactiveColor,
                            size: isSelected ? 26 : 24,
                          ),
                        );
                      },
                    )
                  : Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      color: isSelected ? activeColor : inactiveColor,
                      size: isSelected ? 26 : 24,
                    ),
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                height: 1.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
