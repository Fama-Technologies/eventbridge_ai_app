# WhatsApp-Style Messaging System — Design Spec

**Date:** 2026-04-08
**Author:** brainstorming session
**Status:** Approved for planning
**Scope:** Replace the current broken messaging system in the EventBridge Flutter app with a production-grade, WhatsApp/Telegram-feel real-time chat using Firestore (messages/presence/typing/receipts), AWS S3 (image attachments), and FCM (push notifications).

---

## 1. Problem

The existing messaging code has multiple correctness and UX problems:

- **Two divergent implementations** — `lib/features/messaging/presentation/customer_chat_detail_screen.dart` (366 lines) for customers and `lib/features/vendors_screen/vendor_chat_screen.dart` (998 lines, messy) for vendors. Same conversation, different code, different bugs.
- **WebSocket event name casing bug** — customer listens for `new_message`, vendor listens for `NEW_MESSAGE`. Real-time delivery is unreliable.
- **Stale active chat id** — `WebSocketService.activeChatId = _chatId` is set before `_chatId` is fetched from the server, so it's always `null` at init.
- **3-second polling loop** on top of the WebSocket in the vendor screen → duplicate messages, wasted bandwidth, cold-start penalty on every poll.
- **Raw `Map<String, dynamic>` everywhere** — no typed models, unsafe field access, easy to break on schema changes.
- **No typing indicator, no read receipts, no presence ("online"), no delivered ticks.**
- **UI is plain** — no bubble tails, no sticky date separators, no unread badges, no grouping of consecutive messages from the same sender.
- **Latency is high** — Lambda cold starts add 500ms–2s per request; AWS API Gateway WebSocket drops connections.
- **No failure isolation** — when the Lambda WebSocket dies, real-time chat dies with it.

Users can send messages, but the experience feels broken compared to WhatsApp or Telegram. The user has explicitly asked for a "fully working" WhatsApp-style chat with low latency.

## 2. Goals

- Messages sent and received in under 300ms perceived latency.
- Full WhatsApp-feel features: typing indicators, read receipts (`✓`, `✓✓`, `✓✓` blue), delivered ticks, presence (online / last seen), unread badges, sticky date separators, grouped consecutive messages, bubble tails.
- One unified `ChatDetailScreen` used by both customer and vendor (delete the two separate screens).
- Typed `Chat` and `Message` Freezed models end-to-end — no `Map<String, dynamic>` at the UI layer.
- Image attachments via existing AWS S3 presigned-URL infrastructure (no new storage cost).
- Push notifications via FCM (Firebase Cloud Messaging is already installed and free).
- Phone-number reveal with tap-to-dial, **only after the vendor accepts the lead** (privacy gate).
- Preserve the existing product rule: chat input is locked until `status == 'accepted'`.
- Zero data migration risk — old Postgres chat rows stay archived in place.

## 3. Non-Goals

- **Voice messages** — postponed (phase 2).
- **Emoji reactions / message replies / delete-for-everyone** — postponed.
- **Message search** — postponed.
- **Group chats** — the data model supports it but no group chat UI for now.
- **Migrating old Postgres messages** — old messages stay where they are; new system starts fresh.
- **Changes to the existing lead / matching / vendor onboarding flows** — out of scope.

## 4. Architecture

### 4.1 Stack

| Layer | Service | Why |
|---|---|---|
| Real-time messages, chats, typing, presence, receipts | **Firebase Firestore** | Real-time listeners, offline cache, < 200ms sync, free at current scale |
| Image attachments | **AWS S3** (existing) | Already paid for; reuses existing presigned-URL Lambda endpoint |
| Push notifications | **Firebase Cloud Messaging (FCM)** | Always free, unlimited, already installed |
| User accounts, leads, vendors, bookings | **AWS Lambda + PostgreSQL** (existing) | Unchanged — polyglot persistence |

**Polyglot persistence rationale:** Postgres is the source of truth for relational data (users, leads, bookings). Firestore is the source of truth for real-time, append-only chat data. The two are linked by immutable IDs (`customerId`, `vendorId`, `leadId`) — no sync or replication required. This is a standard production pattern used by many large applications.

