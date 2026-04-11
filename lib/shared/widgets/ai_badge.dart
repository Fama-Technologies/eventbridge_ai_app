import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tiny "AI" pill used next to AI-driven sections / cards.
/// Spec: claude_prompt/eventbridge_flutter_prompt.md → "AiBadge".
class AiBadge extends StatelessWidget {
  const AiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
