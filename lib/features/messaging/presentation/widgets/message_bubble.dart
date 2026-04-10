import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/domain/entities/message_type.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // We only center system messages. Regular ones are aligned left/right.
    if (message.type == MessageType.system) {
      return _SystemContent(message: message, isDark: isDark);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
          minWidth: 0,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          decoration: BoxDecoration(
            gradient: isMe 
              ? LinearGradient(
                  colors: [
                    AppColors.primary01,
                    AppColors.primary02,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
            color: isMe 
                ? null 
                : (isDark ? AppColors.darkNeutral02 : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return switch (message.type) {
      MessageType.image => _ImageContent(message: message, isMe: isMe, isDark: isDark),
      _ => _TextContent(message: message, isMe: isMe, isDark: isDark),
    };
  }
}

// ─── Text bubble ──────────────────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isDark;
  const _TextContent({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: GoogleFonts.outfit(
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          _TimeRow(message: message, isMe: isMe, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Image bubble ─────────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isDark;
  const _ImageContent({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final url = message.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (url != null && url.isNotEmpty)
            Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: isDark ? Colors.white10 : Colors.black12,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            )
          else
            Container(
              height: 160,
              color: isDark ? Colors.white10 : Colors.black12,
              child: const Center(
                child: Icon(Icons.image, color: Colors.white54, size: 40),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _TimeRow(message: message, isMe: isMe, isDark: isDark, onImage: true),
          ),
        ],
      ),
    );
  }
}

// ─── System bubble ────────────────────────────────────────────────────────

class _SystemContent extends StatelessWidget {
  final Message message;
  final bool isDark;
  const _SystemContent({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white38 : Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Time + tick row ──────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isDark;
  final bool onImage;

  const _TimeRow({
    required this.message,
    required this.isMe,
    required this.isDark,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.serverAt ?? message.sentAt);
    final textColor = onImage 
        ? Colors.white.withValues(alpha: 0.8) 
        : (isMe ? Colors.white.withValues(alpha: 0.7) : (isDark ? Colors.white38 : Colors.black26));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr, 
          style: GoogleFonts.outfit(
            color: textColor, 
            fontSize: 11,
            fontWeight: FontWeight.w500,
          )
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _Tick(
            readBy: message.readBy, 
            deliveredTo: message.deliveredTo, 
            onImage: onImage,
            isMe: isMe,
          ),
        ],
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  final List<String> readBy;
  final List<String> deliveredTo;
  final bool onImage;
  final bool isMe;

  const _Tick({
    required this.readBy, 
    required this.deliveredTo, 
    this.onImage = false,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = readBy.isNotEmpty;
    final isDelivered = deliveredTo.isNotEmpty;
    
    Color color;
    if (isRead) {
      color = AppColors.waTickBlue; // Blue ticks for read
    } else {
      color = onImage 
          ? Colors.white.withValues(alpha: 0.8) 
          : (isMe ? Colors.white.withValues(alpha: 0.6) : Colors.black26);
    }

    return Icon(
      isRead || isDelivered ? Icons.done_all : Icons.done,
      size: 14,
      color: color,
    );
  }
}
