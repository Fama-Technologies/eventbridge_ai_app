import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/features/auth/presentation/splash_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/onboarding_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/login_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/role_selection_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/create_account_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/signup_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/vendor_signup_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/vendor_onboarding_screen.dart';
import 'package:eventbridge_ai/features/home/presentation/home_screen.dart';
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
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/vendor-signup',
      builder: (context, state) => const VendorSignupScreen(),
    ),
    GoRoute(
      path: '/vendor-onboarding',
      builder: (context, state) => const VendorOnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
