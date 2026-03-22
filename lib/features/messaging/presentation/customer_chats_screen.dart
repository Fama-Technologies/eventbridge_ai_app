import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/shared/widgets/customer_bottom_navbar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:eventbridge/core/network/api_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';

class CustomerChatsScreen extends ConsumerStatefulWidget {
  const CustomerChatsScreen({super.key});

  @override
  ConsumerState<CustomerChatsScreen> createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends ConsumerState<CustomerChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Map<String, dynamic>>>? _chatsFuture;

  @override
  void initState() {
    super.initState();
  }

  void _fetchChats(String userId) {
    if (userId.isEmpty) return;
    setState(() {
      _chatsFuture = ApiService.instance.getCustomerChats(userId).then((res) {
        if (res['success'] == true) {
          return List<Map<String, dynamic>>.from(res['chats']).map((c) {
            return {
              'id': c['id']?.toString() ?? '',
              'vendorName': c['vendor_name'] ?? 'Vendor',
              'imageUrl': c['vendor_image'] ?? 'https://via.placeholder.com/150',
              'lastMessage': c['last_message'] ?? '',
              'time': _formatTime(c['last_message_time']),
              'unreadCount': c['unread_count_client'] ?? 0,
            };
          }).toList();
        }
        return <Map<String, dynamic>>[];
      }).catchError((_) => <Map<String, dynamic>>[]);
    });
  }

  String _formatTime(dynamic timeStr) {
    if (timeStr == null) return '';
    try {
      final dt = DateTime.parse(timeStr.toString());
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final userId = user?.uid ?? '';
    
    // Refresh if userId becomes available
    if (userId.isNotEmpty && _chatsFuture == null) {
      _fetchChats(userId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final unreadCount = chats.where((c) => (c['unreadCount'] ?? 0) > 0).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$unreadCount NEW CONVERSATIONS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black38,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary01)),
                  ),
                )
              else if (chats.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No chats found.',
                        style: GoogleFonts.outfit(color: Colors.black54),
                      ),
                    ),
                  ),
                )
              else
                _buildChatList(context, chats),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNavbar(currentRoute: '/customer-chats'),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary01,
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary01,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary01.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primary01, size: 22),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.outfit(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Search vendors...',
          hintStyle: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.3), fontSize: 16),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.3), size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<Map<String, dynamic>> allChats) {
    final filteredChats = allChats.where((c) {
      if (_searchQuery.isEmpty) return true;
      return (c['vendorName'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chat = filteredChats[index];
          return _buildChatTile(context, chat, index);
        },
        childCount: filteredChats.length,
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat, int index) {
    final bool isUnread = chat['unreadCount'] > 0;
    return InkWell(
      onTap: () => context.push('/customer-chat/${chat['id']}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: NetworkImage(chat['imageUrl']), fit: BoxFit.cover),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['vendorName'],
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.primary01,
                        ),
                      ),
                      Text(
                        chat['time'],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isUnread ? AppColors.primary01 : Colors.black38,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isUnread ? Colors.black : Colors.black54,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: AppColors.primary01, shape: BoxShape.circle),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: const Duration(seconds: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: (index * 80))).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

