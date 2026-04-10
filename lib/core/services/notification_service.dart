import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';
import 'package:eventbridge/core/network/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet.dart';
import 'package:eventbridge/firebase_options.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Hook registered by the auth layer at startup. When Firebase Auth uid
  /// diverges from backend user_id during FCM token sync, NotificationService
  /// calls this to re-run the custom-token restore flow without taking a
  /// direct dependency on AuthRepository (which would be a circular import).
  static Future<void> Function()? firebaseAuthRestoreHook;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Guard against re-entrant restore loops: updateToken → _saveTokenToFirestore
  // → firebaseAuthRestoreHook → restoreFirebaseMessagingAuthIfNeeded → updateToken…
  bool _isRestoringAuth = false;

  // Notification ID range reserved for booking reminders: 1000–1999
  static const int _reminderBaseId = 1000;
  static const int _reminderMaxCount = 200; // max slots (40 bookings × 5 times)

  // The 5 reminder times (hour, minute) spread across the day
  static const List<(int, int)> _reminderTimes = [
    (8, 0),
    (10, 0),
    (12, 0),
    (15, 0),
    (18, 0),
  ];

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Notifications not supported on Web, skipping init.');
      return;
    }

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // 1. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint(
        '🔔 [NotificationService] User granted notification permission',
      );
    } else {
      debugPrint(
        '🔕 [NotificationService] User denied notification permission: ${settings.authorizationStatus}',
      );
    }

    // 2. Setup Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.payload != null) {
          _handleNavigation(response.payload!);
        }
      },
    );

    // Create the notification channel explicitly for background FCM support
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got message in foreground: ${message.data}');

      final chatId = message.data['chat_id']?.toString();
      if (chatId != null && WebSocketService.activeChatId == chatId) {
        debugPrint(
          'Suppressing foreground notification: User is already in the active chat.',
        );
        return;
      }

      final overlayContext = rootNavigatorKey.currentContext;
      if (overlayContext != null && overlayContext.mounted) {
        final title =
            message.notification?.title ??
            message.data['sender_name'] ??
            'New Message';
        final body =
            message.notification?.body ?? message.data['text'] ?? 'Tap to view';

        TopNotificationOverlay.show(
          context: overlayContext,
          title: title,
          message: body,
          onTap: () {
            _handleNavigation(chatId ?? '', type: message.data['type']);
          },
        );
      } else {
        // Fallback to local notification if context is missing
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      }
    });

    // 4. Handle Notification Clicks (Application opened from terminated or background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked! ${message.data}');
      final type = message.data['type'];
      final id =
          message.data['chat_id'] ??
          message.data['lead_id'] ??
          message.data['vendor_id'];
      if (id != null) {
        _handleNavigation(id, type: type);
      }
    });

    // 5. Get initial token
    updateToken();

    // 6. Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) => _saveTokenToBackend(token));
    
    // Diagnostic
    debugPrint('🔔 [NotificationService] Initialized. Checking push capability...');
  }

  Future<void> updateToken() async {
    if (kIsWeb) return;
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('✅ [NotificationService] FCM Token retrieved: $token');
        _saveTokenToBackend(token);
      } else {
        debugPrint('⚠️ [NotificationService] FCM Token is NULL - push will not work.');
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    final storage = StorageService();
    final userId = storage.getString('user_id');
    if (userId == null) return;

    final savedToken = storage.getString('fcm_token');
    final tokenUnchanged = savedToken == token;

    try {
      if (!tokenUnchanged) {
        debugPrint(
          '🚀 [NotificationService] Syncing FCM Token for userId: $userId',
        );
        final success = await ApiService.instance.updateFcmToken(userId, token);
        if (!success) {
          debugPrint(
            '❌ [NotificationService] Backend failed to update FCM token',
          );
          return;
        }

        await storage.setString('fcm_token', token);
        debugPrint(
          '✅ [NotificationService] FCM Token synced successfully: $token',
        );
      }

      await _saveTokenToFirestore(userId, token);
    } catch (e) {
      debugPrint('🚨 [NotificationService] Error syncing FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    var currentFirebaseUser =
        firebase_auth.FirebaseAuth.instance.currentUser;

    // If Firebase Auth is not aligned with the backend user_id, the
    // Firestore security rule on `notificationTokens/{uid}` will reject
    // the write AND the Cloud Function `onMessageCreate` won't find a
    // token for this user — so pushes silently stop firing. Try to
    // restore the custom-token session once before giving up.
    if (currentFirebaseUser == null || currentFirebaseUser.uid != userId) {
      // Prevent infinite loop: restore calls updateToken which calls us again
      if (_isRestoringAuth) {
        debugPrint(
          '⚠️ [NotificationService] Skipping nested restore attempt — '
          'already restoring auth.',
        );
        return;
      }

      debugPrint(
        '⚠️ [NotificationService] Firebase uid (${currentFirebaseUser?.uid}) '
        '!= backend user_id ($userId). Attempting custom-token restore...',
      );
      final restore = firebaseAuthRestoreHook;
      if (restore == null) {
        debugPrint(
          '🚨 [NotificationService] No firebaseAuthRestoreHook registered — '
          'auth layer must set NotificationService.firebaseAuthRestoreHook '
          'at startup.',
        );
      } else {
        _isRestoringAuth = true;
        try {
          await restore();
        } catch (e) {
          debugPrint(
            '🚨 [NotificationService] firebaseAuthRestoreHook threw: $e',
          );
        } finally {
          _isRestoringAuth = false;
        }
      }
      currentFirebaseUser =
          firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser == null ||
          currentFirebaseUser.uid != userId) {
        debugPrint(
          '🚨 [NotificationService] Firebase Auth still not aligned with '
          'backend user $userId after restore attempt. Skipping '
          'notificationTokens/$userId write — push notifications will NOT '
          'be delivered to this user until login/restart fixes the uid.',
        );
        return;
      }
      debugPrint(
        '✅ [NotificationService] Firebase Auth aligned after restore.',
      );
    }

    try {
      await FirebaseFirestore.instance
          .collection('notificationTokens')
          .doc(userId)
          .set({
            'userId': userId,
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name,
          }, SetOptions(merge: true));
      debugPrint(
        '✅ [NotificationService] FCM token written to notificationTokens/$userId',
      );
    } catch (e) {
      debugPrint(
        '🚨 [NotificationService] Failed to write notificationTokens/$userId: $e',
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = message.data['type'] ?? 'message';
    final payload =
        message.data['chat_id'] ??
        message.data['lead_id'] ??
        message.data['vendor_id'];

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          playSound: true,
          ticker: 'ticker',
        );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: payload != null ? '$type:$payload' : null,
    );
  }

  // ─── Booking Reminder Notifications ──────────────────────────────────────────

  /// Schedule 5 reminder notifications per booking that is exactly 3 days away.
  /// Times: 08:00, 10:00, 12:00, 15:00, 18:00 on the reminder day.
  /// Cancels all previously scheduled reminders before rescheduling.
  Future<void> scheduleBookingReminders(List<DateTime> bookingDates) async {
    if (kIsWeb) return;

    // 1. Cancel all existing booking reminders in our reserved range
    for (
      int i = _reminderBaseId;
      i < _reminderBaseId + _reminderMaxCount;
      i++
    ) {
      await _localNotifications.cancel(id: i);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 2. Determine the local timezone location
    tz.Location location;
    try {
      location = tz.timeZoneDatabase.locations.values.firstWhere(
        (loc) => loc.currentTimeZone.offset == now.timeZoneOffset,
        orElse: () => tz.UTC,
      );
    } catch (_) {
      location = tz.UTC;
    }

    int idCounter = _reminderBaseId;

    for (final bookingDate in bookingDates) {
      // Normalize booking date to midnight
      final bookingDay = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );

      // Calculate the day the reminder should fire (3 days BEFORE the booking)
      final reminderDay = bookingDay.subtract(const Duration(days: 3));

      // If the reminder day is in the past, we skip it
      if (reminderDay.isBefore(today)) continue;

      for (final (hour, minute) in _reminderTimes) {
        if (idCounter >= _reminderBaseId + _reminderMaxCount) {
          debugPrint(
            '⚠️ Warning: Booking reminder limit reached. Some reminders may not be scheduled.',
          );
          break;
        }

        final scheduledTime = tz.TZDateTime(
          location,
          reminderDay.year,
          reminderDay.month,
          reminderDay.day,
          hour,
          minute,
        );

        // Skip if this time has already passed (critical for reminders scheduled for TODAY)
        if (scheduledTime.isBefore(tz.TZDateTime.now(location))) continue;

        final bookingLabel =
            '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';

        await _localNotifications.zonedSchedule(
          id: idCounter,
          title: '📅 Upcoming Booking Reminder',
          body:
              'You have a booking on $bookingLabel — just 3 days away! Make sure you\'re prepared.',
          scheduledDate: scheduledTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
              playSound: true,
              styleInformation: const BigTextStyleInformation(''),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:availability',
        );

        idCounter++;
      }
    }

    debugPrint(
      '✅ Booking reminders scheduled: ${idCounter - _reminderBaseId} notifications across ${bookingDates.length} bookings',
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────────

  void _handleNavigation(String payload, {String? type}) {
    String navType = type ?? 'message';
    String id = payload;

    if (payload.contains(':')) {
      final parts = payload.split(':');
      navType = parts[0];
      id = parts[1];
    }

    final role = StorageService().getString('user_role');
    debugPrint('Navigating to $navType with ID: $id (Role: $role)');

    switch (navType) {
      case 'message':
      case 'chat':
        if (role == 'VENDOR') {
          appRouter.push('/vendor-chat/$id');
        } else {
          appRouter.push('/customer-chat/$id');
        }
        break;
      case 'lead':
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => LeadDetailsBottomSheet(leadId: id),
          );
        }
        break;
      case 'vendor':
        appRouter.push('/vendor-public/$id');
        break;
      case 'reminder':
      case 'availability':
        appRouter.push(
          role == 'VENDOR' ? '/vendor-availability' : '/customer-home',
        );
        break;
      case 'settings':
        appRouter.push(
          role == 'VENDOR' ? '/vendor-settings' : '/customer-settings',
        );
        break;
    }
  }

  // ─── Local-only Notifications ─────────────────────────────────────────────────

  Future<void> showLocalOnlyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          playSound: true,
        );
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

// Background Message Handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
  );

  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final title =
      message.notification?.title ??
      message.data['sender_name']?.toString() ??
      'New Message';
  final body =
      message.notification?.body ??
      message.data['text']?.toString() ??
      'Tap to view';
  final payloadId =
      message.data['chat_id'] ??
      message.data['lead_id'] ??
      message.data['vendor_id'];
  final type = message.data['type']?.toString() ?? 'chat';

  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  await localNotifications.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: payloadId != null ? '$type:$payloadId' : null,
  );
}
