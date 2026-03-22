import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventRequestScreen extends ConsumerStatefulWidget {
  const EventRequestScreen({super.key});

  @override
  ConsumerState<EventRequestScreen> createState() => _EventRequestScreenState();
}

class _EventRequestScreenState extends ConsumerState<EventRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Event Request Screen (Blank)'),
      ),
    );
  }
}
