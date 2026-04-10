import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eventbridge/core/theme/app_theme.dart';
import 'package:eventbridge/core/router/app_router.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/services/notification_service.dart';
import 'package:eventbridge/core/widgets/auth_uid_debug_banner.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eventbridge/core/network/network_status_provider.dart';
import 'package:eventbridge/features/shared/screens/offline_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check to secure Firebase services and remove missing provider warnings
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.init();

  // Initialize Google Sign-In early so renderButton() works on web
  await GoogleSignIn.instance.initialize(
    clientId:
        '210290711848-9vlffn2n1bigsvoi24ieuklj2nmivc6j.apps.googleusercontent.com',
  );

  // Initialize Notifications
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Wire the hook so NotificationService can re-run the custom-token
  // restore flow when it detects a Firebase uid / backend user_id mismatch
  // during FCM token sync. Without this hook, a lost Firebase Auth session
  // silently disables push notifications until the next login.
  NotificationService.firebaseAuthRestoreHook =
      () => AuthRepository().restoreFirebaseMessagingAuthIfNeeded();

  try {
    await AuthRepository().restoreFirebaseMessagingAuthIfNeeded();
  } catch (e, stack) {
    // Startup must stay resilient, but NEVER silently swallow this —
    // a failure here means Firebase Auth uid != backend user_id, which
    // makes every Firestore message write fail the security rule
    // `senderId == request.auth.uid` and causes the Cloud Function
    // onMessageCreate to find no notificationTokens/{uid} doc, so push
    // notifications stop firing. See notification_service.dart and
    // firestore.rules.
    debugPrint(
      '🚨 [main] restoreFirebaseMessagingAuthIfNeeded FAILED: $e\n$stack',
    );
  }
  await NotificationService().init();

  runApp(const ProviderScope(child: EventBridgeApp()));
}

class EventBridgeApp extends ConsumerWidget {
  const EventBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return MaterialApp.router(
      title: 'EventBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        // Wrap with debug banner first
        Widget mainContent = AuthUidDebugBanner(child: child);

        // Then layer the offline screen if needed
        return Stack(
          children: [
            mainContent,
            if (networkStatus.value == NetworkStatus.offline)
              const Positioned.fill(
                child: Material(
                  child: OfflineScreen(),
                ),
              ),
          ],
        );
      },
    );
  }
}
