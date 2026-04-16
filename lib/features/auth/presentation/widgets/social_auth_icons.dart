import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact row of social sign-in icon buttons (Google + Apple).
///
/// Replaces the older full-width "Continue with Google" button. Centered,
/// uses neutral-bordered circular chips so the primary CTA (email signup)
/// stays visually dominant. Apple is a placeholder until an Apple Developer
/// account is set up — tapping it shows a "coming soon" snackbar.
class SocialAuthIcons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;

  const SocialAuthIcons({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
  });

  void _showAppleComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIconButton(
          tooltip: 'Continue with Google',
          onPressed: isLoading ? null : onGooglePressed,
          child: Image.asset('assets/icons/google.png', height: 24, width: 24),
        ),
        const SizedBox(width: 20),
        _SocialIconButton(
          tooltip: 'Continue with Apple',
          onPressed: isLoading
              ? null
              : (onApplePressed ?? () => _showAppleComingSoon(context)),
          child: const Icon(Icons.apple, size: 28, color: Colors.black),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String tooltip;

  const _SocialIconButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.shadesWhite,
        shape: CircleBorder(
          side: BorderSide(
            color: AppColors.neutrals03,
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Opacity(
              opacity: onPressed == null ? 0.5 : 1.0,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
