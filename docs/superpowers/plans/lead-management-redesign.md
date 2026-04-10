# Lead Management UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign lead cards and bottom sheet details with integrated messaging, fix accept lead flow, and modernize UI/UX using design tokens.

**Architecture:** 
- New `lead_card_components.dart` contains reusable lead card, message bubble, and action components
- Redesigned `lead_details_bottom_sheet_v2.dart` replaces old bottom sheet with integrated messaging, real data binding, and proper accept lead flow
- New `lead_message_provider.dart` manages real-time message state using Riverpod
- Updated `lead_model.dart` extends with message fields and acceptance status
- Fix `accept_lead_service.dart` handles lead acceptance with validation and error handling

**Tech Stack:** Flutter, Dart, Riverpod (state), go_router (navigation), design_tokens (spacing/shadows), Socket.IO (real-time)

---

## File Structure

```
lib/features/vendors_screen/
├── models/
│   └── lead_model.dart                    (MODIFY: add message & status fields)
├── data/
│   └── lead_repository.dart               (MODIFY: add accept lead method)
├── widgets/
│   ├── lead_card_components.dart          (CREATE: reusable components)
│   ├── lead_details_bottom_sheet_v2.dart  (CREATE: new redesigned sheet)
│   ├── lead_message_components.dart       (CREATE: message UI)
│   └── lead_details_bottom_sheet.dart     (KEEP: backup)
├── providers/
│   └── lead_message_provider.dart         (CREATE: real-time message state)
└── services/
    └── accept_lead_service.dart           (CREATE: acceptance logic)
```

---

## Task 1: Update Lead Model with Message & Status Fields

**Files:**
- Modify: `lib/features/vendors_screen/models/lead_model.dart`

**Context:** Lead model needs to support messages, acceptance status, and message list for real-time updates.

- [ ] **Step 1: Read current lead_model.dart to understand structure**

Current structure has: id, title, date, time, location, matchScore, budget, guests, responseTime, clientName, clientMessage, venueName, venueAddress, clientImageUrl, isHighValue, lastActive, isAccepted, phoneNumber

- [ ] **Step 2: Add message and messages list fields**

```dart
// In lib/features/vendors_screen/models/lead_model.dart
// Add to Lead class after existing fields:

class Lead {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final int matchScore;
  final double budget;
  final int guests;
  final String responseTime;
  final String clientName;
  final String clientMessage;
  final String venueName;
  final String venueAddress;
  final String clientImageUrl;
  final bool isHighValue;
  final String lastActive;
  final bool isAccepted;
  final String? phoneNumber;
  
  // NEW FIELDS:
  final String? vendorResponse;  // Vendor's latest response message
  final List<ChatMessage> messages;  // Real-time message thread
  final DateTime? acceptedAt;  // Timestamp when lead was accepted
  final String status;  // 'pending', 'accepted', 'rejected', 'completed'

  Lead({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.matchScore,
    required this.budget,
    required this.guests,
    required this.responseTime,
    required this.clientName,
    required this.clientMessage,
    required this.venueName,
    required this.venueAddress,
    required this.clientImageUrl,
    this.isHighValue = false,
    required this.lastActive,
    this.isAccepted = false,
    this.phoneNumber,
    this.vendorResponse,  // NEW
    this.messages = const [],  // NEW
    this.acceptedAt,  // NEW
    this.status = 'pending',  // NEW
  });
```

- [ ] **Step 3: Add copyWith method for status updates**

