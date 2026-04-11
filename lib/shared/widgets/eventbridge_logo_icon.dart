import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// EventBridge fireworks logo — used for the Matches tab and Header
class EventBridgeLogoIcon extends StatelessWidget {
  final Color color;
  final double size;

  const EventBridgeLogoIcon({
    super.key,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/Icon.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

