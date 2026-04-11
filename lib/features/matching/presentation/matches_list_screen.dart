import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/presentation/providers/match_provider.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chats_list_provider.dart';
import 'package:eventbridge/features/messaging/presentation/widgets/chat_list_tile.dart';
import 'package:intl/intl.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(recentMatchesProvider);
    final chatsAsync = ref.watch(chatsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: Text(
          'Matches & Messages',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.primary01,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary01,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary01,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Inquiries'),
            Tab(text: 'Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // inquiries Tab
          matchesAsync.when(
            data: (matches) => matches.isEmpty
                ? _buildEmptyState(isDark, 'No active inquiries', 'Start matching with vendors to see them here.')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _MatchInquiryTile(match: match, isDark: isDark);
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text('Failed to load inquiries')),
          ),
          
          // Chats Tab
          chatsAsync.when(
            data: (chats) => chats.isEmpty
                ? _buildEmptyState(isDark, 'No messages yet', 'Your conversations will appear here.')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) => ChatListTile(chat: chats[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text('Failed to load chats')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.ghost, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.primary01,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchInquiryTile extends StatelessWidget {
  final dynamic match; // Using dynamic for now to handle VendorMatch
  final bool isDark;

  const _MatchInquiryTile({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    bool isPending = match.status.toLowerCase() == 'pending';
    bool isAccepted = match.status.toLowerCase() == 'accepted';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: match.imageUrl != null
                  ? Image.network(match.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[200], child: Icon(PhosphorIconsRegular.storefront)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.vendorName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary01,
                  ),
                ),
                Text(
                  '${match.eventType} • ${DateFormat('MMM dd').format(match.eventDate)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAccepted 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : AppColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    match.status.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAccepted ? Colors.green : AppColors.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isAccepted)
            IconButton(
              onPressed: () {
                 // Navigate to chat
                 context.push('/customer-chat/${match.id}?otherUserId=${match.vendorId}&otherUserName=${Uri.encodeComponent(match.vendorName)}');
              },
              icon: Icon(PhosphorIconsRegular.chatCircleDots, color: AppColors.primary01),
            )
          else
            Icon(PhosphorIconsRegular.clock, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
