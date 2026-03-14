import 'package:flutter/material.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/features/vendors_screen/home.dart';
import 'package:eventbridge_ai/features/vendors_screen/leads.dart';
import 'package:eventbridge_ai/features/vendors_screen/messages_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/settings.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_packages_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const VendorHomeScreen(),
    const LeadsScreen(),
    const MessagesListScreen(),
    const VendorProfileScreen(),
  ];

  static const _navItems = [
    _NavItemData(icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.dashboard_customize_rounded, label: 'Leads'),
    _NavItemData(icon: Icons.campaign_rounded, label: 'Messages'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
  ];

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
                      padding: EdgeInsets.only(right: i == _navItems.length - 1 ? 0 : 16),
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
      onTap: () => setState(() => _selectedIndex = index),
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
        child: Icon(
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
