import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/matching/data/matching_repository.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/core/network/api_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';

class CustomerChatDetailScreen extends ConsumerStatefulWidget {
  final String vendorId; // This might actually be chatId if coming from chats list
  const CustomerChatDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<CustomerChatDetailScreen> createState() => _CustomerChatDetailScreenState();
}

class _CustomerChatDetailScreenState extends ConsumerState<CustomerChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _chatId;
  MatchVendor? _vendor;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        _initializeChat(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeChat(String customerId) async {
    try {
      // 1. Resolve vendor info
      final vRepo = MatchingRepository();
      _vendor = await vRepo.getVendorById(widget.vendorId);
      
      // 2. Resolve chatId
      final initRes = await ApiService.instance.initChat(customerId, widget.vendorId);
      if (initRes['success'] == true) {
        _chatId = initRes['chatId'];
        await _fetchMessages(customerId);
        _startPolling(customerId);
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling(String customerId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(customerId, isPolling: true);
    });
  }

  Future<void> _fetchMessages(String customerId, {bool isPolling = false}) async {
    if (_chatId == null) return;
    try {
      final res = await ApiService.instance.getCustomerChatMessages(_chatId!);
      if (res['success'] == true) {
        final List newMsgs = res['messages'] as List;
        final mapped = newMsgs.map((m) => {
          'text': m['text'],
          'isMe': m['sender_id'].toString() == customerId,
          'time': _formatTime(m['created_at']),
        }).toList();

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(mapped);
          });
        }
      }
    } catch (_) {}
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'now';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '10:00 AM';
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    _controller.clear();
    // Optimistic update
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'Just now',
      });
    });

    try {
      await ApiService.instance.sendCustomerChatMessage(
        chatId: _chatId!,
        senderId: user.uid,
        text: text,
      );
      _fetchMessages(user.uid);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary01),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary01.withValues(alpha: 0.1),
              backgroundImage: (_vendor?.portfolio.isNotEmpty ?? false) 
                ? NetworkImage(_vendor!.portfolio.first)
                : null,
              child: (_vendor?.portfolio.isEmpty ?? true) 
                ? const Icon(Icons.person_rounded, color: AppColors.primary01, size: 20)
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _vendor?.name ?? 'Vendor',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary01,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
        : Column(
            children: [
              Expanded(
                child: _messages.isEmpty 
                  ? Center(child: Text('No messages yet', style: GoogleFonts.outfit(color: Colors.black38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
              ),
              _buildInputArea(),
            ],
          ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isMe = msg['isMe'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary01 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              msg['text'],
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isMe ? Colors.white : AppColors.primary01,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg['time'],
            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary01,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
