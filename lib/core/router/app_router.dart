import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/features/auth/presentation/splash_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/onboarding_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/login_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/signup_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
  ],
);
