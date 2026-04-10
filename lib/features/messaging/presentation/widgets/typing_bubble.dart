import 'package:flutter/material.dart';

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        child: const Text(
          '...',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
