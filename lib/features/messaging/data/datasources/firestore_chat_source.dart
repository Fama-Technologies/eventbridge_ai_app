import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat.dart';
import 'package:eventbridge/features/messaging/domain/entities/chat_status.dart';
import 'package:eventbridge/features/messaging/domain/entities/message.dart';
import 'package:eventbridge/features/messaging/domain/entities/message_type.dart';
import 'package:eventbridge/features/messaging/domain/entities/presence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:eventbridge/core/storage/storage_service.dart';

/// All Firestore reads/writes for the messaging feature.
/// No Riverpod/UI logic here — pure data access.
class FirestoreChatSource {
  final FirebaseFirestore _db;

  FirestoreChatSource({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // ─── Collection refs ───────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  DocumentReference<Map<String, dynamic>> _chatDoc(String chatId) =>
      _chats.doc(chatId);

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chatDoc(chatId).collection('messages');

  DocumentReference<Map<String, dynamic>> _presenceDoc(String userId) =>
      _db.collection('presence').doc(userId);

  Future<void> _ensureMessagingAuthReady() async {
    final storageUserId = StorageService().getString('user_id');
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint(
      '[Chat] Ensuring messaging auth. storage user_id=$storageUserId, '
      'firebase uid=$firebaseUid',
    );
    try {
      await AuthRepository().restoreFirebaseMessagingAuthIfNeeded();
      debugPrint(
        '[Chat] Messaging auth ready check complete. firebase uid='
        '${FirebaseAuth.instance.currentUser?.uid}',
      );
    } catch (e, stack) {
      debugPrint(
        '[Chat] Failed to restore Firebase messaging auth before Firestore access: '
        '$e\n$stack',
      );
      // Rethrow so sendMessage/watchMessages can fail loudly instead of
      // hitting a "Permission Denied" Firestore error that looks like a 
      // network issue.
      rethrow;
    }
  }

  // ─── Chat ID ───────────────────────────────────────────────────────────────

  /// Deterministic chatId prevents duplicate chats: "{clientId}_{vendorId}"
  static String chatId(String clientId, String vendorId) =>
      '${clientId}_$vendorId';

  // ─── Create or get chat ────────────────────────────────────────────────────

  Future<Chat?> createOrGetChat({
    required String clientId,
    required String vendorId,
    required String customerName,
    required String customerPhotoUrl,
    required String customerPhone,
    required String vendorName,
    required String vendorPhotoUrl,
    required String vendorPhone,
    String? leadId,
  }) async {
    await _ensureMessagingAuthReady();
    final id = chatId(clientId, vendorId);
    final ref = _chatDoc(id);
    final existing = await ref.get();

    if (existing.exists) {
      await ref.set({
        'id': id,
        'clientId': clientId,
        'vendorId': vendorId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'customerPhone': customerPhone,
        'vendorName': vendorName,
        'vendorPhotoUrl': vendorPhotoUrl,
        'vendorPhone': vendorPhone,
        if (leadId != null) 'leadId': leadId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        'id': id,
        'clientId': clientId,
        'vendorId': vendorId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'customerPhone': customerPhone,
        'vendorName': vendorName,
        'vendorPhotoUrl': vendorPhotoUrl,
        'vendorPhone': vendorPhone,
        if (leadId != null) 'leadId': leadId,
        'status': 'pending',
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByClient': 0,
        'unreadByVendor': 0,
        'typing': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final snap = await ref.get();
    if (!snap.exists) return null;
    return _chatFromDoc(snap);
  }

  /// Creates (or retrieves) a chat document using [leadId] as the doc key.
  ///
  /// Used when the customer's Firebase UID is not available from the backend.
  /// The chat is keyed as `lead_{leadId}` and has [leadId] stored in the `leadId`
  /// field so [watchResolvedChat] can discover it via the leadId+vendorId query.
  /// [clientId] is left empty and can be patched later once the backend
  /// starts returning it.
  Future<Chat?> createOrGetChatByLeadId({
    required String leadId,
    required String vendorId,
    required String vendorName,
    required String vendorPhotoUrl,
    required String vendorPhone,
    String customerName = 'Customer',
    String customerPhotoUrl = '',
    String customerPhone = '',
  }) async {
    await _ensureMessagingAuthReady();
    final chatId = 'lead_$leadId';
    final ref = _chatDoc(chatId);
    
    // Attempt to resolve clientId from the current session if available
    final storage = StorageService();
    final role = storage.getString('user_role') ?? 'CUSTOMER';
    final currentUserId = storage.getString('user_id') ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // If we are a customer, we ARE the clientId. 
    // If we are a vendor, we still don't know the clientId yet (it remains '' until updated/healed).
    final resolvedClientId = role == 'CUSTOMER' ? currentUserId : '';

    final existing = await ref.get();
    if (!existing.exists) {
      final data = {
        'id': chatId,
        'leadId': leadId,
        'vendorId': vendorId,
        'clientId': resolvedClientId,
        'vendorName': vendorName,
        'vendorPhotoUrl': vendorPhotoUrl,
        'vendorPhone': vendorPhone,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'customerPhone': customerPhone,
        'status': 'pending',
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByClient': 0,
        'unreadByVendor': 0,
        'typing': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data, SetOptions(merge: true));
    } else {
      // Healing: If the doc exists but clientId is empty, and we now know who it is, update it.
      if (resolvedClientId.isNotEmpty && (existing.data()?['clientId']?.isEmpty ?? true)) {
        await ref.update({'clientId': resolvedClientId, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }

    final snap = await ref.get();
    if (!snap.exists) return null;
    return _chatFromDoc(snap);
  }

  // ─── Streams ───────────────────────────────────────────────────────────────

  /// Stream of all chats for a user (as customer or vendor), ordered by last message
  Stream<List<Chat>> watchChats(String userId) async* {
    await _ensureMessagingAuthReady();
    // Two separate queries merged — safer for indexing
    final asClient = _chats
        .where('clientId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_chatFromDoc).toList());

    final asVendor = _chats
        .where('vendorId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_chatFromDoc).toList());

    // Combine both streams
    yield* _combineLatestChats(asClient, asVendor);
  }

  Stream<List<Chat>> _combineLatestChats(
    Stream<List<Chat>> a,
    Stream<List<Chat>> b,
  ) async* {
    List<Chat> latestA = [];
    List<Chat> latestB = [];

    await for (final combined in Rx.combineLatest2<List<Chat>, List<Chat>, List<Chat>>(
      a,
      b,
      (listA, listB) {
        latestA = listA;
        latestB = listB;
        return _mergeAndSort([...latestA, ...latestB]);
      },
    )) {
      yield combined;
    }
  }

  List<Chat> _mergeAndSort(List<Chat> chats) {
    // Deduplicate by id, sort by lastMessageAt desc
    final map = <String, Chat>{};
    for (final c in chats) {
      map[c.id] = c;
    }
    final result = map.values.toList();
    result.sort((a, b) {
      final ta = a.lastMessageAt ?? DateTime(2000);
      final tb = b.lastMessageAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return result;
  }

  /// Stream of the single chat document (for typing/status/unread)
  Stream<Chat?> watchChat(String chatId) async* {
    await _ensureMessagingAuthReady();
    yield* _chatDoc(
      chatId,
    ).snapshots().map((s) => s.exists ? _chatFromDoc(s) : null);
  }

  Stream<Chat?> watchResolvedChat(String chatIdOrChatLookupKey) async* {
    if (chatIdOrChatLookupKey.isEmpty) {
      yield null;
      return;
    }
    await _ensureMessagingAuthReady();
    if (chatIdOrChatLookupKey.contains('_')) {
      yield* _chatDoc(chatIdOrChatLookupKey).snapshots().map((doc) {
        if (doc.exists) return _chatFromDoc(doc);
        return null;
      });
      return;
    }

    final storage = StorageService();
    final userId =
        storage.getString('user_id') ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    final role = storage.getString('user_role') ?? 'CUSTOMER';
    final userField = role.toUpperCase() == 'VENDOR'
        ? 'vendorId'
        : 'clientId';

    yield* _chats
        .where('leadId', isEqualTo: chatIdOrChatLookupKey)
        .where(userField, isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.isEmpty ? null : _chatFromDoc(snapshot.docs.first),
        );
  }

  /// Stream of messages in a chat, ordered by serverAt ascending
  Stream<List<Message>> watchMessages(String chatId) async* {
    await _ensureMessagingAuthReady();
    yield* _messages(chatId)
        .orderBy('serverAt')
        .snapshots()
        .map((s) => s.docs.map(_messageFromDoc).toList());
  }

  /// Stream of a user's presence doc
  Stream<Presence?> watchPresence(String userId) async* {
    if (userId.isEmpty) {
      yield null;
      return;
    }
    await _ensureMessagingAuthReady();
    yield* _presenceDoc(
      userId,
    ).snapshots().map((s) => s.exists ? _presenceFromDoc(s) : null);
  }

  // ─── Send message ──────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    String? imageUrl,
    Map<String, dynamic>? systemData,
  }) async {
    await _ensureMessagingAuthReady();
    final now = DateTime.now();
    final msgRef = _messages(chatId).doc();

    // 1. Write the message first (most important operation)
    await msgRef.set({
      'id': msgRef.id,
      'senderId': senderId,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (systemData != null) 'systemData': systemData,
      'sentAt': Timestamp.fromDate(now),
      'serverAt': FieldValue.serverTimestamp(),
      'deliveredTo': [],
      'readBy': [],
    });

    // 2. Update the chat summary (best-effort — don't fail the send if this errors)
    try {
      final chatDoc = await _chatDoc(chatId).get();
      if (chatDoc.exists) {
        final isClient = chatDoc.data()?['clientId'] == senderId;
        final unreadField = isClient ? 'unreadByVendor' : 'unreadByClient';

        await _chatDoc(chatId).update({
          'lastMessage': type == 'image' ? '📷 Photo' : text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderId,
          'lastMessageType': type,
          'updatedAt': FieldValue.serverTimestamp(),
          unreadField: FieldValue.increment(1),
        });
      } else {
        debugPrint(
          '[Chat] Chat doc $chatId does not exist — skipping summary update.',
        );
      }
    } catch (e) {
      debugPrint('[Chat] Failed to update chat summary: $e');
    }
  }

  // ─── Mark as read ──────────────────────────────────────────────────────────

  Future<void> markAsRead({
    required String chatId,
    required String userId,
    required bool isVendor,
  }) async {
    await _ensureMessagingAuthReady();
    try {
      // Find unread messages not yet in readBy
      final snap = await _messages(
        chatId,
      ).orderBy('serverAt', descending: true).limit(100).get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      var hasUpdates = false;
      for (final doc in snap.docs) {
        final data = doc.data();
        final senderId = data['senderId']?.toString() ?? '';
        final readBy = List<String>.from(data['readBy'] ?? const []);
        final deliveredTo = List<String>.from(data['deliveredTo'] ?? const []);

        if (senderId != userId &&
            (!readBy.contains(userId) || !deliveredTo.contains(userId))) {
          batch.update(doc.reference, {
            if (!readBy.contains(userId))
              'readBy': FieldValue.arrayUnion([userId]),
            if (!deliveredTo.contains(userId))
              'deliveredTo': FieldValue.arrayUnion([userId]),
          });
          hasUpdates = true;
        }
      }

      // Reset unread counter for this role
      final unreadField = isVendor ? 'unreadByVendor' : 'unreadByClient';
      batch.update(_chatDoc(chatId), {unreadField: 0});
      hasUpdates = true;

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('[Chat] markAsRead error: $e');
    }
  }

  // ─── Typing ────────────────────────────────────────────────────────────────

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _ensureMessagingAuthReady();
    try {
      await _chatDoc(chatId).update({
        'typing.$userId': isTyping ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      debugPrint('[Chat] setTyping error: $e');
    }
  }

  // ─── Presence ──────────────────────────────────────────────────────────────

  Future<void> setPresence({
    required String userId,
    required bool online,
  }) async {
    await _ensureMessagingAuthReady();
    try {
      await _presenceDoc(userId).set({
        'userId': userId,
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Presence] setPresence error: $e');
    }
  }

  Future<Chat?> getChatByLeadId(String leadId) async {
    if (leadId.isEmpty) return null;
    await _ensureMessagingAuthReady();
    final storage = StorageService();
    final userId =
        storage.getString('user_id') ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    final role = storage.getString('user_role') ?? 'CUSTOMER';
    final userField = role.toUpperCase() == 'VENDOR'
        ? 'vendorId'
        : 'clientId';

    final snapshot = await _chats
        .where('leadId', isEqualTo: leadId)
        .where(userField, isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _chatFromDoc(snapshot.docs.first);
  }

  Future<void> updateChatStatus({
    required String chatId,
    required ChatStatus status,
  }) async {
    await _chatDoc(chatId).update({
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChatStatusByLeadId({
    required String leadId,
    required ChatStatus status,
  }) async {
    final chat = await getChatByLeadId(leadId);
    if (chat == null) return;
    await updateChatStatus(chatId: chat.id, status: status);
  }

  // ─── Converters ────────────────────────────────────────────────────────────

  Chat _chatFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Chat(
      id: doc.id,
      clientId: d['clientId'] ?? '',
      vendorId: d['vendorId'] ?? '',
      customerName: d['customerName'] ?? '',
      customerPhotoUrl: d['customerPhotoUrl'] ?? '',
      customerPhone: d['customerPhone'] ?? '',
      vendorName: d['vendorName'] ?? '',
      vendorPhotoUrl: d['vendorPhotoUrl'] ?? '',
      vendorPhone: d['vendorPhone'] ?? '',
      leadId: d['leadId'],
      status: ChatStatus.fromString(d['status']),
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: d['lastMessageSenderId'],
      lastMessageType: d['lastMessageType'] ?? 'text',
      unreadByClient: (d['unreadByClient'] as int?) ?? 0,
      unreadByVendor: (d['unreadByVendor'] as int?) ?? 0,
      typing: _parseTypingMap(d['typing']),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Message _messageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Message(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      type: MessageType.fromString(d['type']),
      imageUrl: d['imageUrl'],
      systemData: d['systemData'] != null
          ? Map<String, dynamic>.from(d['systemData'])
          : null,
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      serverAt: (d['serverAt'] as Timestamp?)?.toDate(),
      deliveredTo: List<String>.from(d['deliveredTo'] ?? []),
      readBy: List<String>.from(d['readBy'] ?? []),
    );
  }

  Presence _presenceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Presence(
      userId: doc.id,
      online: d['online'] == true,
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, DateTime?> _parseTypingMap(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), v is Timestamp ? v.toDate() : null),
    );
  }
}
