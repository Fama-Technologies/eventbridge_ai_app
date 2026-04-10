import 'package:flutter/material.dart';

enum TickStatus { sent, delivered, read }

class TickIcon extends StatelessWidget {
  final TickStatus status;
  const TickIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;
    switch (status) {
      case TickStatus.sent:
        iconData = Icons.check;
        color = Colors.grey;
        break;
      case TickStatus.delivered:
        iconData = Icons.done_all;
        color = Colors.grey;
        break;
      case TickStatus.read:
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
    }
    return Icon(
      iconData,
      color: color,
      size: 16,
    );
  }
}
