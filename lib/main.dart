import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eventbridge_ai/core/theme/app_theme.dart';
import 'package:eventbridge_ai/core/router/app_router.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.init();

  // Initialize Google Sign-In early so renderButton() works on web
  await GoogleSignIn.instance.initialize(
    clientId: '185107161336-540qvqk8m94p5384rr6f47c4nmb18gd0.apps.googleusercontent.com',
  );

  runApp(const ProviderScope(child: EventBridgeApp()));
}

class EventBridgeApp extends StatelessWidget {
  const EventBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EventBridge AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
