import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';
import 'package:eventbridge/features/home/presentation/providers/match_provider.dart';
import 'package:intl/intl.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(recentMatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FC),
      body: Column(
        children: [
          AppHeader(
            title: 'AI Matches',
            username: 'User', // Placeholder or get from state if available
            onAvatarTap: () => context.push('/customer-profile'),
          ),
          Expanded(
            child: matchesAsync.when(
              data: (matches) => matches.isEmpty
                  ? _buildEmptyState(
                      isDark,
                      'No matches yet',
                      'Your matches will appear here once you start connecting.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return _MatchInquiryTile(match: match, isDark: isDark);
                      },
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary01),
              ),
              error: (err, stack) => const Center(
                child: Text('Failed to load matches'),
              ),
            ),
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
  final dynamic match;
  final bool isDark;

  const _MatchInquiryTile({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = (match.status ?? 'pending').toLowerCase();
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'accepted':
        statusColor = const Color(0xFF3B82F6);
        statusText = 'ACCEPTED';
        break;
      case 'success':
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusText = 'COMPLETED';
        break;
      case 'updated':
        statusColor = const Color(0xFF8B5CF6);
        statusText = 'UPDATED';
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusText = status.toUpperCase();
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Image
                Hero(
                  tag: 'vendor_${match.vendorId}_${match.id}',
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: match.imageUrl != null && match.imageUrl!.isNotEmpty
                          ? Image.network(
                              match.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              match.vendorName,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1A24),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(color: statusColor, text: statusText),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.eventType ?? 'Event Inquiry',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(match.eventDate),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'View Profile',
                    icon: Icons.person_outline_rounded,
                    isOutline: true,
                    onPressed: () => context.push('/vendor-public/${match.vendorId}'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline_rounded,
                    isOutline: false,
                    onPressed: () {
                      context.push(
                        '/customer-chat/${match.id}?otherUserId=${match.vendorId}&otherUserName=${Uri.encodeComponent(match.vendorName)}',
                      );
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.storefront_rounded, color: Color(0xFF94A3B8), size: 30),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String text;

  const _StatusBadge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isOutline;
  final VoidCallback onPressed;
  final bool isDark;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isOutline,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutline ? Colors.transparent : AppColors.primary01,
        foregroundColor: isOutline
            ? (isDark ? Colors.white : const Color(0xFF1A1A24))
            : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isOutline
              ? BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0))
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