```dart
// Add to Lead class:
Lead copyWith({
  String? id,
  String? title,
  String? date,
  String? time,
  String? location,
  int? matchScore,
  double? budget,
  int? guests,
  String? responseTime,
  String? clientName,
  String? clientMessage,
  String? venueName,
  String? venueAddress,
  String? clientImageUrl,
  bool? isHighValue,
  String? lastActive,
  bool? isAccepted,
  String? phoneNumber,
  String? vendorResponse,  // NEW
  List<ChatMessage>? messages,  // NEW
  DateTime? acceptedAt,  // NEW
  String? status,  // NEW
}) {
  return Lead(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    time: time ?? this.time,
    location: location ?? this.location,
    matchScore: matchScore ?? this.matchScore,
    budget: budget ?? this.budget,
    guests: guests ?? this.guests,
    responseTime: responseTime ?? this.responseTime,
    clientName: clientName ?? this.clientName,
    clientMessage: clientMessage ?? this.clientMessage,
    venueName: venueName ?? this.venueName,
    venueAddress: venueAddress ?? this.venueAddress,
    clientImageUrl: clientImageUrl ?? this.clientImageUrl,
    isHighValue: isHighValue ?? this.isHighValue,
    lastActive: lastActive ?? this.lastActive,
    isAccepted: isAccepted ?? this.isAccepted,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    vendorResponse: vendorResponse ?? this.vendorResponse,  // NEW
    messages: messages ?? this.messages,  // NEW
    acceptedAt: acceptedAt ?? this.acceptedAt,  // NEW
    status: status ?? this.status,  // NEW
  );
}
```

- [ ] **Step 4: Create ChatMessage model class (in same file)**

```dart
// Add to lead_model.dart (before Lead class):
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String text;
  final DateTime timestamp;
  final bool isVendor;  // true if sent by vendor, false if client

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.text,
    required this.timestamp,
    required this.isVendor,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderImage: json['senderImage'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isVendor: json['isVendor'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isVendor': isVendor,
    };
  }
}
```

- [ ] **Step 5: Update fromJson to parse new fields**

```dart
// In Lead.fromJson():
return Lead(
  id: json['id']?.toString() ?? '',
  title: json['title'] ?? json['eventType'] ?? 'Lead',
  date: json['date'] ?? 'TBD',
  time: json['time'] ?? 'TBD',
  location: json['location'] ?? 'TBD',
  matchScore: int.tryParse(json['matchScore']?.toString() ?? '0') ?? 0,
  budget: (json['budget'] is num)
      ? (json['budget'] as num).toDouble()
      : double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
  guests: int.tryParse(json['guests']?.toString() ?? '0') ?? 0,
  responseTime: json['responseTime'] ?? '2h',
  clientName: json['clientName'] ?? 'Client',
  clientMessage: json['clientMessage'] ?? '',
  venueName: json['venueName'] ?? '',
  venueAddress: json['venueAddress'] ?? '',
  clientImageUrl: json['clientImageUrl'] ?? '',
  isHighValue: json['isHighValue'] ?? false,
  lastActive: json['lastActive'] ?? 'Active now',
  isAccepted: json['isAccepted'] ?? false,
  phoneNumber: json['phoneNumber']?.toString(),
  vendorResponse: json['vendorResponse']?.toString(),  // NEW
  messages: (json['messages'] as List?)
      ?.map((m) => ChatMessage.fromJson(m))
      .toList() ?? [],  // NEW
  acceptedAt: json['acceptedAt'] != null
      ? DateTime.tryParse(json['acceptedAt'].toString())
      : null,  // NEW
  status: json['status']?.toString() ?? 'pending',  // NEW
);
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/vendors_screen/models/lead_model.dart
git commit -m "feat(lead): add message, status, and acceptance fields to Lead model"
```

---

## Task 2: Create Reusable Lead Card Components

**Files:**
- Create: `lib/features/vendors_screen/widgets/lead_card_components.dart`

**Context:** These components will be used in both lead list and in bottom sheet. They're designed with proper spacing (8pt grid), shadows, and dark mode support.

- [ ] **Step 1: Create file with imports**

```dart
// lib/features/vendors_screen/widgets/lead_card_components.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Component library for lead cards
```

- [ ] **Step 2: Create LeadCard component (main card for grid/list)**

