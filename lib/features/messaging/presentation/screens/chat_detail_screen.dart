import 'dart:async';

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/messaging/data/datasources/firestore_chat_source.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat_status.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/domain/entities/presence.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_providers.dart';
import 'package:eventbridge/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:eventbridge/features/messaging/presentation/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatLookupKey;
  final String currentUserId;
  final bool isVendor;
  final String? initialOtherUserId;
  final String? initialOtherUserName;
  final String? initialOtherUserPhotoUrl;

  // Lead context — only relevant on the vendor side
  final String? leadTitle;
  final String? leadDate;
  final String? clientPhone;
  final String? clientId;

  const ChatDetailScreen({
    super.key,
    required this.chatLookupKey,
    required this.currentUserId,
    required this.isVendor,
    this.initialOtherUserId,
    this.initialOtherUserName,
    this.initialOtherUserPhotoUrl,
    this.leadTitle,
    this.leadDate,
    this.clientPhone,
    this.clientId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingDebounce;
  Timer? _stopTypingTimer;
  bool _sending = false;
  bool _hasUnreadBelow = false;
  int _lastMessageCount = 0;

  /// Tracks the resolved chatId after bootstrap (for vendor-initiated chats).
  String? _bootstrappedChatId;

  FirestoreChatSource get _source => ref.read(firestoreChatSourceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _stopTypingTimer?.cancel();
    _controller.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleScroll() {
    if (_isNearBottom() && _hasUnreadBelow && mounted) {
      setState(() => _hasUnreadBelow = false);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final distance =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    return distance < 100;
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
    if (mounted) {
      setState(() => _hasUnreadBelow = false);
    }
  }

  Future<void> _markRead(String chatId) async {
    await _source.markAsRead(
      chatId: chatId,
      userId: widget.currentUserId,
      isVendor: widget.isVendor,
    );
  }

  Future<void> _clearTyping(String chatId) {
    return _source.setTyping(
      chatId: chatId,
      userId: widget.currentUserId,
      isTyping: false,
    );
  }

  void _onTextChanged(String? chatId, String value) {
    if (chatId == null) return;
    final isTyping = value.trim().isNotEmpty;
    _typingDebounce?.cancel();
    _stopTypingTimer?.cancel();

    if (isTyping) {
      _typingDebounce = Timer(const Duration(milliseconds: 300), () {
        _source.setTyping(
          chatId: chatId,
          userId: widget.currentUserId,
          isTyping: true,
        );
      });

      _stopTypingTimer = Timer(const Duration(seconds: 2), () {
        _clearTyping(chatId);
      });
    } else {
      _clearTyping(chatId);
    }
  }

  /// Resolves the effective chatId: either the live one from Firestore,
  /// or one we bootstrapped earlier this session.
  String? _effectiveChatId(String? fromProvider) {
    return fromProvider ?? _bootstrappedChatId;
  }

  Future<void> _sendMessage(String? chatId) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _typingDebounce?.cancel();
    _stopTypingTimer?.cancel();

    if (chatId != null) {
      _clearTyping(chatId);
    }

    try {
      String? actualChatId = chatId;

      // Bootstrap the chat if it doesn't exist yet
      if (actualChatId == null) {
        final storage = StorageService();

        if (widget.isVendor) {
          var custId = widget.clientId?.isNotEmpty == true
              ? widget.clientId!
              : widget.chatLookupKey.contains('_')
              ? widget.chatLookupKey.split('_').first
              : '';

          debugPrint('[Chat] custId after initial resolution: "$custId" '
              '(widget.clientId="${widget.clientId}", '
              'lookupKey="${widget.chatLookupKey}")');

          // Fallback 1: check local lead state
          if (custId.isEmpty) {
            final leads = ref.read(sharedLeadStateProvider);
            final lead = leads.firstWhere(
              (l) => l.id == widget.chatLookupKey,
              orElse: () => Lead.empty(),
            );
            if (lead.clientId != null && lead.clientId!.isNotEmpty) {
              custId = lead.clientId!;
              debugPrint('[Chat] Resolved custId from local lead state: $custId');
            }
          }

          // Fallback 2: query Firestore for an existing chat with this leadId
          if (custId.isEmpty) {
            try {
              final existingChat = await _source.getChatByLeadId(
                widget.chatLookupKey,
              );
              if (existingChat != null &&
                  existingChat.clientId.isNotEmpty) {
                custId = existingChat.clientId;
                debugPrint(
                  '[Chat] Resolved custId from Firestore chat by leadId: $custId',
                );
              }
            } catch (e) {
              debugPrint('[Chat] getChatByLeadId error: $e');
            }
          }

          if (custId.isNotEmpty) {
            // Normal path — we have the customer ID
            final chat = await _source.createOrGetChat(
              clientId: custId,
              vendorId: widget.currentUserId,
              customerName: widget.initialOtherUserName ?? 'Customer',
              customerPhotoUrl: widget.initialOtherUserPhotoUrl ?? '',
              customerPhone: widget.clientPhone ?? '',
              vendorName: storage.getString('user_name') ?? 'Vendor',
              vendorPhotoUrl: storage.getString('user_image') ?? '',
              vendorPhone: storage.getString('user_phone') ?? '',
              leadId: widget.chatLookupKey.contains('_')
                  ? null
                  : widget.chatLookupKey,
            );
            actualChatId = chat?.id;
          } else {
            // Fallback 3: backend doesn't return clientId.
            // Create a lead-keyed chat (lead_{leadId}) so messaging still works.
            // watchResolvedChat finds this via leadId+vendorId query.
            debugPrint(
              '[Chat] No clientId available — creating lead-keyed chat '
              'for leadId="${widget.chatLookupKey}"',
            );
            final chat = await _source.createOrGetChatByLeadId(
              leadId: widget.chatLookupKey,
              vendorId: widget.currentUserId,
              customerName: widget.initialOtherUserName ?? 'Customer',
              customerPhotoUrl: widget.initialOtherUserPhotoUrl ?? '',
              customerPhone: widget.clientPhone ?? '',
              vendorName: storage.getString('user_name') ?? 'Vendor',
              vendorPhotoUrl: storage.getString('user_image') ?? '',
              vendorPhone: storage.getString('user_phone') ?? '',
            );
            actualChatId = chat?.id;
          }
        } else {
          final vendId = widget.chatLookupKey.contains('_')
              ? widget.chatLookupKey.split('_').last
              : '';

          if (vendId.isEmpty) {
            _showError('Cannot start chat — vendor info missing.');
            return;
          }

          final chat = await _source.createOrGetChat(
            clientId: widget.currentUserId,
            vendorId: vendId,
            customerName: storage.getString('user_name') ?? 'Customer',
            customerPhotoUrl: storage.getString('user_image') ?? '',
            customerPhone: storage.getString('user_phone') ?? '',
            vendorName: widget.initialOtherUserName ?? 'Vendor',
            vendorPhotoUrl: widget.initialOtherUserPhotoUrl ?? '',
            vendorPhone: '',
          ).timeout(const Duration(seconds: 10));
          actualChatId = chat?.id;
        }

        if (actualChatId != null && mounted) {
          setState(() => _bootstrappedChatId = actualChatId);
        }
      }

      if (actualChatId == null) {
        _showError('Could not resolve chat session. Check your internet.');
        return;
      }

      await _source.sendMessage(
        chatId: actualChatId,
        senderId: widget.currentUserId,
        text: text,
      );

      // Only clear the input AFTER a successful send
      _controller.clear();
      _jumpToBottom();
      
      // Mark as read (swallow errors here so send doesn't look like it failed)
      try {
        _markRead(actualChatId);
      } catch (_) {}
      
    } catch (e) {
      debugPrint('[Chat] Send failed: $e');
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('permission-denied') || errorMsg.contains('permission denied')) {
        _showError('Message blocked: Permission denied. Refreshing session...');
        // Try to FORCE a token refresh for the next attempt
        AuthRepository().restoreFirebaseMessagingAuthIfNeeded().catchError((_) => null);
      } else if (errorMsg.contains('auth')) {
        _showError('Authentication failed. Please log in again.');
      } else if (errorMsg.contains('timeout')) {
        _showError('Request timed out. Please check your connection.');
      } else {
        _showError('Message failed to send. Check your connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: AppColors.errorsMain,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  String _statusLabel({required bool isTyping, required Presence? presence}) {
    if (isTyping) return 'typing...';
    if (presence?.online == true) return 'online';

    final lastSeen = presence?.lastSeen;
    if (lastSeen == null) return 'offline';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'last seen just now';
    if (diff.inHours < 1) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'last seen ${diff.inHours}h ago';
    return 'last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatAsync = ref.watch(resolvedChatProvider(widget.chatLookupKey));

    return chatAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary01),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkNeutral01
              : AppColors.backgroundLight,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : AppColors.darkNeutral01,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorsMain,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load chat',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (chat) {
        final providerChatId = chat?.id;
        final activeChatId = _effectiveChatId(providerChatId);
        final otherUserId = chat != null
            ? (widget.isVendor ? chat.clientId : chat.vendorId)
            : (widget.initialOtherUserId ?? '');
        final otherUserName = chat != null
            ? chat.displayName(isVendor: widget.isVendor)
            : (widget.initialOtherUserName ?? 'Chat');
        final otherUserPhotoUrl = chat != null
            ? chat.displayPhoto(isVendor: widget.isVendor)
            : (widget.initialOtherUserPhotoUrl ?? '');
        final otherUserPhone =
            chat?.displayPhone(isVendor: widget.isVendor) ?? '';

        // For vendor side, prefer phone from Firestore chat, fallback to route param
        final effectivePhone = (widget.isVendor)
            ? (otherUserPhone.isNotEmpty
                  ? otherUserPhone
                  : (widget.clientPhone ?? ''))
            : otherUserPhone;

        final presenceAsync = ref.watch(presenceProvider(otherUserId));
        final presence = presenceAsync.asData?.value;
        final isOtherTyping =
            chat?.isOtherTyping(myId: widget.currentUserId) ?? false;
        final messagesAsync = activeChatId == null
            ? const AsyncValue<List<Message>>.data(<Message>[])
            : ref.watch(messagesProvider(activeChatId));

        // Show lead banner for vendor side when lead context is available
        final showLeadBanner =
            widget.isVendor &&
            (widget.leadTitle != null || chat?.leadId != null);
        final bannerTitle = widget.leadTitle ?? 'Lead Match';
        final bannerDate = widget.leadDate ?? '';
        final bannerPhone = effectivePhone;

        if (activeChatId != null) {
          ref.listen(messagesProvider(activeChatId), (_, next) {
            next.whenData((messages) {
              if (messages.length > _lastMessageCount) {
                if (_isNearBottom()) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _jumpToBottom();
                  });
                } else if (mounted) {
                  setState(() => _hasUnreadBelow = true);
                }
              }
              _lastMessageCount = messages.length;
              _markRead(activeChatId);
            });
          });
        }

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : const Color(0xFFF5F7FA),
          appBar: _buildAppBar(
            name: otherUserName,
            photoUrl: otherUserPhotoUrl,
            phone: effectivePhone,
            subtitle: _statusLabel(isTyping: isOtherTyping, presence: presence),
            canCall: effectivePhone.isNotEmpty,
            isDark: isDark,
          ),
          body: Column(
            children: [
              // ── Lead context banner (vendor side only) ──
              if (showLeadBanner)
                _LeadContextBanner(
                  leadTitle: bannerTitle,
                  leadDate: bannerDate,
                  phone: bannerPhone,
                  isDark: isDark,
                  onCallPhone: bannerPhone.isNotEmpty
                      ? () => _callPhone(bannerPhone)
                      : null,
                ),
              // Status banner for pending chats (informational only)
              if (!widget.isVendor &&
                  chat != null &&
                  chat.status != ChatStatus.accepted)
                _PendingChatBanner(status: chat.status, isDark: isDark),
              Expanded(
                child: Stack(
                  children: [
                    messagesAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary01,
                        ),
                      ),
                      error: (e, __) => Center(
                        child: Text(
                          'Error: $e',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      data: (messages) => _buildMessageList(
                        messages: messages,
                        currentUserId: widget.currentUserId,
                        isVendor: widget.isVendor,
                        isDark: isDark,
                      ),
                    ),
                    if (_hasUnreadBelow)
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: FilledButton.icon(
                          onPressed: _jumpToBottom,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary01,
                          ),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: Text(
                            'New messages',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isOtherTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicator(),
                  ),
                ),
              _buildInputBar(activeChatId: activeChatId, isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar({
    required String name,
    required String photoUrl,
    required String subtitle,
    required String phone,
    required bool canCall,
    required bool isDark,
  }) {
    final bgColor = isDark
        ? AppColors.darkNeutral01
        : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A24);
    final subColor = isDark ? Colors.white54 : const Color(0xFF717171);

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      titleSpacing: 0,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark
                ? AppColors.darkNeutral03
                : AppColors.neutrals02,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary01,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: subColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (canCall)
          IconButton(
            icon: Icon(Icons.call_outlined, color: AppColors.primary01),
            onPressed: () => _callPhone(phone),
          ),
      ],
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF1A1A24),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildMessageList({
    required List<Message> messages,
    required String currentUserId,
    required bool isVendor,
    required bool isDark,
  }) {
    if (messages.isEmpty) {
      return _EmptyChatState(isVendor: isVendor, isDark: isDark);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showDate =
            index == 0 ||
            !_sameDay(
              messages[index - 1].serverAt ?? messages[index - 1].sentAt,
              message.serverAt ?? message.sentAt,
            );

        return Column(
          children: [
            if (showDate)
              _DateDivider(
                date: message.serverAt ?? message.sentAt,
                isDark: isDark,
              ),
            MessageBubble(message: message, isMe: isMe),
          ],
        );
      },
    );
  }

  Widget _buildInputBar({required String? activeChatId, required bool isDark}) {
    final barBg = isDark ? AppColors.darkNeutral01 : Colors.white;
    final fieldBg = isDark ? AppColors.darkNeutral02 : const Color(0xFFF4F6F8);
    final hintColor = isDark ? Colors.white30 : const Color(0xFF9CA3AF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A24);

    // Always enabled — send handler deals with bootstrap
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: true,
                        onChanged: (value) =>
                            _onTextChanged(activeChatId, value),
                        onSubmitted: (_) => _sendMessage(activeChatId),
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.outfit(
                            color: hintColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              enabled: true,
              onTap: () => _sendMessage(activeChatId),
              sending: _sending,
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Lead Context Banner ─────────────────────────────────────────────────────

class _LeadContextBanner extends StatelessWidget {
  final String leadTitle;
  final String leadDate;
  final String phone;
  final bool isDark;
  final VoidCallback? onCallPhone;

  const _LeadContextBanner({
    required this.leadTitle,
    required this.leadDate,
    required this.phone,
    required this.isDark,
    this.onCallPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary01.withValues(alpha: 0.12)
            : AppColors.primary01.withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary01.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: AppColors.primary01,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leadTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A24),
                  ),
                ),
                if (leadDate.isNotEmpty)
                  Text(
                    'Event: $leadDate',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                if (phone.isNotEmpty)
                  Text(
                    'Client: $phone',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary01.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          if (onCallPhone != null)
            GestureDetector(
              onTap: onCallPhone,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary01,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pending Chat Banner ─────────────────────────────────────────────────────

class _PendingChatBanner extends StatelessWidget {
  final ChatStatus status;
  final bool isDark;

  const _PendingChatBanner({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (text, icon) = switch (status) {
      ChatStatus.pending => (
        'Waiting for the vendor to accept. You can still send messages.',
        Icons.schedule_rounded,
      ),
      ChatStatus.declined => (
        'This lead was declined by the vendor.',
        Icons.info_outline_rounded,
      ),
      ChatStatus.accepted => ('', Icons.check),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : const Color(0xFFFFF8F0),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.primary01.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark
                ? Colors.white38
                : AppColors.primary01.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateDivider({required this.date, required this.isDark});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);

    if (current == today) return 'Today';
    if (today.difference(current).inDays == 1) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral02 : AppColors.neutrals02,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _label(),
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Send Button ─────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool sending;
  final bool enabled;

  const _SendButton({
    required this.onTap,
    required this.sending,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending || !enabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primary01, AppColors.primary02],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : AppColors.neutrals03,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary01.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: sending
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Empty Chat State ─────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  final bool isVendor;
  final bool isDark;

  const _EmptyChatState({required this.isVendor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final message = isVendor
        ? 'No messages yet. Introduce yourself to the client!'
        : 'No messages yet. Start the conversation!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary01,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
