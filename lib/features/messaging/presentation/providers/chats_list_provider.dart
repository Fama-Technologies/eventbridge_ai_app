import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatsListProvider = StreamProvider<List<Chat>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final userId = StorageService().getString('user_id');
  if (userId != null && userId.isNotEmpty) {
    return chatRepository.getChats(userId);
  }
  return Stream.value([]);
});