```dart
// Add to lead_card_components.dart:

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final bool isDark;

  const LeadCard({
    required this.lead,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [ShadowTokens.getShadow(8, isDark: isDark)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar + Title + Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RadiusTokens.lg),
                            boxShadow: [ShadowTokens.getShadow(4, isDark: isDark)],
                            image: DecorationImage(
                              image: NetworkImage(lead.clientImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Gaps.hLg,
                        // Title section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lead.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (lead.isHighValue)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEF3C7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFD97706),
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              Gaps.xs,
                              Text(
                                lead.clientName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Gaps.xl,

                    // Metrics row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricBadge(
                          Icons.calendar_today_rounded,
                          lead.date,
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.people_alt_rounded,
                          '${lead.guests} Guests',
                          isDark,
                        ),
                        _buildMetricBadge(
                          Icons.payments_rounded,
                          'UGX ${lead.budget.toInt()}',
                          isDark,
                        ),
                      ],
                    ),
                    Gaps.lg,

                    // Recent message preview (if exists)
                    if (lead.clientMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client Message',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Gaps.sm,
                            Text(
                              lead.clientMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Gaps.lg,

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(lead.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Text(
                        lead.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(lead.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text, bool isDark) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
            Gaps.hXs,
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'completed':
        return const Color(0xFF3B82F6); // Blue
      default:
        return AppColors.primary01; // Orange
    }
  }
}
```

- [ ] **Step 3: Create LeadHeaderCard component (for bottom sheet header)**

```dart
// Add to lead_card_components.dart:

class LeadHeaderCard extends StatelessWidget {
  final Lead lead;
  final bool isDark;

  const LeadHeaderCard({
    required this.lead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium badge
        if (lead.isHighValue)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary01.withOpacity(0.1),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: AppColors.primary01, size: 14),
                Gaps.hXs,
                Text(
                  'PREMIUM LEAD',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary01,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        if (lead.isHighValue) Gaps.md,

        // Lead title
        Text(
          lead.title,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        Gaps.md,

        // Client info row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                image: DecorationImage(
                  image: NetworkImage(lead.clientImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Gaps.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Gaps.xs,
                  Text(
                    'Match Score: ${lead.matchScore}%',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Create LeadStatsGrid component**

```dart
// Add to lead_card_components.dart:

class LeadStatsGrid extends StatelessWidget {
  final Lead lead;
  final bool isDark;

