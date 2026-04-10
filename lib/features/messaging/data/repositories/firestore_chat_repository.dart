import 'package:eventbridge/features/messaging/data/datasources/firestore_chat_source.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/domain/entities/message_type.dart';
import 'package:eventbridge/features/messaging/domain/repositories/chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  final FirestoreChatSource _firestoreChatSource;

  FirestoreChatRepository(this._firestoreChatSource);

  @override
  Stream<List<Chat>> getChats(String userId) {
    return _firestoreChatSource.watchChats(userId);
  }

  @override
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestoreChatSource.watchMessages(chatId);
  }

  @override
  Stream<Chat> getChatDetails(String chatId) {
    return _firestoreChatSource
        .watchChat(chatId)
        .map((chat) => chat ?? Chat(id: chatId, customerId: '', vendorId: ''));
  }

  @override
  Future<void> sendMessage(String chatId, Message message) async {
    await _firestoreChatSource.sendMessage(
      chatId: chatId,
      senderId: message.senderId,
      text: message.text,
      type: _toSourceMessageType(message.type),
      imageUrl: message.imageUrl,
      systemData: message.systemData,
    );
  }

  @override
  Future<void> markAsRead(String chatId, String userId) {
    final isVendor = !chatId.startsWith('${userId}_');
    return _firestoreChatSource.markAsRead(
      chatId: chatId,
      userId: userId,
      isVendor: isVendor,
    );
  }

  @override
  Future<void> setTyping(String chatId, String userId, bool isTyping) {
    return _firestoreChatSource.setTyping(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  String _toSourceMessageType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image';
      case MessageType.system:
        return 'system';
      case MessageType.text:
        return 'text';
    }
  }
}
