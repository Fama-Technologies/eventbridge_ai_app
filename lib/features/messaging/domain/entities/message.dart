import 'package:eventbridge/features/messaging/domain/entities/message_type.dart';

/// Represents a message document in Firestore:
/// chats/{chatId}/messages/{messageId}
class Message {
  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final String? imageUrl;
  final Map<String, dynamic>? systemData;

  /// Client local time — used for optimistic ordering before server round-trip
  final DateTime sentAt;

  /// Server-side Firestore timestamp — authoritative for ordering
  final DateTime? serverAt;

  /// Users who have received this message
  final List<String> deliveredTo;

  /// Users who have opened the chat after this message arrived
  final List<String> readBy;

  /// Optimistic-only: true while the message is being written to Firestore
  final bool isSending;

  const Message({
    required this.id,
    required this.senderId,
    this.text = '',
    this.type = MessageType.text,
    this.imageUrl,
    this.systemData,
    required this.sentAt,
    this.serverAt,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.isSending = false,
  });

  /// Tick state for outgoing messages
  TickState tickState({required String myId, required String otherId}) {
    if (senderId != myId) return TickState.none;
    if (readBy.contains(otherId)) return TickState.read;
    if (deliveredTo.contains(otherId)) return TickState.delivered;
    return TickState.sent;
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    MessageType? type,
    String? imageUrl,
    Map<String, dynamic>? systemData,
    DateTime? sentAt,
    DateTime? serverAt,
    List<String>? deliveredTo,
    List<String>? readBy,
    bool? isSending,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      systemData: systemData ?? this.systemData,
      sentAt: sentAt ?? this.sentAt,
      serverAt: serverAt ?? this.serverAt,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      readBy: readBy ?? this.readBy,
      isSending: isSending ?? this.isSending,
    );
  }
}

enum TickState { none, sent, delivered, read }
