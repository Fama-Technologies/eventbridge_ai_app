import 'package:eventbridge/features/messaging/domain/entities/presence.dart';
import 'package:eventbridge/features/messaging/presentation/providers/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final presenceProvider = StreamProvider.family<Presence, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('presence').doc(userId).snapshots().map((doc) {
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final lastSeenRaw = data['lastSeen'];
      DateTime? lastSeen;
      if (lastSeenRaw is DateTime) {
        lastSeen = lastSeenRaw;
      } else if (lastSeenRaw != null &&
          (lastSeenRaw as dynamic).toDate != null) {
        lastSeen = (lastSeenRaw as dynamic).toDate() as DateTime;
      }
      return Presence(
        userId: data['userId']?.toString() ?? userId,
        online: data['online'] == true,
        lastSeen: lastSeen,
      );
    } else {
      return Presence(userId: userId, online: false, lastSeen: DateTime.now());
    }
  });
});
