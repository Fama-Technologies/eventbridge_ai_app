import 'package:flutter/material.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/features/vendors_screen/home.dart';
import 'package:eventbridge_ai/features/vendors_screen/leads.dart';
import 'package:eventbridge_ai/features/vendors_screen/messages_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/settings.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_packages_screen.dart';

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
    const VendorPackagesScreen(),
    const MessagesListScreen(),
    const VendorSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD9CD),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFA892), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded),
              _buildNavItem(1, Icons.dashboard_customize_rounded),
              _buildNavItem(2, Icons.bar_chart_rounded),
              _buildNavItem(3, Icons.campaign_rounded),
              _buildNavItem(4, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.white : const Color(0xFFEF9B63);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary01 : const Color(0xFFF2F3F6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary01.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
