import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eventbridge/core/theme/app_theme.dart';
import 'package:eventbridge/core/router/app_router.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.init();

  // Initialize Google Sign-In early so renderButton() works on web
  await GoogleSignIn.instance.initialize(
    clientId: '210290711848-9vlffn2n1bigsvoi24ieuklj2nmivc6j.apps.googleusercontent.com',
  );

  // Initialize Notifications
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await NotificationService().init();

  runApp(const ProviderScope(child: EventBridgeApp()));
}

class EventBridgeApp extends StatelessWidget {
  const EventBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EventBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