**Failure isolation:** If Firestore is down, auth/leads/payments still work. If Postgres is down, existing chats still work. This is an improvement over the current single-cloud architecture where a Lambda outage takes everything down.

### 4.2 Flutter Module Layout

Follows the existing clean-architecture pattern of `features/auth` and `features/matching`.

```
lib/features/messaging/
├── domain/
│   ├── entities/
│   │   ├── chat.dart                 (Chat entity — Freezed)
│   │   ├── message.dart              (Message entity — Freezed, sealed types)
│   │   ├── presence.dart             (Presence entity — Freezed)
│   │   └── chat_status.dart          (enum: pending, accepted, declined)
│   └── repositories/
│       └── chat_repository.dart      (abstract interface)
├── data/
│   ├── models/
│   │   ├── chat_dto.dart             (Freezed + fromFirestore/toFirestore)
│   │   └── message_dto.dart          (Freezed + fromFirestore/toFirestore)
│   ├── datasources/
│   │   ├── firestore_chat_source.dart    (all Firestore reads/writes/streams)
│   │   ├── s3_image_uploader.dart        (presigned-URL flow)
│   │   └── presence_source.dart          (online/offline heartbeat)
│   └── repositories/
│       └── firestore_chat_repository.dart  (implements ChatRepository)
└── presentation/
    ├── providers/
    │   ├── chat_repository_provider.dart
    │   ├── chats_list_provider.dart           (StreamProvider — list of chats for current user)
    │   ├── chat_messages_provider.dart        (StreamProvider.family<ChatId>)
    │   ├── chat_detail_provider.dart          (StreamProvider.family<ChatId>)
    │   ├── presence_provider.dart             (StreamProvider.family<UserId>)
    │   └── chat_controller.dart               (StateNotifier — send, markRead, setTyping)
    ├── screens/
    │   ├── chats_list_screen.dart             (unified — customer or vendor role)
    │   └── chat_detail_screen.dart            (unified — customer or vendor role)
    └── widgets/
        ├── chat_list_tile.dart
        ├── message_bubble.dart
        ├── date_separator.dart
        ├── typing_bubble.dart
        ├── chat_input_bar.dart
        ├── presence_dot.dart
        ├── tick_icon.dart
        ├── call_header_action.dart
        ├── locked_chat_banner.dart
        └── system_lead_card.dart               (reuses existing LeadMilestoneCard)
```

### 4.3 Files To Delete

- `lib/core/network/websocket_service.dart` — replaced by Firestore streams
- `lib/features/vendors_screen/vendor_chat_screen.dart` (998 lines) — replaced by unified `ChatDetailScreen`
- `lib/features/messaging/presentation/customer_chat_detail_screen.dart` (366 lines) — replaced by unified `ChatDetailScreen`
- `lib/features/messaging/presentation/customer_chats_screen.dart` (343 lines) — replaced by unified `ChatsListScreen`
- Chat-related methods in `lib/core/network/api_service.dart`:
  - `getCustomerChats`, `initChat`, `getCustomerChatMessages`, `sendCustomerChatMessage`
  - `getVendorChats`, `markChatAsRead`, `sendVendorChatMessage`

Routes in `lib/core/router/app_router.dart` must be updated so `/customer-chats`, `/customer-chat/:id`, and `/vendor-chat/:id` all point to the new unified screens.

## 5. Firestore Data Model

### 5.1 Collection: `chats/{chatId}`

`chatId` is **deterministic**: `"{customerId}_{vendorId}"`. This makes "init chat" a no-op merge write and prevents duplicate chat documents.

