import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  String _sortBy = 'recent';
  List<dynamic> _chats = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorChats(userId);
      if (mounted && result['success'] == true) {
        setState(() {
          _chats = result['chats'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: _buildSearchBar(isDark),
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
                    '${_chats.where((c) => (c['unreadCount'] as int? ?? 0) > 0).length} NEW CONVERSATIONS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))),
          if (!_isLoading && _chats.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    'No conversions found',
                    style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
            ),
          if (!_isLoading && _chats.isNotEmpty)
            _buildChatList(context, isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary01,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 30),
      ).animate().scale(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/vendor-help-support'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5224), // Vibrant orange requested
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5224).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: () => _showFilterSheet(context, isDark),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Icon(Icons.tune_rounded, color: isDark ? Colors.white : Colors.black, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
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
        style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.3), fontSize: 16),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.3), size: 24),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, bool isDark) {
    final filteredChats = _chats.where((c) {
      if (_searchQuery.isEmpty) return true;
      final name = (c['clientName'] as String).toLowerCase();
      final msg = (c['lastMessage'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             msg.contains(_searchQuery.toLowerCase());
    }).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chat = filteredChats[index];
          return _buildChatTile(context, chat, index, isDark);
        },
        childCount: filteredChats.length,
      ),
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filter Chats',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 24),
            _buildFilterOption('All Messages', 'recent', Icons.chat_bubble_outline_rounded, isDark),
            _buildFilterOption('Unread First', 'unread', Icons.mark_chat_unread_outlined, isDark),
            _buildFilterOption('Archived', 'archived', Icons.archive_outlined, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value, IconData icon, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtered by $title',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isDark ? AppColors.darkNeutral01 : const Color(0xFF1A1A24),
            elevation: 10,
            margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary01.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary01 : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary01 : (isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.primary01 : (isDark ? Colors.white : Colors.black))),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.primary01, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, dynamic chat, int index, bool isDark) {
    final bool isUnread = (chat['unreadCount'] as int? ?? 0) > 0;
    final String lastMsg = chat['lastMessage'] ?? 'No messages yet';
    final DateTime? lastTime = chat['lastMessageTime'] != null ? DateTime.parse(chat['lastMessageTime']) : null;
    final String timeStr = lastTime != null ? '${lastTime.hour}:${lastTime.minute.toString().padLeft(2, '0')}' : '';

    return InkWell(
      onTap: () => context.push('/vendor-chat/${chat['id']}?phone=${chat['clientPhone'] ?? ''}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _buildAvatar(chat, isDark),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['clientName'],
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isUnread ? AppColors.primary01 : (isDark ? Colors.white38 : Colors.black38),
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
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? (isUnread ? Colors.white : Colors.white60) : (isUnread ? Colors.black : Colors.black54),
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

  Widget _buildAvatar(dynamic chat, bool isDark) {
    return Hero(
      tag: 'avatar_${chat['id']}',
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: NetworkImage(chat['clientImageUrl']), fit: BoxFit.cover),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
