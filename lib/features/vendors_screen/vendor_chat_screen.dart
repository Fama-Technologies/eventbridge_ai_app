import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/network/websocket_service.dart';
import 'package:eventbridge/features/vendors_screen/widgets/full_screen_image_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class VendorChatScreen extends StatefulWidget {
  final String leadId;
  const VendorChatScreen({super.key, required this.leadId});

  @override
  State<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends State<VendorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  Timer? _typingTimer;
  bool _isClientTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startPolling();
    _markAsRead();
    _initWebSocket();
  }

  void _initWebSocket() {
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(Map<String, dynamic> data) {
    if (data['type'] == 'NEW_MESSAGE') {
      final message = data['message'];
      if (message['chat_id'].toString() == widget.leadId) {
        // If it's a message for THIS chat, add it instantly
        if (mounted) {
          setState(() {
            // Check if message already exists to avoid duplicates (from polling)
            final exists = _messages.any((m) => m['id'] == message['id']);
            if (!exists) {
              _messages.add(message);
              _scrollToBottom();
            }
          });
        }
      }
    }
  }

  void _markAsRead() {
    final userId = StorageService().getString('user_id');
    if (userId != null) {
      ApiService.instance.markChatAsRead(chatId: widget.leadId, userId: userId);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(isBackground: true);
      _fetchChatStatus();
    });
  }

  Future<void> _fetchChatStatus() async {
    try {
      // For now, we reuse getVendorChats or a more specific endpoint to get status
      // Let's assume getChatMessages could return chat metadata too
      // or we just poll the specific chat status in a real app.
      // Since I don't have a separate 'getChat' endpoint, I'll fetch chats list filtered for this one.
      final userId = StorageService().getString('user_id');
      if (userId == null) return;
      
      final result = await ApiService.instance.getVendorChats(userId);
      if (mounted && result['success'] == true) {
        final chats = result['chats'] as List;
        final thisChat = chats.firstWhere((c) => c['id'].toString() == widget.leadId, orElse: () => null);
        if (thisChat != null) {
          setState(() {
            _isClientTyping = thisChat['client_is_typing'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching chat status: $e');
    }
  }

  void _onMessageChanged(String value) {
    if (_typingTimer?.isActive ?? false) return;

    final userId = StorageService().getString('user_id');
    if (userId == null) return;

    ApiService.instance.updateTypingStatus(
      chatId: widget.leadId,
      userId: userId,
      isTyping: true,
    );

    _typingTimer = Timer(const Duration(seconds: 2), () {
      ApiService.instance.updateTypingStatus(
        chatId: widget.leadId,
        userId: userId,
        isTyping: false,
      );
    });
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    try {
      final result = await ApiService.instance.getChatMessages(widget.leadId);
      if (mounted && result['success'] == true) {
        final newMessages = result['messages'] ?? [];
        if (newMessages.length != _messages.length) {
          setState(() {
            _messages = newMessages;
            _isLoading = false;
          });
          _scrollToBottom();
        } else if (!isBackground) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = StorageService().getString('user_id');
    if (userId == null) return;

    _messageController.clear();

    try {
      final result = await ApiService.instance.sendChatMessage(
        chatId: widget.leadId,
        senderId: userId,
        text: text,
      );
      if (mounted && result['success'] == true) {
        _fetchMessages(isBackground: true);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading image...', style: GoogleFonts.outfit()),
              backgroundColor: AppColors.primary01,
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // 1. Get presigned URL
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_chat_${widget.leadId}.jpg';
        final presignedResult = await ApiService.instance.getPresignedUrl(
          fileName: fileName,
          contentType: 'image/jpeg',
          folder: 'chats',
        );

        if (presignedResult['success'] == true) {
          final uploadUrl = presignedResult['uploadUrl'];
          final publicUrl = presignedResult['publicUrl'];

          // 2. Upload to S3
          final fileBytes = await image.readAsBytes();
          await Dio().put(
            uploadUrl,
            data: fileBytes,
            options: Options(headers: {'Content-Type': 'image/jpeg'}),
          );

          // 3. Send message with imageUrl
          final userId = StorageService().getString('user_id');
          if (userId != null) {
            await ApiService.instance.sendChatMessage(
              chatId: widget.leadId,
              senderId: userId,
              text: 'Sent an image',
              imageUrl: publicUrl,
            );
            _fetchMessages(isBackground: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    _scrollController.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = MockLeadRepository.getById(widget.leadId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (lead == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_rounded, size: 64, color: AppColors.primary01),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
                Text(
                  'User Not Found',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'This user hasn\'t joined EventBridge yet. Would you like to send them an invite to install the app?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, color: isDark ? Colors.white60 : Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _showInviteConfirmation(context),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary01,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.primary01.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Center(
                      child: Text(
                        'Send Invite Reminder',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Cancel', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context, lead, isDark),
              _buildLeadBanner(context, lead, isDark),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        _buildChatArea(lead, isDark),
                        if (_isClientTyping)
                          Positioned(
                            bottom: 10,
                            left: 20,
                            child: _buildTypingIndicator(lead, isDark),
                          ),
                      ],
                    )
              ),
              _buildInputArea(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Lead lead, bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Hero(
            tag: 'avatar_${lead.id}',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: NetworkImage(lead.clientImageUrl), fit: BoxFit.cover),
                border: Border.all(color: AppColors.primary01.withValues(alpha: 0.2), width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.clientName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLeadBanner(BuildContext context, Lead lead, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.primary01.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary01.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary01, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Scheduled for ${lead.date}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/lead-details/${lead.id}'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('VIEW', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea(Lead lead, bool isDark) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'No messages yet.\nSay hi to get started!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final userId = StorageService().getString('user_id');
        final isMe = msg['sender_id'].toString() == userId;
        final DateTime createdAt = DateTime.parse(msg['created_at']);
        final timeStr = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

        return _buildMessageBubble(
          msg['text'],
          timeStr,
          isMe,
          lead.clientImageUrl,
          index,
          isDark,
          imageUrl: msg['image_url'],
        );
      },
    );
  }

  Widget _buildMessageBubble(
    String text,
    String time,
    bool isMe,
    String clientAvatar,
    int index,
    bool isDark, {
    String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: NetworkImage(clientAvatar), fit: BoxFit.cover),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
              if (!isMe) const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageView(
                                imageUrl: imageUrl,
                                tag: 'msg_img_${imageUrl}',
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'msg_img_${imageUrl}',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 320),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isMe ? AppColors.primary01.withValues(alpha: 0.3) : Colors.black12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary01 : (isDark ? AppColors.darkNeutral02 : Colors.white),
                        gradient: isMe
                            ? LinearGradient(
                                colors: [AppColors.primary01, AppColors.primary01.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: Radius.circular(isMe ? 24 : 8),
                          bottomRight: Radius.circular(isMe ? 8 : 24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMe ? AppColors.primary01.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: isMe ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                          fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 42, right: isMe ? 6 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isMe) const SizedBox(width: 6),
                if (isMe) Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary01),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: (index * 100))).moveY(begin: 10, end: 0, curve: Curves.easeOut);
  }

  Widget _buildTypingIndicator(Lead lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${lead.clientName} is typing',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          _buildTypingDots(isDark),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.5, end: 0);
  }

  Widget _buildTypingDots(bool isDark) {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white38 : Colors.black38,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(
              delay: Duration(milliseconds: index * 200),
              duration: const Duration(milliseconds: 600),
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.2, 1.2),
            );
      }),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.attach_file_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_emotions_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Stickers & Emojis coming soon!',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isDark ? AppColors.darkNeutral01 : const Color(0xFF1A1A24),
                  elevation: 10,
                  margin: const EdgeInsets.only(bottom: 90, left: 24, right: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.emoji_emotions_outlined, color: isDark ? Colors.white54 : Colors.black54, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              constraints: const BoxConstraints(minHeight: 56, maxHeight: 150),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Scrollbar(
                child: TextField(
                  controller: _messageController,
                  onChanged: _onMessageChanged,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary01,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary01.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Ready to Proceed?', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'We will open your SMS app with a pre-filled message for the client to install the Event Management app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.black38)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchSMS();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary01, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text('PROCEED', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSMS() async {
    final lead = MockLeadRepository.getById(widget.leadId);
    final String phoneNumber = lead?.phoneNumber ?? "";
    final String message = "Hi! I'd like to chat with you about your event on EventBridge. Please install the app to get started: https://eventbridge.app/install";
    final Uri uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch SMS app')));
      }
    }
  }
}