```
{
  id: "customerA_vendorB",
  customerId: "uuid-a",
  vendorId: "uuid-b",

  // Denormalized for chat list (avoids extra reads)
  customerName: "Jane Doe",
  customerPhotoUrl: "https://s3.../jane.jpg",
  customerPhone: "+256700000000",
  vendorName: "Bob's Catering",
  vendorPhotoUrl: "https://s3.../bob.jpg",
  vendorPhone: "+256711111111",

  // Link back to Postgres
  leadId: "lead-uuid-123",

  // Gating
  status: "pending" | "accepted" | "declined",

  // Last message summary (chat list only fetches this)
  lastMessage: "See you tomorrow",
  lastMessageAt: Timestamp,
  lastMessageSenderId: "uuid-a",
  lastMessageType: "text" | "image" | "system",

  // Unread counters per role (cheap, atomic)
  unreadByCustomer: 0,
  unreadByVendor: 2,

  // Typing state (piggybacks on the chat stream — no extra listener)
  typing: {
    "uuid-a": Timestamp or null,
    "uuid-b": Timestamp or null
  },

  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

### 5.2 Subcollection: `chats/{chatId}/messages/{messageId}`

```
{
  id: "auto-id",
  senderId: "uuid-a",
  text: "Hello there",
  type: "text" | "image" | "system",
  imageUrl: null,            // S3 URL if type=image
  systemData: null,          // JSON map for system cards (inquiry/lead milestones)
  sentAt: Timestamp,         // client local time (used for optimistic ordering)
  serverAt: Timestamp,       // server-side timestamp (authoritative ordering)
  deliveredTo: ["uuid-b"],   // recipient userIds who received the message
  readBy: ["uuid-b"],        // recipient userIds who opened the chat
}
```

Messages are ordered by `serverAt` ascending. `sentAt` is only used for the optimistic local placement before the server round-trip completes.

### 5.3 Collection: `presence/{userId}`

```
{
  userId: "uuid-a",
  online: true,
  lastSeen: Timestamp,
  updatedAt: Timestamp,
}
```

### 5.4 Denormalization Notes

- `customerName`, `customerPhotoUrl`, `customerPhone`, `vendorName`, `vendorPhotoUrl`, `vendorPhone` are **denormalized onto the chat document** so the chat list can render without extra reads.
- Updating these on profile changes is out of scope for this spec; a later sync job can refresh them.
- `lastMessage*` is updated on every message send inside a single batched write.

## 6. Real-Time Flows

### 6.1 Send Message

1. User taps send. Local UI appends the message with `status: sending` immediately (0ms perceived).
2. `ChatController.sendMessage()` runs a Firestore batched write:
   - Create `chats/{chatId}/messages/{auto}` with `serverAt: FieldValue.serverTimestamp()`.
   - Update `chats/{chatId}`: `lastMessage`, `lastMessageAt`, `lastMessageSenderId`, `lastMessageType`, `updatedAt`, and atomic increment of `unreadBy{otherRole}`.
3. Firestore syncs (~100–200ms). The local optimistic message is replaced when the real doc arrives via the stream.
4. Recipient's client receives the doc via its message stream → renders the bubble.
5. Recipient's client writes `deliveredTo: arrayUnion(myUid)` → single ✓ becomes ✓✓.
6. When recipient opens the chat detail screen, controller writes `readBy: arrayUnion(myUid)` on all unread messages in a single batch (debounced ≤ 500ms) and resets `unreadBy{myRole} = 0` → ✓✓ turns blue.

### 6.2 Receive Message (App Foreground)

- `chatMessagesProvider(chatId)` is a `StreamProvider.family` wrapping `firestore.collection('chats/{chatId}/messages').orderBy('serverAt').snapshots()`.
- On doc add, Riverpod rebuilds the bubble list. If the user is within 100px of the bottom, auto-scroll.
- If the user is scrolled up, show a "new message" pill at the bottom they can tap.

### 6.3 Receive Message (App Closed or Background)

- Cloud Function `onMessageCreate` triggers on any new `chats/*/messages/*` document.
- Function reads the recipient's FCM token from `users/{recipientId}.fcmToken` (stored at app launch).
- Sends FCM data message with `chatId`, `senderName`, `preview`, and a notification payload.
- App's FCM handler deep-links to `/chat/{chatId}` on tap.

### 6.4 Typing Indicator

- On each keystroke, `ChatController.onInputChanged()` schedules a debounced write (300ms) of `chats/{chatId}.typing.{myUid} = serverTimestamp()`.
- A 2-second "stop typing" timer writes `typing.{myUid} = null` after user stops.
- `chatDetailProvider(chatId)` stream already includes the full chat doc — typing state arrives with no extra listener.
- UI shows "typing..." in the header (or a typing bubble in the message list) if `typing[otherUid]` exists and is less than 5 seconds old.
- On send, typing is cleared immediately.

### 6.5 Presence

- `PresenceSource` writes `presence/{myUid}` with `online: true, lastSeen: now, updatedAt: now` on app launch and every foreground resume.
- On app pause/background, writes `online: false, lastSeen: now`.
- A 30-second heartbeat while in foreground keeps `lastSeen` fresh (protects against crashes).
- Chat detail header subscribes to `presenceProvider(otherUid)` and displays:
  - `online: true` → "online"
  - `online: false` → "last seen {humanized(lastSeen)}"
- Chat list tiles show a green dot overlay on the avatar when the other party is online.

### 6.6 Read Receipts

- When the chat detail screen opens: controller debounces (≤ 500ms) a single batched write of `readBy: arrayUnion(myUid)` on all currently visible unread messages, plus resets `unreadBy{myRole}` on the chat doc.
- Each subsequent inbound message while the chat is open adds to the pending batch.
- Single-tick, double-tick, and blue-tick state is derived locally from `deliveredTo` and `readBy` of the other user.

### 6.7 Chat List Auto-Sort

- `chatsListProvider` queries `chats` where `customerId == myUid OR vendorId == myUid` (implemented as two merged streams or a `array-contains` on a `participants` field — final form decided in planning).
- Ordered by `lastMessageAt DESC`.
- Any update to `lastMessageAt` automatically bumps the chat to the top.

### 6.8 Image Send (via S3)

1. User taps the attach icon → picks an image from gallery (`image_picker` package, already installed).
2. Local UI appends a message bubble with a local file preview and `status: uploading`.
3. `S3ImageUploader.upload(file)` calls the existing `POST /api/upload/presigned-url` Lambda → gets a temporary upload URL.
4. `PUT` the file bytes directly to S3 (no Lambda bandwidth cost).
5. On success, `ChatController.sendMessage(type: image, imageUrl: s3Url)` writes the Firestore message.
6. Both sides' streams deliver the image bubble.

### 6.9 Lead Accept → Chat Unlock

- Vendor taps Accept on a lead. Existing Lambda endpoint updates the Postgres lead row.
- Lambda calls **Firebase Admin SDK** (already installed server-side via `FIREBASE_SERVICE_ACCOUNT` env var) to write `chats/{chatId}.status = 'accepted'`.
- Both sides' chat detail screens listen to the chat doc → input bar unlocks, phone number + call icon appear.

### 6.10 Phone Reveal + Tap-to-Dial

- Header shows phone number and a green call icon **only when** `chat.status == 'accepted'`.
- Tap the icon or the number → `url_launcher` opens `tel:{phone}` → native dialer with number pre-filled.
- Phone numbers come from denormalized `customerPhone` / `vendorPhone` on the chat doc.

## 7. UI Specification

### 7.1 Chats List Screen

- App bar: title "Chats", search icon, overflow menu.
- Background: WhatsApp cream (`#EFEAE2` light) or WhatsApp dark (`#0B141A` dark).
- Tile layout: circular avatar (56px) with presence dot overlay, vendor/customer name, last message preview with tick prefix, time (green+bold when unread), unread badge (green pill `#25D366`).
- Tap → chat detail screen.

### 7.2 Chat Detail Screen

- **Header**:
  - Back arrow
  - Circular avatar (40px) with presence dot
  - Name (bold)
  - Subtitle: `online` / `last seen X` / `typing...` (whichever is current)
  - Phone number (when `accepted`, small, below name)
  - Green call icon on the right (when `accepted`)
  - Overflow menu
- **Body**:
  - WhatsApp cream background
  - Sticky date separator pills ("Today", "Yesterday", "March 5, 2026")
  - Incoming bubbles: white (`#FFFFFF`) / dark (`#1F2C33`), left-aligned, tail on bottom-left of first bubble in a sequence
  - Outgoing bubbles: WA green (`#D9FDD3`) / dark green (`#005C4B`), right-aligned, tail on bottom-right of first bubble in a sequence
  - Consecutive messages from the same sender grouped together (no avatar/name repeat, tighter spacing)
  - Tick icons inside outgoing bubbles: `✓` (sent), `✓✓` gray (delivered), `✓✓` blue `#53BDEB` (read)
  - Typing bubble: 3 animated dots in a small incoming-style bubble, shown above input when `typing[otherUid]` is active
  - System lead cards: rendered as non-bubble widgets (reuses existing `LeadMilestoneCard`)
- **Input bar**:
  - When `status == pending`: replaced by a `LockedChatBanner` — "Waiting for vendor to accept — tap to view lead"
  - When `status == accepted`:
    - Emoji icon (placeholder, phase 2)
    - Text field with rounded background
    - Attach icon (image picker)
    - Mic icon when text is empty (phase 2 — stub for now)
    - Send icon (green circle) when text is present

### 7.3 Theme Tokens

Add to `lib/core/theme/app_colors.dart`:

```dart
static const waChatBg = Color(0xFFEFEAE2);
static const waChatBgDark = Color(0xFF0B141A);
static const waOutgoing = Color(0xFFD9FDD3);
static const waOutgoingDark = Color(0xFF005C4B);
static const waIncoming = Color(0xFFFFFFFF);
static const waIncomingDark = Color(0xFF1F2C33);
static const waTickBlue = Color(0xFF53BDEB);
static const waTickGray = Color(0xFF8696A0);
static const waGreen = Color(0xFF25D366);
static const waHeader = Color(0xFF008069);
static const waHeaderDark = Color(0xFF1F2C33);
```

## 8. Security Rules

`firestore.rules` (new file at project root, deployed via `firebase deploy --only firestore:rules`):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /chats/{chatId} {
      allow read: if request.auth != null
        && (resource.data.customerId == request.auth.uid
            || resource.data.vendorId == request.auth.uid);

      allow create: if request.auth != null
        && (request.resource.data.customerId == request.auth.uid
            || request.resource.data.vendorId == request.auth.uid);

      allow update: if request.auth != null
        && (resource.data.customerId == request.auth.uid
            || resource.data.vendorId == request.auth.uid);

      match /messages/{msgId} {
        allow read: if request.auth != null
          && (get(/databases/$(database)/documents/chats/$(chatId)).data.customerId == request.auth.uid
           || get(/databases/$(database)/documents/chats/$(chatId)).data.vendorId == request.auth.uid);

        allow create: if request.auth != null
          && request.resource.data.senderId == request.auth.uid;

        // Only deliveredTo / readBy may be updated after creation
        allow update: if request.auth != null
          && request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['deliveredTo', 'readBy']);
      }
    }

    match /presence/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Note: the `status: accepted` update that unlocks the chat is written by the **backend Lambda** using the Firebase Admin SDK (which bypasses security rules). The rules above intentionally do not let clients change `status` — only the backend can.

## 9. Migration & Rollout

- **No data migration.** Old Postgres chat rows stay archived in place and can be recovered later if needed.
- **Feature flag** `USE_FIRESTORE_CHAT` in a new `lib/core/config/feature_flags.dart` — allows instant rollback by flipping the flag.
- **Route updates** in `lib/core/router/app_router.dart`:
  - `/customer-chats` → `ChatsListScreen(role: customer)`
  - `/customer-chat/:id` → `ChatDetailScreen(chatId: id)`
  - `/vendor-chat/:id` → `ChatDetailScreen(chatId: id)`
  - Vendor leads screen's "chat" button routes to the same `/chat/:id` path.
- **Deletion** of old files happens only after manual testing passes and the feature flag is removed.
- **Backend change:** the lead-accept Lambda endpoint adds a Firebase Admin SDK call to write `chats/{chatId}` with `status: 'accepted'` and denormalized profile fields.

## 10. Testing

### 10.1 Unit Tests

- `MessageDto.fromFirestore` → `toFirestore` round-trip equality.
- `ChatDto.fromFirestore` → `toFirestore` round-trip equality, including the `typing` map.
- `FirestoreChatRepository` tested against `fake_cloud_firestore` package: send message updates chat + messages subcollection in a single batch; mark-as-read clears unread counter.
- `ChatController` debounce logic for typing and read receipts (use `fake_async`).

### 10.2 Integration Tests

- End-to-end with `fake_cloud_firestore`: two simulated users, verify that when user A sends a message, user B's listener fires with the new message within the test frame.
- Typing indicator propagation: user A writes typing state, user B's chat stream surfaces it.
- Read receipts: user B opens chat, verify `readBy` array contains user B's uid on all relevant messages.

### 10.3 Manual Test Checklist (on real devices)

1. Customer sends text message → vendor sees bubble in < 500ms real-world.
2. Vendor types → customer sees "typing..." in header within 500ms.
3. Customer backgrounds the app → vendor sees "last seen ..." within 10 seconds.
4. Customer sends image → vendor sees image bubble; tapping opens full-screen viewer.
5. Vendor force-quits app → customer sends message → FCM push arrives on vendor's device within 3 seconds.
6. Pending chat → both sides see `LockedChatBanner` and cannot type.
7. Vendor accepts lead → within 2 seconds, both chat screens unlock and show phone number + call icon.
8. Customer taps call icon → native dialer opens with vendor's phone number pre-filled.
9. Customer opens chat → all vendor's previous outgoing messages turn `✓✓` blue on vendor's side within 1 second.
10. Customer turns on airplane mode → types and sends 3 messages → messages stay visible with `sending` state → airplane mode off → all 3 messages sync within 5 seconds.
11. Two chats with new messages → chat list shows correct unread counts and both chats are reordered to the top with the most recent on top.
12. Delete conversation on one side (if implemented in phase 1; otherwise deferred).

## 11. Cost Analysis

Target scale: 1000 daily active users × 100 messages/day = 100k messages/day.

| Service | Usage | Cost |
|---|---|---|
| Firestore writes | ~200k/day (message + chat doc update + read receipts) | Free tier: 20k/day. Overage: ~$0.18/day |
| Firestore reads | ~500k/day (listeners re-delivering) | Free tier: 50k/day. Overage: ~$0.27/day |
| Firestore storage | ~500 MB / year | Essentially $0 |
| FCM push | Unlimited | **$0** |
| S3 image uploads | Depends on usage | Already paying, no increase |
| AppSync / Lambda WS (removed) | 0 | **Saves existing cost** |

**Estimated cost at full scale: ~$15/month.** Today (small user base): **$0**.

## 12. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Firestore outage | Existing features (auth, leads, payments) unaffected — failure isolation. Messaging fails loudly but gracefully. |
| Firestore free-tier overrun at unexpected growth | Monitor Firestore usage dashboard daily during rollout. Feature flag allows instant rollback. |
| Cloud Function for FCM push adds latency | Keep function minimal (< 100ms typical). Use data-only FCM messages for fastest delivery. |
| Denormalized profile data (name, photo, phone) becomes stale | Accept staleness for phase 1. Build a background sync job in phase 2 if needed. |
| Security rule bugs leaking data | Write security rules tests with the Firebase emulator before deploying. Rules are intentionally strict — only participants can read a chat. |
| Old `WebSocketService` lingering imports | Delete in the same PR as the new screens; flutter analyze will catch any lingering references. |

## 13. Open Questions (resolve during planning)

- `chats` query form: merged two streams (one for `customerId == me`, one for `vendorId == me`) vs. a `participants: [...]` array field with `array-contains me`. The array-contains form is simpler and cheaper; decide in planning.
- Should unread badge count total unread messages across all chats and display on the bottom nav? (Likely yes, but confirm.)
- Cloud Function language: JavaScript (matches existing backend stack) or TypeScript? (Prefer JS for consistency.)
- Should we add a "seen" avatar (small circle below the last read message) like WhatsApp web does? (Phase 2.)

## 14. Definition of Done

- Unified `ChatsListScreen` and `ChatDetailScreen` in place; old customer and vendor chat screens deleted.
- `WebSocketService` deleted; no remaining references in the codebase (verified by `flutter analyze`).
- Typed `Chat` and `Message` Freezed models everywhere — no `Map<String, dynamic>` in presentation or domain layers.
- All 12 manual test checklist items pass on a real Android device (and iOS if available).
- Unit and integration tests added and passing.
- Firestore security rules deployed and tested with the Firebase emulator.
- Cloud Function for FCM push deployed and verified.
- Backend Lambda updated to write Firestore chat doc on lead accept.
- Firestore usage dashboard monitored for 24 hours post-deploy with no cost anomalies.
- Feature flag removed after verification.
- Project documentation updated with new messaging architecture.
