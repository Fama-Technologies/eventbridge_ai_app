// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/features/auth/presentation/splash_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/login_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/role_selection_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/create_account_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/signup_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/vendor_signup_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/signup_success_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/vendor_onboarding_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:eventbridge_ai/features/auth/presentation/verify_code_screen.dart';
import 'package:eventbridge_ai/features/home/presentation/home_screen.dart';
import 'package:eventbridge_ai/features/home/presentation/customer_home_screen.dart';
import 'package:eventbridge_ai/features/home/presentation/customer_settings_screen.dart';
import 'package:eventbridge_ai/features/matching/presentation/event_request_screen.dart';
import 'package:eventbridge_ai/features/matching/presentation/match_results_screen.dart';
import 'package:eventbridge_ai/features/matching/presentation/vendor_public_profile_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_main_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/lead_details_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/settings.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_chat_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_profile_settings.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_packages_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/vendor_availability_screen.dart';
import 'package:eventbridge_ai/features/vendors_screen/subscription_screen.dart';
import 'package:eventbridge_ai/features/matching/presentation/submit_review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/vendor-signup',
      builder: (context, state) => const VendorSignupScreen(),
    ),
    GoRoute(
      path: '/signup-success',
      builder: (context, state) => const SignupSuccessScreen(
        title: 'Account Created',
        message:
            'Your profile is ready. You can now continue into EventBridge and start exploring.',
        nextRoute: '/customer-home',
      ),
    ),
    GoRoute(
      path: '/login-success',
      builder: (context, state) => const SignupSuccessScreen(
        title: 'Login Successful',
        message: 'Welcome back! You are now logged in to EventBridge.',
        nextRoute: '/home',
      ),
    ),
    GoRoute(
      path: '/vendor-signup-success',
      builder: (context, state) => const SignupSuccessScreen(
        title: 'Vendor Account Ready',
        message:
            'Your vendor profile was created successfully. Continue to finish onboarding and set up your business.',
        nextRoute: '/vendor-onboarding',
      ),
    ),
    GoRoute(
      path: '/onboarding-success',
      builder: (context, state) => const SignupSuccessScreen(
        title: 'Onboarding Complete',
        message:
            'Your business profile is fully set up. You can now start receiving leads.',
        nextRoute: '/vendor-home',
      ),
    ),
    GoRoute(
      path: '/vendor-onboarding',
      builder: (context, state) => const VendorOnboardingScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-code',
      builder: (context, state) => const VerifyCodeScreen(),
    ),
    GoRoute(
      path: '/customer-home',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/customer-settings',
      builder: (context, state) => const CustomerSettingsScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const EventRequestScreen(),
    ),
    GoRoute(
      path: '/legacy-home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => const MatchResultsScreen(),
    ),
    GoRoute(
      path: '/vendor-public/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return VendorPublicProfileScreen(vendorId: id);
      },
    ),
    GoRoute(
      path: '/vendor-home',
      builder: (context, state) => const VendorMainScreen(),
    ),
    GoRoute(
      path: '/lead-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LeadDetailsScreen(leadId: id);
      },
    ),
    GoRoute(
      path: '/vendor-chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return VendorChatScreen(leadId: id);
      },
    ),
    GoRoute(
      path: '/vendor-settings',
      builder: (context, state) => const VendorSettingsScreen(),
    ),
    GoRoute(
      path: '/vendor-calendar',
      builder: (context, state) => const VendorAvailabilityScreen(),
    ),
    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/vendor-profile-settings',
      builder: (context, state) => const VendorProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/vendor-packages',
      builder: (context, state) => const VendorPackagesScreen(),
    ),
    GoRoute(
      path: '/submit-review/:vendorId',
      builder: (context, state) {
        final id = state.pathParameters['vendorId']!;
        return SubmitReviewScreen(vendorId: id);
      },
    ),
  ],
);