  const LeadStatsGrid({
    required this.lead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Budget',
            'UGX ${lead.budget.toInt()}',
            Icons.payments_rounded,
            isDark,
          ),
        ),
        Gaps.hMd,
        Expanded(
          child: _buildStatCard(
            'Guests',
            '${lead.guests}',
            Icons.people_alt_rounded,
            isDark,
          ),
        ),
        Gaps.hMd,
        Expanded(
          child: _buildStatCard(
            'Response',
            lead.responseTime,
            Icons.timer_rounded,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.lg,
        horizontal: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary01, size: 20),
          Gaps.md,
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Gaps.xs,
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/vendors_screen/widgets/lead_card_components.dart
git commit -m "feat(lead): create reusable lead card components with message preview"
```

---

## Task 3: Create Lead Message Components

**Files:**
- Create: `lib/features/vendors_screen/widgets/lead_message_components.dart`

**Context:** Message bubbles and chat display components for the bottom sheet messaging interface.

- [ ] **Step 1: Create MessageBubble component**

```dart
// lib/features/vendors_screen/widgets/lead_message_components.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const MessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
      child: Row(
        mainAxisAlignment: message.isVendor
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isVendor) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                image: DecorationImage(
                  image: NetworkImage(message.senderImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Gaps.hMd,
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isVendor
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.lg,
                    vertical: SpacingTokens.md,
                  ),
                  decoration: BoxDecoration(
                    color: message.isVendor
                        ? AppColors.primary01
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: message.isVendor
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                      height: 1.4,
                    ),
                  ),
                ),
                Gaps.xs,
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (message.isVendor) Gaps.hMd,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create MessagesList component**

```dart
// Add to lead_message_components.dart:

class MessagesList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isDark;

  const MessagesList({
    required this.messages,
    required this.isDark,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Send the first message!',
          style: GoogleFonts.outfit(
            color: widget.isDark ? Colors.white38 : Colors.black38,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(
          message: widget.messages[index],
          isDark: widget.isDark,
        );
      },
    );
  }
}
```

- [ ] **Step 3: Create MessageInputField component**

```dart
// Add to lead_message_components.dart:

class MessageInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isDark;
  final bool isLoading;

  const MessageInputField({
    required this.onSend,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkNeutral01 : Colors.white,
        border: Border(
          top: BorderSide(
            color: widget.isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.isLoading,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.outfit(
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  borderSide: const BorderSide(
                    color: AppColors.primary01,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.md,
                ),
              ),
              style: GoogleFonts.outfit(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          Gaps.hMd,
          GestureDetector(
            onTap: widget.isLoading
                ? null
                : () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSend(_controller.text.trim());
                      _controller.clear();
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: AppColors.primary01,
                shape: BoxShape.circle,
                boxShadow: [ShadowTokens.getShadow(4)],
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/vendors_screen/widgets/lead_message_components.dart
git commit -m "feat(lead): add message bubble, list, and input components"
```

---

## Task 4: Create Lead Message Provider (Riverpod State Management)

**Files:**
- Create: `lib/features/vendors_screen/providers/lead_message_provider.dart`

**Context:** Manages real-time message state and updates for a specific lead.

- [ ] **Step 1: Create file with basic structure**

```dart
// lib/features/vendors_screen/providers/lead_message_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';

// State notifier for managing messages for a specific lead
class LeadMessageNotifier extends StateNotifier<List<ChatMessage>> {
  LeadMessageNotifier() : super([]);

  Future<void> loadMessages(String leadId) async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      // Fetch messages from API
      final result = await ApiService.instance.getLeadMessages(leadId);
      
      if (result['success'] == true) {
        final messages = (result['messages'] as List?)
            ?.map((m) => ChatMessage.fromJson(m))
            .toList() ?? [];
        
        // Sort by timestamp (oldest first)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state = messages;
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<bool> sendMessage(String leadId, String text) async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return false;

      // Send message via API
      final result = await ApiService.instance.sendCustomerChatMessage(
        chatId: leadId,
        senderId: userId,
        text: text,
      );

      if (result['success'] == true) {
        // Create local message object
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: userId,
          senderName: 'You',
          senderImage: '',
          text: text,
          timestamp: DateTime.now(),
          isVendor: true,
        );

        // Add to state
        state = [...state, newMessage];
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
  }
}

// Provider for a specific lead's messages
final leadMessageProvider =
    StateNotifierProvider.family<LeadMessageNotifier, List<ChatMessage>, String>(
  (ref, leadId) => LeadMessageNotifier(),
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/vendors_screen/providers/lead_message_provider.dart
git commit -m "feat(lead): add lead message provider for real-time message state"
```

---

## Task 5: Create Accept Lead Service

**Files:**
- Create: `lib/features/vendors_screen/services/accept_lead_service.dart`

**Context:** Business logic for accepting leads with validation, error handling, and success callbacks.

- [ ] **Step 1: Create accept lead service**

```dart
// lib/features/vendors_screen/services/accept_lead_service.dart
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'dart:convert';

class AcceptLeadService {
  static final AcceptLeadService _instance = AcceptLeadService._internal();

  factory AcceptLeadService() {
    return _instance;
  }

  AcceptLeadService._internal();

  /// Validates that a lead can be accepted
  Future<({bool isValid, String? errorMessage})> validateLead(Lead lead) async {
    // Check if lead is already accepted
    if (lead.isAccepted || lead.status == 'accepted') {
      return (
        isValid: false,
        errorMessage: 'This lead has already been accepted',
      );
    }

    // Check if lead is rejected
    if (lead.status == 'rejected') {
      return (
        isValid: false,
        errorMessage: 'This lead has been rejected',
      );
    }

    // Check user is authenticated
    final userId = StorageService().getString('user_id');
    if (userId == null) {
      return (
        isValid: false,
        errorMessage: 'You must be logged in',
      );
    }

    return (isValid: true, errorMessage: null);
  }

  /// Accepts a lead and sends initial inquiry message
  Future<({bool success, String? errorMessage})> acceptLead(
    Lead lead, {
    String? customMessage,
  }) async {
    try {
      // Validate first
      final validation = await validateLead(lead);
      if (!validation.isValid) {
        return (success: false, errorMessage: validation.errorMessage);
      }

      final userId = StorageService().getString('user_id') ?? 'unknown';

      // Prepare inquiry message
      final inquiryPayload = {
        'clientName': lead.clientName,
        'title': lead.title,
        'date': lead.date,
        'time': lead.time,
        'guests': lead.guests,
        'location': lead.location,
        'budget': lead.budget,
        'message': lead.clientMessage,
      };

      // Send system message with inquiry
      final messageResult = await ApiService.instance.sendCustomerChatMessage(
        chatId: lead.id,
        senderId: userId,
        text: '__SYSTEM_INQUIRY__${jsonEncode(inquiryPayload)}',
      );

      if (messageResult['success'] != true) {
        return (
          success: false,
          errorMessage: 'Failed to send inquiry message',
        );
      }

      // Update lead status
      final updateResult = await ApiService.instance.updateLeadStatus(
        leadId: lead.id,
        status: 'accepted',
      );

      if (updateResult['success'] != true) {
        return (
          success: false,
          errorMessage: 'Failed to accept lead',
        );
      }

      return (success: true, errorMessage: null);
    } catch (e) {
      return (
        success: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  /// Rejects a lead
  Future<({bool success, String? errorMessage})> rejectLead(
    Lead lead, {
    String? reason,
  }) async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) {
        return (
          success: false,
          errorMessage: 'You must be logged in',
        );
      }

      final result = await ApiService.instance.updateLeadStatus(
        leadId: lead.id,
        status: 'rejected',
      );

      if (result['success'] != true) {
        return (
          success: false,
          errorMessage: 'Failed to reject lead',
        );
      }

      return (success: true, errorMessage: null);
    } catch (e) {
      return (
        success: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/vendors_screen/services/accept_lead_service.dart
git commit -m "feat(lead): add accept lead service with validation and error handling"
```

---

## Task 6: Create Redesigned Lead Details Bottom Sheet V2

**Files:**
- Create: `lib/features/vendors_screen/widgets/lead_details_bottom_sheet_v2.dart`

**Context:** The main bottom sheet with integrated messaging, proper lead details, and improved accept flow. This is a significant component that ties everything together.

- [ ] **Step 1: Create file header and imports**

```dart
// lib/features/vendors_screen/widgets/lead_details_bottom_sheet_v2.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/features/vendors_screen/providers/lead_message_provider.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_card_components.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_message_components.dart';
import 'package:eventbridge/features/vendors_screen/services/accept_lead_service.dart';
import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeadDetailsBottomSheetV2 extends ConsumerStatefulWidget {
  final String leadId;

  const LeadDetailsBottomSheetV2({
    super.key,
    required this.leadId,
  });

  @override
  ConsumerState<LeadDetailsBottomSheetV2> createState() =>
      _LeadDetailsBottomSheetV2State();
}

class _LeadDetailsBottomSheetV2State
    extends ConsumerState<LeadDetailsBottomSheetV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAcceptingLead = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leads = ref.watch(sharedLeadStateProvider);
    
    final lead = leads.firstWhere(
      (l) => l.id == widget.leadId,
      orElse: () => Lead(
        id: widget.leadId,
        title: 'Loading...',
        date: '',
        time: '',
        location: '',
        matchScore: 0,
        budget: 0,
        guests: 0,
        responseTime: '',
        clientName: 'Loading...',
        clientMessage: '',
        venueName: '',
        venueAddress: '',
        clientImageUrl: '',
        lastActive: '',
      ),
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.round),
          ),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white,
              width: 1.5,
            ),
          ),
          boxShadow: [ShadowTokens.xlDark],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.lg),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Tab navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.xxl,
                SpacingTokens.xl,
                SpacingTokens.xxl,
                0,
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Text(
                      'Details',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Messages',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Details tab
                  _buildDetailsTab(lead, isDark),

                  // Messages tab
                  _buildMessagesTab(lead, isDark),
                ],
              ),
            ),

            // Action buttons
            _buildActionButtons(lead, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Lead lead, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeadHeaderCard(lead: lead, isDark: isDark).animate().fadeIn().slideY(begin: 0.1, end: 0),
          Gaps.xxxl,

          LeadStatsGrid(lead: lead, isDark: isDark).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          Gaps.xxxl,

          // Event details
          Text(
            'Event Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Gaps.lg,

          _buildDetailRow(
            Icons.calendar_today_rounded,
            'Date & Time',
            '${lead.date} at ${lead.time}',
            isDark,
          ),
          Gaps.lg,

          _buildDetailRow(
            Icons.location_on_rounded,
            'Venue',
            lead.venueName.isEmpty ? lead.location : lead.venueName,
            isDark,
          ),
          Gaps.lg,

          _buildDetailRow(
            Icons.map_rounded,
            'Address',
            lead.venueAddress.isEmpty ? lead.location : lead.venueAddress,
            isDark,
          ),
          Gaps.xxxl,

          // Client message
          Text(
            'Client Message',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Gaps.lg,

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.primary01.withOpacity(0.05),
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : AppColors.primary01.withOpacity(0.2),
              ),
            ),
            child: Text(
              lead.clientMessage.isEmpty
                  ? 'No additional details provided'
                  : lead.clientMessage,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: AppColors.primary01.withOpacity(0.1),
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
          ),
          child: Icon(icon, color: AppColors.primary01, size: 20),
        ),
        Gaps.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Gaps.sm,
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTab(Lead lead, bool isDark) {
    final messages = ref.watch(leadMessageProvider(lead.id));

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet.\nSend your first message to start a conversation!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                  ),
                )
              : MessagesList(messages: messages, isDark: isDark),
        ),
        MessageInputField(
          isDark: isDark,
          isLoading: _isAcceptingLead,
          onSend: (text) async {
            // Send message
            await ref
                .read(leadMessageProvider(lead.id).notifier)
                .sendMessage(lead.id, text);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(Lead lead, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.xxl,
        SpacingTokens.lg,
        SpacingTokens.xxl,
        MediaQuery.of(context).padding.bottom + SpacingTokens.xxl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Decline button
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                _showRejectConfirmation(lead, isDark);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Decline',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Gaps.hLg,

          // Accept button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isAcceptingLead ? null : () => _handleAcceptLead(lead),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary01,
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  boxShadow: [ShadowTokens.getShadow(8)],
                ),
                child: Center(
                  child: _isAcceptingLead
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on_rounded,
                                color: Colors.white, size: 18),
                            Gaps.hSm,
                            Text(
                              'Accept Lead',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptLead(Lead lead) async {
    setState(() => _isAcceptingLead = true);

    try {
      final result = await AcceptLeadService().acceptLead(lead);

      if (!mounted) return;

      if (result.success) {
        _showSuccessOverlay();

        // Update state
        await ref
            .read(sharedLeadStateProvider.notifier)
            .updateLeadStatus(lead.id, 'accepted');

        // Navigate to chat after delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.pop();
            context.push('/vendor-chat/${lead.id}?phone=${lead.phoneNumber ?? ''}');
          }
        });
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to accept lead');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isAcceptingLead = false);
      }
    }
  }

  void _showRejectConfirmation(Lead lead, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.xxl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral01 : Colors.white,
            borderRadius: BorderRadius.circular(RadiusTokens.xxl),
            boxShadow: [ShadowTokens.xlDark],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              Gaps.xl,

              Text(
                'Decline This Lead?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Gaps.lg,

              Text(
                'You won\'t be able to view or message this client again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Gaps.xxl,

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.lg,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                        ),
                        child: Center(
                          child: Text(
                            'Keep It',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gaps.hLg,
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final result =
                            await AcceptLeadService().rejectLead(lead);

                        if (!mounted) return;

                        if (result.success) {
                          if (mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lead declined'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          _showErrorDialog(
                            result.errorMessage ?? 'Failed to decline lead',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.lg,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Decline',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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

  void _showSuccessOverlay() {
    final entry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.xxxl,
              vertical: SpacingTokens.xxl,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(RadiusTokens.round),
              border: Border.all(color: Colors.white24),
              boxShadow: [ShadowTokens.xlDark],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                Gaps.xl,

                Text(
                  'Lead Accepted!',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Gaps.lg,

                Text(
                  'Opening chat...',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .scale(duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack)
              .fadeIn()
              .then()
              .fadeOut(delay: const Duration(seconds: 1)),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.xxl),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(RadiusTokens.xxl),
            boxShadow: [ShadowTokens.xlDark],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              Gaps.xl,

              Text(
                'Error',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Gaps.lg,

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                ),
              ),
              Gaps.xxl,

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary01,
                    borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  ),
                  child: Center(
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/vendors_screen/widgets/lead_details_bottom_sheet_v2.dart
git commit -m "feat(lead): create redesigned lead details bottom sheet with messaging and accept flow"
```

---

## Task 7: Update Lead List Screens to Use New Components

**Files:**
- Modify: `lib/features/vendors_screen/leads.dart`
- Modify: `lib/features/vendors_screen/home.dart`

**Context:** Replace old lead cards with the new reusable LeadCard component and update bottom sheet reference.

- [ ] **Step 1: Update leads.dart to use LeadCard and new bottom sheet**

```dart
// In lib/features/vendors_screen/leads.dart
// Add import:
import 'package:eventbridge/features/vendors_screen/widgets/lead_card_components.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet_v2.dart';

// Replace _buildPremiumLeadCard method usage with:
LeadCard(
  lead: lead,
  isDark: isDark,
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LeadDetailsBottomSheetV2(leadId: lead.id),
    );
  },
)
```

- [ ] **Step 2: Update home.dart similarly**

```dart
// In lib/features/vendors_screen/home.dart
// Add import:
import 'package:eventbridge/features/vendors_screen/widgets/lead_card_components.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet_v2.dart';

// Replace _buildPremiumLeadCard with:
PremiumLeadCard(...) // or use LeadCard if refactoring
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/vendors_screen/leads.dart lib/features/vendors_screen/home.dart
git commit -m "feat(lead): update lead screens to use new card components and bottom sheet"
```

---

## Task 8: Add API Methods to ApiService (if missing)

**Files:**
- Modify: `lib/core/network/api_service.dart`

**Context:** Ensure API service has required methods for loading messages and updating lead status.

- [ ] **Step 1: Add getLeadMessages method (if not exists)**

```dart
// Add to ApiService class:
Future<Map<String, dynamic>> getLeadMessages(String leadId) async {
  try {
    final response = await _dio.get('/api/leads/$leadId/messages');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

- [ ] **Step 2: Add updateLeadStatus method (if not exists)**

```dart
// Add to ApiService class:
Future<Map<String, dynamic>> updateLeadStatus({
  required String leadId,
  required String status,
}) async {
  try {
    final response = await _dio.post(
      '/api/leads/$leadId/status',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/api_service.dart
git commit -m "feat(api): add getLeadMessages and updateLeadStatus methods"
```

---

## Task 9: Create Documentation

**Files:**
- Create: `LEAD_REDESIGN_GUIDE.md`

**Context:** Document the new lead system, components, and how to use them.

- [ ] **Step 1: Create guide**

```markdown
# Lead Management Redesign Guide

## Overview

The lead management system has been redesigned with:
- Modern, reusable lead card components
- Integrated messaging system with real-time updates
- Improved accept lead flow with validation
- Better visual hierarchy and dark mode support

## New Components

### LeadCard
Main card component for displaying leads in grids/lists.

```dart
LeadCard(
  lead: lead,
  isDark: isDark,
  onTap: () {
    // Handle tap
  },
)
```

Features:
- Client avatar and basic info
- Metrics (date, guests, budget)
- Client message preview
- Status badge (pending, accepted, rejected)

### LeadDetailsBottomSheetV2
Redesigned bottom sheet with tabs for details and messaging.

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => LeadDetailsBottomSheetV2(leadId: leadId),
);
```

Features:
- Tabbed interface (Details, Messages)
- Full lead information display
- Real-time messaging
- Accept/Decline actions with validation

### MessageBubble & MessagesList
Components for displaying individual messages and message threads.

### MessageInputField
Input component for sending messages.

## Usage Example

```dart
// In your lead list screen
LeadCard(
  lead: lead,
  isDark: isDark,
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeadDetailsBottomSheetV2(leadId: lead.id),
    );
  },
)
```

## State Management

Lead messages are managed via Riverpod:

```dart
final leadMessageProvider =
    StateNotifierProvider.family<LeadMessageNotifier, List<ChatMessage>, String>(
  (ref, leadId) => LeadMessageNotifier(),
);
```

Load messages:
```dart
await ref.read(leadMessageProvider(leadId).notifier).loadMessages(leadId);
```

Send message:
```dart
await ref.read(leadMessageProvider(leadId).notifier).sendMessage(leadId, text);
```

## Accepting Leads

Use AcceptLeadService for proper validation and error handling:

```dart
final result = await AcceptLeadService().acceptLead(lead);

if (result.success) {
  // Navigate to chat
} else {
  // Show error: result.errorMessage
}
```

## API Methods Required

Make sure ApiService has these methods:
- `getLeadMessages(leadId)` - Fetch all messages for a lead
- `updateLeadStatus(leadId, status)` - Update lead status
- `sendCustomerChatMessage(chatId, senderId, text)` - Send message

## Design Tokens

All components use the design tokens from the earlier redesign:
- `SpacingTokens` - Consistent 8pt grid spacing
- `RadiusTokens` - Border radius values
- `ShadowTokens` - Semantic shadows
```

- [ ] **Step 2: Commit**

```bash
git add LEAD_REDESIGN_GUIDE.md
git commit -m "docs: add lead redesign guide and component documentation"
```

---

## Summary

**Files Created:**
1. ✅ `lead_model.dart` (modified) - Added message & status fields
2. ✅ `lead_card_components.dart` - Reusable components
3. ✅ `lead_message_components.dart` - Message UI
4. ✅ `lead_message_provider.dart` - Riverpod state
5. ✅ `accept_lead_service.dart` - Business logic
6. ✅ `lead_details_bottom_sheet_v2.dart` - Main redesigned sheet
7. ✅ `leads.dart` (modified) - Updated to use new components
8. ✅ `home.dart` (modified) - Updated to use new components
9. ✅ `api_service.dart` (modified) - Added API methods

**Key Improvements:**
- ✅ Modern, professional design with proper spacing
- ✅ Integrated messaging system with real-time updates
- ✅ Fixed accept lead flow with validation & error handling
- ✅ Better visual hierarchy and dark mode support
- ✅ Touch-friendly UI (44pt+ targets)
- ✅ Real data binding (no demo data)
- ✅ Smooth animations throughout

---

## Execution Options

**Plan complete and saved to `lead-management-redesign.md`.** Two execution options:

**1. Subagent-Driven (recommended)** - Fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach would you prefer?**
