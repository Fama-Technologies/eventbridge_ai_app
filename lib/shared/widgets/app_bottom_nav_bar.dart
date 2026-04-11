import 'dart:math' as math;

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/messaging/presentation/providers/unread_messages_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'eventbridge_logo_icon.dart';

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return FloatingBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
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
      ],
    );
  }
}

class FloatingBottomNavItem {
  final IconData? icon;
  final String label;
  final bool isLogo;
  final int badge;

  const FloatingBottomNavItem({
    this.icon,
    required this.label,
    this.isLogo = false,
    this.badge = 0,
  });
}

class FloatingBottomNavBar extends StatelessWidget {
  final List<FloatingBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 32;
          const outerPadding = 8.0;
          const gap = 8.0;
          const minInactiveWidth = 40.0;
          final contentWidth = math.max(
            0,
            availableWidth - (outerPadding * 2) - (gap * (items.length - 1)),
          );
          final idealActiveWidth = math
              .min(132.0, contentWidth * 0.34)
              .toDouble();
          final inactiveWidth =
              (items.length > 1
                      ? math.max(
                          minInactiveWidth,
                          ((contentWidth - idealActiveWidth) /
                                  (items.length - 1))
                              .floorToDouble(),
                        )
                      : contentWidth)
                  .toDouble();
          final activeWidth = items.length > 1
              ? math
                    .max(
                      idealActiveWidth,
                      contentWidth - (inactiveWidth * (items.length - 1)),
                    )
                    .toDouble()
              : contentWidth.toDouble();

          return Container(
            padding: const EdgeInsets.all(outerPadding),
            decoration: BoxDecoration(
              color: AppColors.navBackground,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _FloatingNavButton(
                    item: items[i],
                    isActive: i == currentIndex,
                    activeWidth: activeWidth,
                    inactiveWidth: inactiveWidth,
                    onTap: () => onTap(i),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingNavButton extends StatelessWidget {
  final FloatingBottomNavItem item;
  final bool isActive;
  final double activeWidth;
  final double inactiveWidth;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.item,
    required this.isActive,
    required this.activeWidth,
    required this.inactiveWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const navButtonHeight = 52.0;
    final iconBoxSize = item.isLogo ? 28.0 : 22.0;
    final iconColor = isActive
        ? AppColors.white
        : AppColors.white.withValues(alpha: 0.72);
    final backgroundColor = isActive ? AppColors.primary01 : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: isActive ? activeWidth : inactiveWidth,
      height: navButtonHeight,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (item.isLogo)
                          EventBridgeLogoIcon(color: iconColor, size: 28)
                        else
                          Icon(item.icon, color: iconColor, size: 22),
                        if (item.badge > 0)
                          Positioned(
                            top: -2,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.navBackground,
                                  width: 1.4,
                                ),
                              ),
                              child: Text(
                                item.badge > 9 ? '9+' : '${item.badge}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerLeft,
                    child: ClipRect(
                      child: Align(
                        widthFactor: isActive ? 1 : 0,
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
