import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/messaging/presentation/providers/unread_messages_provider.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/plan_upgrade_overlay.dart';
import 'package:eventbridge/features/vendors_screen/home.dart';
import 'package:eventbridge/features/vendors_screen/leads.dart';
import 'package:eventbridge/features/messaging/presentation/screens/chats_list_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_packages_screen.dart';
import 'package:eventbridge/features/vendors_screen/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/websocket_service.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';

class VendorMainScreen extends ConsumerStatefulWidget {
  const VendorMainScreen({super.key});
 
  @override
  ConsumerState<VendorMainScreen> createState() => _VendorMainScreenState();
}
 
class _VendorMainScreenState extends ConsumerState<VendorMainScreen> {
  int _selectedIndex = 0;
 
  bool _isRestricted() {
    final plan = StorageService().getString('vendor_plan');
    return plan?.toLowerCase() == 'free';
  }
 
  void _showUpgradeOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const PlanUpgradeOverlay(),
    );
  }
 
  final List<Widget> _screens = [
    const VendorHomeScreen(),
    const LeadsScreen(),
    const ChatsListScreen(),
    const VendorPackagesScreen(),
    const VendorProfileScreen(),
  ];
 
  static const _navItems = [
    _NavItemData(icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.dashboard_customize_rounded, label: 'Leads'),
    _NavItemData(icon: Icons.chat_bubble_rounded, label: 'Messages'),
    _NavItemData(icon: Icons.inventory_2_rounded, label: 'Packages'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
  ];
 
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
      
      final senderName = data['senderName'] ?? 'Customer';
      final text = data['text'] ?? data['message']?['text'] ?? 'New message';
 
      TopNotificationOverlay.show(
        context: context,
        title: senderName,
        message: text,
        onTap: () {
          context.push('/vendor-chat/$chatId');
        },
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
 
    return Scaffold(
      extendBody: true, // Allows the body to scroll under the floating nav bar
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkNeutral02
                        : const Color(0xFFFFD9CD),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF444444)
                          : const Color(0xFFFFA892),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_navItems.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: i == _navItems.length - 1 ? 0 : 16,
                        ),
                        child: _buildNavItem(i, _navItems[i], isDark),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildNavItem(int index, _NavItemData item, bool isDark) {
    final isSelected = _selectedIndex == index;
    final activeColor = AppColors.primary01;
    final inactiveColor = isDark
        ? const Color(0xFFBB7755)
        : const Color(0xFFEF9B63);
 
    return GestureDetector(
      onTap: () {
        if (index != 0 && _isRestricted()) {
          _showUpgradeOverlay();
          return;
        }
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? activeColor
              : isDark
              ? const Color(0xFF333333) // slightly lighter than background
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: index == 2 // Messages index
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
                      item.icon,
                      color: isSelected ? Colors.white : inactiveColor,
                      size: 24,
                    ),
                  );
                },
              )
            : Icon(
                item.icon,
                color: isSelected ? Colors.white : inactiveColor,
                size: 24,
              ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}
