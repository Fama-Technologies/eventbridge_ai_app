import 'dart:async';
import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';

abstract class ChatRepository {
  Stream<List<Chat>> getChats(String userId);
  Stream<List<Message>> getChatMessages(String chatId);
  Stream<Chat> getChatDetails(String chatId);
  Future<void> sendMessage(String chatId, Message message);
  Future<void> markAsRead(String chatId, String userId);
  Future<void> setTyping(String chatId, String userId, bool isTyping);
}
