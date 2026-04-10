import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatDetailProvider = StreamProvider.family<Chat, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatDetails(chatId);
});
