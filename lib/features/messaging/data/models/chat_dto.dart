import 'package:eventbridge/features/messaging/domain/entities/chat_status.dart';

class ChatDto {
  final String id;
  final String clientId;
  final String vendorId;
  final String customerName;
  final String customerPhotoUrl;
  final String? customerPhone;
  final String vendorName;
  final String vendorPhotoUrl;
  final String? vendorPhone;
  final String? leadId;
  final ChatStatus status;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final String lastMessageType;
  final int unreadByClient;
  final int unreadByVendor;
  final Map<String, DateTime?> typing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatDto({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.customerName = '',
    this.customerPhotoUrl = '',
    this.customerPhone,
    this.vendorName = '',
    this.vendorPhotoUrl = '',
    this.vendorPhone,
    this.leadId,
    this.status = ChatStatus.pending,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastMessageType = 'text',
    this.unreadByClient = 0,
    this.unreadByVendor = 0,
    this.typing = const {},
    this.createdAt,
    this.updatedAt,
  });
}
