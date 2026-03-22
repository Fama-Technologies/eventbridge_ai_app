import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/router/app_router.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Notifications not supported on Web, skipping init.');
      return;
    }
    // 1. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Setup Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got message in foreground');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 4. Handle Notification Clicks (Application opened from terminated or background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked! ${message.data}');
      final type = message.data['type'];
      final id = message.data['chat_id'] ?? message.data['lead_id'] ?? message.data['vendor_id'];
      if (id != null) {
        _handleNavigation(id, type: type);
      }
    });

    // 5. Get initial token
    updateToken();

    // 6. Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) => _saveTokenToBackend(token));
  }

  Future<void> updateToken() async {
    if (kIsWeb) return; // Cannot get FCM token on Web without SW and vapidKey
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    final storage = StorageService();
    final userId = storage.getString('user_id');
    if (userId == null) return;

    // Avoid redundant updates
    final savedToken = storage.getString('fcm_token');
    if (savedToken == token) return;

    try {
      final success = await ApiService.instance.updateFcmToken(userId, token);
      if (success) {
        await storage.setString('fcm_token', token);
        debugPrint('FCM Token synced successfully');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = message.data['type'] ?? 'message';
    final payload = message.data['chat_id'] ?? message.data['lead_id'] ?? message.data['vendor_id'];

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: payload != null ? '$type:$payload' : null,
    );
  }

  void _handleNavigation(String payload, {String? type}) {
    String navType = type ?? 'message';
    String id = payload;

    if (payload.contains(':')) {
      final parts = payload.split(':');
      navType = parts[0];
      id = parts[1];
    }

    debugPrint('Navigating to $navType with ID: $id');

    switch (navType) {
      case 'message':
      case 'chat':
        appRouter.push('/customer-chat/$id');
        break;
      case 'lead':
        appRouter.push('/lead-details/$id');
        break;
      case 'vendor':
        appRouter.push('/vendor-public/$id');
        break;
      case 'settings':
        final role = StorageService().getString('user_role');
        appRouter.push(role == 'VENDOR' ? '/vendor-settings' : '/customer-settings');
        break;
    }
  }

  // Helper for triggering local-only notifications (e.g. settings updated)
  Future<void> showLocalOnlyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // flutter_local_notifications not fully supported on web

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
    );
    final NotificationDetails details = NotificationDetails(android: androidDetails);

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
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}
