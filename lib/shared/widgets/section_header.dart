import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Title row that introduces a section, with optional "See all" link and
/// optional trailing widget (e.g. AiBadge).
/// Spec: claude_prompt/eventbridge_flutter_prompt.md → "SectionHeader".
class SectionHeader extends StatelessWidget {
  final String title;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.seeAllLabel = 'See all',
    this.onSeeAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.sectionHeader),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllLabel ?? 'See all',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
