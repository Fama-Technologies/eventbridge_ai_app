import 'package:flutter/material.dart';

class LockedChatBanner extends StatelessWidget {
  const LockedChatBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      padding: const EdgeInsets.all(8.0),
      child: const Row(
        children: [
          Icon(Icons.lock),
          SizedBox(width: 8),
          Expanded(
            child: Text('Waiting for vendor to accept — tap to view lead'),
          ),
        ],
      ),
    );
  }
}
