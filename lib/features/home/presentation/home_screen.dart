import 'package:flutter/material.dart';
import 'package:gap/gap.dart' as gap;
import 'package:eventbridge_ai/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 3; // Default to map/tracking as per mockup

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Top Graphic/Map Section (Mockup gray area) ──
          Container(
            width: double.infinity,
            height: 450,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFD9D9D9) : const Color(0xFFE5E5E5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.elliptical(500, 250),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 60,
                  left: 20,
                  child: _buildCircularIcon(Icons.arrow_back_rounded),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: _buildCircularIcon(Icons.more_vert_rounded),
                ),
              ],
            ),
          ),

          // ── Stats Dashboard (Dark Bottom Sheet) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 500,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const gap.Gap(12),
                  // Drag Handle
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const gap.Gap(32),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton('Stop', Colors.white10),
                        ),
                        const gap.Gap(16),
                        Expanded(
                          child: _buildActionButton(
                            'Start',
                            AppColors.primary01,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const gap.Gap(40),

                  // Stats Grid
                  _buildStatsGrid(),

                  const Spacer(),
                  // Custom Bottom Navigation
                  _buildCustomBottomNav(),
                  const gap.Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIcon(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary01.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary01, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildActionButton(String label, Color color) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatItem('Time', '00:35:44')),
              _buildVerticalDivider(),
              Expanded(child: _buildStatItem('Distance (mi)', '0:53')),
            ],
          ),
          const gap.Gap(32),
          Row(
            children: [
              Expanded(child: _buildStatItem('Avg. Pace', '5:33')),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatItem(
                  'Bpm',
                  '60',
                  valueColor: AppColors.primary01,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.white12);
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white54,
            fontWeight: FontWeight.w400,
          ),
        ),
        const gap.Gap(4),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFDCBBE),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled),
          _buildNavItem(1, Icons.grid_view_rounded),
          _buildNavItem(2, Icons.show_chart_rounded),
          _buildNavItem(3, Icons.map_rounded),
          _buildNavItem(4, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary01 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.primary01,
          size: 28,
        ),
      ),
    );
  }
}
