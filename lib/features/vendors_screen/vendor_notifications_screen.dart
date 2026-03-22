import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:intl/intl.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() => _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getNotifications(userId);
      if (mounted && result['success'] == true) {
        setState(() {
          _notifications = result['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = StorageService().getString('user_id');
    if (userId == null) return;

    final success = await ApiService.instance.markAllNotificationsAsRead(userId);
    if (success && mounted) {
      _fetchNotifications();
    }
  }

  Future<void> _markAsRead(String id) async {
    final success = await ApiService.instance.markNotificationAsRead(id);
    if (success && mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'].toString() == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'TBD';
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all as read',
                style: GoogleFonts.outfit(
                  color: AppColors.primary01,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.primary01,
              child: _notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(
                          context: context,
                          id: notification['id'].toString(),
                          title: notification['title'] ?? 'Notice',
                          message: notification['message'] ?? '',
                          time: _formatTime(notification['created_at']),
                          type: _getType(notification['type']),
                          isNew: notification['is_read'] == false,
                          isDark: isDark,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  NotificationType _getType(String? type) {
    switch (type) {
      case 'lead': return NotificationType.lead;
      case 'message': return NotificationType.message;
      default: return NotificationType.system;
    }
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required String id,
    required String title,
    required String message,
    required String time,
    required NotificationType type,
    required bool isNew,
    required bool isDark,
  }) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case NotificationType.lead:
        icon = Icons.bolt_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFF6366F1);
        break;
      case NotificationType.system:
        icon = Icons.info_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
    }

    return GestureDetector(
      onTap: () => _markAsRead(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNew 
              ? AppColors.primary01.withOpacity(0.3) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            width: isNew ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isNew)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary01,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }
}

enum NotificationType { lead, message, system }
