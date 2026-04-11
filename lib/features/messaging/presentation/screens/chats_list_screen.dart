import 'package:eventbridge/shared/widgets/app_header.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chats_list_provider.dart';
import 'package:eventbridge/features/messaging/presentation/widgets/chat_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatsAsync = ref.watch(chatsListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF8FAFC),
        body: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  chatsAsync.when(
                    data: (chats) {
                      final filtered = _searchQuery.isEmpty
                          ? chats
                          : chats.where((c) {
                              final q = _searchQuery.toLowerCase();
                              return c.customerName.toLowerCase().contains(q) ||
                                  c.vendorName.toLowerCase().contains(q) ||
                                  c.lastMessage.toLowerCase().contains(q);
                            }).toList();

                      if (filtered.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _searchQuery.isNotEmpty
                              ? _buildNoResults(isDark)
                              : _buildEmptyState(isDark),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ChatListTile(chat: filtered[index]),
                            childCount: filtered.length,
                          ),
                        ),
                      );
                    },
                    loading: () => SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: AppColors.primary01,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading conversations...',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.errorsMain.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.wifi_off_rounded,
                                  color: AppColors.errorsMain,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Connection issue',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load your messages.\nPull down to retry.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AppHeader(
      title: 'Messages',
      showSearch: false,
      customSearchWidget: _buildSearchBar(isDark, inHeader: true),
    );
  }

  Widget _buildSearchBar(bool isDark, {bool inHeader = false}) {
    final bgColor = inHeader 
        ? AppColors.white 
        : (isDark ? AppColors.darkNeutral02 : const Color(0xFFF1F3F5));
    final textColor = inHeader ? Colors.black87 : (isDark ? Colors.white : Colors.black87);
    final hintColor = inHeader ? const Color(0xFFBDBDBD) : (isDark ? Colors.white30 : Colors.black26);

    Widget searchField = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: inHeader ? const EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero,
      child: Row(
        children: [
          if (inHeader) ...[
            Icon(
              Icons.search_rounded,
              size: 18,
              color: hintColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: false, // Changed autofocus to false so it doesn't pop up immediately
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: hintColor,
                ),
                prefixIcon: inHeader ? null : Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: hintColor,
                ),
                border: InputBorder.none,
                isDense: inHeader,
                contentPadding: inHeader 
                    ? const EdgeInsets.symmetric(vertical: 12)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );

    if (!inHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: searchField,
      );
    }
    return searchField;
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary01.withValues(alpha: 0.12),
                    AppColors.primary02.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary01,
                size: 38,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No conversations yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your chats with vendors will appear here\nonce you start a conversation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
