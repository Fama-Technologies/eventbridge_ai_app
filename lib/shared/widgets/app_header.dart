import 'package:flutter/material.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppHeader extends StatelessWidget {
  final String? greeting;
  final String? username;
  final bool showSearch;
  final bool showBack;
  final String? title; // for non-home screens
  final VoidCallback? onSearchTap;
  final VoidCallback? onAvatarTap;
  final String? avatarLetter; // Optional override for initials
  final String? searchHint;
  final bool showFilterIcon;
  final Widget? customSearchWidget;

  const AppHeader({
    super.key,
    this.greeting,
    this.username,
    this.showSearch = false,
    this.showBack = false,
    this.title,
    this.onSearchTap,
    this.onAvatarTap,
    this.avatarLetter,
    this.searchHint,
    this.showFilterIcon = true,
    this.customSearchWidget,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo/back + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              showBack ? _BackButton() : _LogoRow(),
              _AvatarButton(
                onTap: onAvatarTap,
                initials:
                    avatarLetter ??
                    (username != null && username!.isNotEmpty
                        ? username![0].toUpperCase()
                        : 'U'),
              ),
            ],
          ),

          // Greeting (home screen only)
          if (greeting != null) ...[
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${greeting!} ',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: username ?? '',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 20, color: AppColors.white),
            ),
            const SizedBox(height: 14),
          ],

          // Non-home screen title
          if (title != null) ...[
            const SizedBox(height: 10),
            Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Search bar (home screen only or any screen that explicitly requests it)
          if (showSearch || customSearchWidget != null) ...[
            customSearchWidget ??
                _SearchBar(
                  onTap: onSearchTap,
                  hint: searchHint,
                  showFilter: showFilterIcon,
                ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// Logo + app name
class _LogoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/Icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'EventBridge',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

// Back button (for non-home screens)
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.white,
        size: 22,
      ),
    );
  }
}

// Avatar button (top right)
class _AvatarButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String initials;
  const _AvatarButton({this.onTap, required this.initials});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withOpacity(0.25),
          border: Border.all(
            color: AppColors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Search bar
class _SearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String? hint;
  final bool showFilter;
  const _SearchBar({this.onTap, this.hint, this.showFilter = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFBDBDBD),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint ?? 'Search events near you...',
                style: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
              ),
            ),
            if (showFilter)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
