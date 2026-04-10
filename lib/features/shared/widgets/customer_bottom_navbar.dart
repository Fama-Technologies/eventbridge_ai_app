import 'package:flutter/material.dart';
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
    // 4 icons matching the design: Home, Explore/Compass, Favorites/Heart, Profile/Person
    final items = [
      (Icons.home_rounded, '/customer-home'),
      (Icons.explore_outlined, '/customer-explore'),
      (Icons.chat_bubble_outline_rounded, '/customer-chats'),
      (Icons.person_outline_rounded, '/customer-profile'),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isSelected = currentRoute == item.$2;

          return GestureDetector(
            onTap: () => context.go(item.$2),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Active indicator line at the top
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary01,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(height: 3),
                  const Spacer(),
                  Icon(
                    item.$1,
                    color: isSelected ? AppColors.primary01 : Colors.grey.shade400,
                    size: 26,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
