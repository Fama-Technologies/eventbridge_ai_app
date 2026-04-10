import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/domain/entities/presence.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export firestoreChatSourceProvider from the canonical location
export 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart'
    show firestoreChatSourceProvider;

// ─── Chat list ─────────────────────────────────────────────────────────────

final chatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final source = ref.watch(firestoreChatSourceProvider);
  return source.watchChats(userId);
});

// ─── Single chat ───────────────────────────────────────────────────────────

final chatProvider = StreamProvider.family<Chat?, String>((ref, chatId) {
  final source = ref.watch(firestoreChatSourceProvider);
  return source.watchChat(chatId);
});

final resolvedChatProvider = StreamProvider.family<Chat?, String>((
  ref,
  chatIdOrLeadId,
) {
  final source = ref.watch(firestoreChatSourceProvider);
  return source.watchResolvedChat(chatIdOrLeadId);
});

// ─── Messages ──────────────────────────────────────────────────────────────

final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final source = ref.watch(firestoreChatSourceProvider);
  return source.watchMessages(chatId);
});

// ─── Presence ──────────────────────────────────────────────────────────────

final presenceProvider = StreamProvider.family<Presence?, String>((
  ref,
  userId,
) {
  final source = ref.watch(firestoreChatSourceProvider);
  return source.watchPresence(userId);
});
