import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_providers.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final totalUnreadCountProvider = Provider<int>((ref) {
  final storage = StorageService();
  final userId = storage.getString('user_id') ?? FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    debugPrint('🔴 [totalUnreadCountProvider] No userId found!');
    return 0;
  }
  
  final role = storage.getString('user_role') ?? 'CUSTOMER';
  final isVendor = role.toUpperCase() == 'VENDOR';
  
  final chatsAsync = ref.watch(chatsProvider(userId));
  
  return chatsAsync.when(
    data: (chats) {
      final total = chats.fold<int>(0, (sum, chat) {
        return sum + chat.unreadCount(isVendor: isVendor);
      });
      debugPrint('🟢 [totalUnreadCountProvider] User: $userId ($role), Chats: \${chats.length}, Total Unread: \$total');
      return total;
    },
    loading: () {
      debugPrint('🟡 [totalUnreadCountProvider] Loading chats...');
      return 0;
    },
    error: (err, stack) {
      debugPrint('🔴 [totalUnreadCountProvider] Error: \$err');
      return 0;
    },
  );
});
