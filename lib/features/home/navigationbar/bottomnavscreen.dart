import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventbridge/features/home/presentation/customer_home_screen.dart';
import 'package:eventbridge/features/home/presentation/saved_vendors_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_profile_screen.dart';
import 'package:eventbridge/features/matching/presentation/matches_list_screen.dart';
import 'package:eventbridge/features/messaging/presentation/screens/chats_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/websocket_service.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';
import 'package:eventbridge/shared/widgets/app_bottom_nav_bar.dart';

class Bottomnavscreen extends StatefulWidget {
  final int initialIndex;
  const Bottomnavscreen({super.key, this.initialIndex = 0});

  @override
  State<Bottomnavscreen> createState() => _BottomnavscreenState();
}

class _BottomnavscreenState extends State<Bottomnavscreen>
    with TickerProviderStateMixin {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WebSocketService().connect();
    WebSocketService().addListener(_onNewMessage);
  }

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    SavedVendorsScreen(),
    MatchesListScreen(),
    ChatsListScreen(),
    CustomerProfileScreen(),
  ];


  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  void didUpdateWidget(Bottomnavscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onNewMessage);
    super.dispose();
  }

  void _onNewMessage(Map<String, dynamic> data) {
    if (data['type'] == 'NEW_MESSAGE') {
      final chatId = data['chatId'];
      if (chatId == null || WebSocketService.activeChatId == chatId) return;

      final senderName = data['senderName'] ?? 'Vendor';
      final text = data['text'] ?? data['message']?['text'] ?? 'New message';

      TopNotificationOverlay.show(
        context: context,
        title: senderName,
        message: text,
        onTap: () {
          context.push('/customer-chat/$chatId');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
