import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventbridge/features/messaging/data/datasources/firestore_chat_source.dart';
import 'package:eventbridge/features/messaging/data/repositories/firestore_chat_repository.dart';
import 'package:eventbridge/features/messaging/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final firestoreChatSourceProvider = Provider(
  (ref) => FirestoreChatSource(db: ref.watch(firestoreProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => FirestoreChatRepository(ref.watch(firestoreChatSourceProvider)),
);
