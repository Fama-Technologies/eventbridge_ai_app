import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatMessages(chatId);
});
