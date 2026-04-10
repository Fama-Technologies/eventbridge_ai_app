class MessageDto {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final String? imageUrl;
  final Map<String, dynamic>? systemData;
  final DateTime sentAt;
  final DateTime? serverAt;
  final List<String> deliveredTo;
  final List<String> readBy;

  const MessageDto({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.imageUrl,
    this.systemData,
    required this.sentAt,
    this.serverAt,
    this.deliveredTo = const [],
    this.readBy = const [],
  });
}
