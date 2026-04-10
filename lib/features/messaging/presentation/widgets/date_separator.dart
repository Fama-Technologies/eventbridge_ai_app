import 'package:flutter/material.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
      ),
    );
  }
}
