import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatListTile extends StatelessWidget {
  final Chat chat;

  const ChatListTile({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storage = StorageService();
    final role = (storage.getString('user_role') ?? '').toUpperCase();
    final isVendor = role == 'VENDOR';

    final name = chat.displayName(isVendor: isVendor);
    final photoUrl = chat.displayPhoto(isVendor: isVendor);
    final unread = chat.unreadCount(isVendor: isVendor);
    final lastMsg =
        chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet';
    final timeStr = _formatTime(chat.lastMessageAt);
    final hasUnread = unread > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? (hasUnread
                ? AppColors.darkNeutral02.withValues(alpha: 0.9)
                : AppColors.darkNeutral02.withValues(alpha: 0.6))
            : (hasUnread ? Colors.white : Colors.white.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(16),
        border: hasUnread
            ? Border.all(
                color: AppColors.primary01.withValues(alpha: isDark ? 0.2 : 0.1),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: hasUnread ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isVendor) {
                context.push(
                  '/vendor-chat/${chat.id}?otherUserName=${Uri.encodeComponent(name)}&otherUserPhotoUrl=${Uri.encodeComponent(photoUrl)}',
                );
              } else {
                context.push(
                  '/customer-chat/${chat.id}?otherUserName=${Uri.encodeComponent(name)}&otherUserPhotoUrl=${Uri.encodeComponent(photoUrl)}',
                );
              }
            },
            splashColor: AppColors.primary01.withValues(alpha: 0.06),
            highlightColor: AppColors.primary01.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  _Avatar(
                    name: name,
                    photoUrl: photoUrl,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight:
                                      hasUnread ? FontWeight.w800 : FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w500,
                                color: hasUnread
                                    ? AppColors.primary01
                                    : (isDark ? Colors.white30 : Colors.black26),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: hasUnread
                                      ? (isDark
                                          ? Colors.white70
                                          : Colors.black54)
                                      : (isDark
                                          ? Colors.white30
                                          : Colors.black38),
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary01,
                                      AppColors.primary02,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);

    if (date == today) {
      return DateFormat('HH:mm').format(value);
    }
    if (today.difference(date).inDays == 1) {
      return 'Yesterday';
    }
    if (today.difference(date).inDays < 7) {
      return DateFormat('EEE').format(value); // Mon, Tue, etc.
    }
    return DateFormat('dd/MM/yy').format(value);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool isDark;

  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl.isEmpty
            ? LinearGradient(
                colors: [
                  AppColors.primary01.withValues(alpha: 0.15),
                  AppColors.primary02.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary01.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: AppColors.primary01,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}
