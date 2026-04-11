import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Floating dark pill navigation. The active item reveals its label via
/// AnimatedSize; inactive items are icon-only.
/// Spec: claude_prompt/eventbridge_flutter_prompt.md → "FloatingNavBar".
class FloatingNavBar extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onTap;
  final List<NavBarItem> items;

  const FloatingNavBar({
    super.key,
    this.initialIndex = 0,
    this.onTap,
    this.items = const [
      NavBarItem(icon: Icons.home_rounded, label: 'Home'),
      NavBarItem(icon: Icons.explore_rounded, label: 'Explore'),
      NavBarItem(icon: Icons.favorite_rounded, label: 'Saved'),
      NavBarItem(icon: Icons.person_rounded, label: 'Profile'),
    ],
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  late int _selected = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.items.length,
            (i) => _NavButton(
              item: widget.items[i],
              isActive: _selected == i,
              onTap: () {
                setState(() => _selected = i);
                widget.onTap?.call(i);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavBarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: AppColors.white, size: 18),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final String label;
  const NavBarItem({required this.icon, required this.label});
}
