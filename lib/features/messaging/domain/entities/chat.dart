import 'package:eventbridge/features/messaging/domain/entities/chat_status.dart';

/// Represents a chat conversation document in Firestore.
/// chatId format: "{customerId}_{vendorId}" (deterministic — prevents duplicates)
class Chat {
  final String id;
  final String customerId;
  final String vendorId;

  // Denormalized display data (avoids extra reads on chat list)
  final String customerName;
  final String customerPhotoUrl;
  final String customerPhone;
  final String vendorName;
  final String vendorPhotoUrl;
  final String vendorPhone;

  // Postgres link
  final String? leadId;

  // Access control gate
  final ChatStatus status;

  // Chat list summary
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final String lastMessageType; // 'text' | 'image' | 'system'

  // Unread counters
  final int unreadByCustomer;
  final int unreadByVendor;

  // Typing map: {userId: DateTime?} — included in chat doc stream (no extra listener)
  final Map<String, DateTime?> typing;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Chat({
    required this.id,
    required this.customerId,
    required this.vendorId,
    this.customerName = '',
    this.customerPhotoUrl = '',
    this.customerPhone = '',
    this.vendorName = '',
    this.vendorPhotoUrl = '',
    this.vendorPhone = '',
    this.leadId,
    this.status = ChatStatus.pending,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastMessageType = 'text',
    this.unreadByCustomer = 0,
    this.unreadByVendor = 0,
    this.typing = const {},
    this.createdAt,
    this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? customerId,
    String? vendorId,
    String? customerName,
    String? customerPhotoUrl,
    String? customerPhone,
    String? vendorName,
    String? vendorPhotoUrl,
    String? vendorPhone,
    String? leadId,
    ChatStatus? status,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageType,
    int? unreadByCustomer,
    int? unreadByVendor,
    Map<String, DateTime?>? typing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      customerName: customerName ?? this.customerName,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      customerPhone: customerPhone ?? this.customerPhone,
      vendorName: vendorName ?? this.vendorName,
      vendorPhotoUrl: vendorPhotoUrl ?? this.vendorPhotoUrl,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      leadId: leadId ?? this.leadId,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadByCustomer: unreadByCustomer ?? this.unreadByCustomer,
      unreadByVendor: unreadByVendor ?? this.unreadByVendor,
      typing: typing ?? this.typing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the other party's name based on the current user's role
  String displayName({required bool isVendor}) =>
      isVendor ? customerName : vendorName;

  String displayPhoto({required bool isVendor}) =>
      isVendor ? customerPhotoUrl : vendorPhotoUrl;

  String displayPhone({required bool isVendor}) =>
      isVendor ? customerPhone : vendorPhone;

  /// Unread count for the current user's role
  int unreadCount({required bool isVendor}) =>
      isVendor ? unreadByVendor : unreadByCustomer;

  /// Whether someone else is currently typing
  bool isOtherTyping({required String myId}) {
    final now = DateTime.now();
    return typing.entries
        .where((e) => e.key != myId && e.value != null)
        .any((e) => now.difference(e.value!).inSeconds < 5);
  }
}
