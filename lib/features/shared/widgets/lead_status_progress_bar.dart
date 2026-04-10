import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

/// A horizontal step indicator showing the journey of a lead:
/// Inquiry Sent → Accepted → Booked → Completed
///
/// [status] values: 'pending', 'accepted', 'booked', 'completed', 'rejected'
class LeadStatusProgressBar extends StatelessWidget {
  final String status;

  const LeadStatusProgressBar({super.key, required this.status});

  static const _steps = [
    (label: 'Inquiry\nSent', icon: Icons.send_rounded),
    (label: 'Accepted', icon: Icons.handshake_rounded),
    (label: 'Booked', icon: Icons.event_available_rounded),
    (label: 'Completed', icon: Icons.star_rounded),
  ];

  /// Index of the CURRENT (in-progress) step.
  /// Steps before this index are DONE; steps after are UPCOMING.
  int get _activeStep {
    switch (status) {
      case 'accepted':
        return 1;
      case 'booked':
        return 2;
      case 'completed':
        return 4; // all steps done
      default:
        return 0; // pending / rejected
    }
  }

  bool get _isRejected => status == 'rejected';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activeStep;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: _isRejected
          ? _buildRejectedBanner(isDark)
          : Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  // Connector line between steps
                  final lineAfterStep = i ~/ 2;
                  final lineDone = active > lineAfterStep;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: lineDone
                            ? AppColors.primary01
                            : isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                // Step node
                final stepIndex = i ~/ 2;
                final isDone = active > stepIndex;
                final isCurrent = active == stepIndex;
                final step = _steps[stepIndex];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.primary01
                            : isCurrent
                                ? AppColors.primary01.withValues(alpha: 0.12)
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF3F4F6),
                        border: isCurrent
                            ? Border.all(color: AppColors.primary01, width: 2)
                            : null,
                        boxShadow: isDone
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary01.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: 14,
                        color: isDone
                            ? Colors.white
                            : isCurrent
                                ? AppColors.primary01
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFFD1D5DB),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        height: 1.2,
                        fontWeight: (isDone || isCurrent)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isDone
                            ? AppColors.primary01
                            : isCurrent
                                ? AppColors.primary01
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  Widget _buildRejectedBanner(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cancel_rounded,
          size: 16,
          color: AppColors.errorsMain,
        ),
        const SizedBox(width: 8),
        Text(
          'Vendor declined this inquiry',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.errorsMain,
          ),
        ),
      ],
    );
  }
}
