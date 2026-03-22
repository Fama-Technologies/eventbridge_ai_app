import 'package:flutter/material.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

enum ToastType { error, success, info }

class AppToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any existing toast
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;
        },
        duration: duration,
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color iconBgColor;
    IconData icon;
    Color iconColor;

    switch (widget.type) {
      case ToastType.error:
        bgColor = isDark ? const Color(0xFF2D1414) : const Color(0xFFFEF2F2);
        borderColor = isDark ? const Color(0xFF5C2020) : const Color(0xFFFECACA);
        iconBgColor = const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        iconColor = Colors.white;
        break;
      case ToastType.success:
        bgColor = isDark ? const Color(0xFF142D1A) : const Color(0xFFF0FDF4);
        borderColor = isDark ? const Color(0xFF1E5C2E) : const Color(0xFFBBF7D0);
        iconBgColor = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
        iconColor = Colors.white;
        break;
      case ToastType.info:
        bgColor = isDark ? const Color(0xFF14202D) : const Color(0xFFEFF6FF);
        borderColor = isDark ? const Color(0xFF1E3A5C) : const Color(0xFFBFDBFE);
        iconBgColor = AppColors.primary01;
        icon = Icons.info_rounded;
        iconColor = Colors.white;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _controller.reverse().then((_) {
                  if (mounted) widget.onDismiss();
                });
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
