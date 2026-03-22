// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/auth/presentation/splash_screen.dart';
import 'package:eventbridge/features/auth/presentation/login_screen.dart';
import 'package:eventbridge/features/auth/presentation/role_selection_screen.dart';
import 'package:eventbridge/features/auth/presentation/create_account_screen.dart';
import 'package:eventbridge/features/auth/presentation/signup_screen.dart';
import 'package:eventbridge/features/auth/presentation/vendor_signup_screen.dart';
import 'package:eventbridge/features/auth/presentation/signup_success_screen.dart';
import 'package:eventbridge/features/auth/presentation/vendor_onboarding_screen.dart';
import 'package:eventbridge/features/auth/presentation/forgot_password_screen.dart';
import 'package:eventbridge/features/auth/presentation/verify_code_screen.dart';
import 'package:eventbridge/features/home/presentation/home_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_home_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_settings_screen.dart';
import 'package:eventbridge/features/home/presentation/customer_profile_screen.dart';
import 'package:eventbridge/features/matching/presentation/event_request_screen.dart';
import 'package:eventbridge/features/matching/presentation/match_results_screen.dart';
import 'package:eventbridge/features/matching/presentation/vendor_public_profile_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_main_screen.dart';
import 'package:eventbridge/features/vendors_screen/lead_details_screen.dart';
import 'package:eventbridge/features/vendors_screen/settings.dart';
import 'package:eventbridge/features/vendors_screen/vendor_chat_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_profile_settings.dart';
import 'package:eventbridge/features/vendors_screen/vendor_packages_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_availability_screen.dart';
import 'package:eventbridge/features/vendors_screen/subscription_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_personal_information_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_help_support_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_portfolio_screen.dart';
import 'package:eventbridge/features/vendors_screen/vendor_notifications_screen.dart';
import 'package:eventbridge/features/matching/presentation/submit_review_screen.dart';
import 'package:eventbridge/features/matching/presentation/match_intake_form_screen.dart';
import 'package:eventbridge/features/matching/presentation/ai_analyzing_screen.dart';
import 'package:eventbridge/features/messaging/presentation/customer_chats_screen.dart';
import 'package:eventbridge/features/messaging/presentation/customer_chat_detail_screen.dart';
import 'package:eventbridge/features/matching/presentation/ai_results_screen.dart';

// Routes that don't require authentication
const _publicRoutes = [
  '/',
  '/login',
  '/signup',
  '/create-account',
  '/vendor-signup',
  '/role-selection',
  '/forgot-password',
  '/verify-code',
  '/signup-success',
  '/login-success',
  '/vendor-signup-success',
];

// Routes reserved for Vendors
const _vendorOnlyRoutes = [
  '/vendor-home',
  '/vendor-onboarding',
  '/onboarding-success',
  '/lead-details',
  '/vendor-chat',
  '/vendor-settings',
  '/vendor-calendar',
  '/subscription',
  '/vendor-profile-settings',
  '/vendor-packages',
  '/vendor-personal-info',
  '/vendor-help-support',
  '/vendor-portfolio',
  '/vendor-notifications',
];

// Routes reserved for Customers
const _customerOnlyRoutes = [
  '/customer-home',
  '/customer-settings',
  '/customer-profile',
  '/home',
  '/matches',
  '/match-intake',
  '/ai-analyzing',
  '/ai-results',
  '/customer-chats',
  '/customer-chat',
  '/submit-review',
];

bool _isVendorRoute(String path) {
  return _vendorOnlyRoutes.any(
    (route) => path == route || path.startsWith('$route/'),
  );
}

bool _isCustomerRoute(String path) {
  return _customerOnlyRoutes.any(
    (route) => path == route || path.startsWith('$route/'),
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.matchedLocation;
    final isPublic = _publicRoutes.contains(path);

    final storage = StorageService();
    final token = await storage.getToken();
    final isLoggedIn = token != null && token.isNotEmpty;

    // 1. Handle Unauthenticated Users
    if (!isLoggedIn) {
      // If trying to access a protected route, go to login
      if (!isPublic) return '/login';
      return null;
    }

    // 2. Handle Authenticated Users
    final role = storage.getString('user_role');

    // If on public "getting started" pages, redirect to their role-based home
    if (path == '/' ||
        path == '/login' ||
        path == '/signup' ||
        path == '/role-selection') {
      if (role == 'VENDOR') {
        final onboarded = storage.getString('onboarding_completed');
        return onboarded == 'true' ? '/vendor-home' : '/vendor-onboarding';
      }
      return '/customer-home';
    }

    // 3. Enforce Role-Based Access Control (RBAC)
    if (role == 'VENDOR') {
      // Redirect un-onboarded vendors to onboarding
      final onboarded = storage.getString('onboarding_completed') == 'true';
      if (!onboarded && path != '/vendor-onboarding') {
        return '/vendor-onboarding';
      }
      
      // Vendors should not access customer-only routes
      if (_isCustomerRoute(path)) {
        return '/vendor-home';
      }
    } else if (role == 'CUSTOMER') {
      // Customers should not access vendor-only routes
      if (_isVendorRoute(path)) {
        return '/customer-home';
      }
    }

    return null; // All good, proceed
  },
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
      path: '/customer-profile',
      builder: (context, state) => const CustomerProfileScreen(),
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
      path: '/vendor-personal-info',
      builder: (context, state) => const VendorPersonalInformationScreen(),
    ),
    GoRoute(
      path: '/vendor-help-support',
      builder: (context, state) => const VendorHelpSupportScreen(),
    ),
    GoRoute(
      path: '/vendor-portfolio',
      builder: (context, state) => const VendorPortfolioScreen(),
    ),
    GoRoute(
      path: '/submit-review/:vendorId',
      builder: (context, state) {
        final id = state.pathParameters['vendorId']!;
        return SubmitReviewScreen(vendorId: id);
      },
    ),
    GoRoute(
      path: '/vendor-notifications',
      builder: (context, state) => const VendorNotificationsScreen(),
    ),
    GoRoute(
      path: '/match-intake',
      builder: (context, state) => const MatchIntakeFormScreen(),
    ),
    GoRoute(
      path: '/ai-analyzing',
      builder: (context, state) => const AiAnalyzingScreen(),
    ),
    GoRoute(
      path: '/ai-results',
      builder: (context, state) => const AiResultsScreen(),
    ),
    GoRoute(
      path: '/customer-chats',
      builder: (context, state) => const CustomerChatsScreen(),
    ),
    GoRoute(
      path: '/customer-chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomerChatDetailScreen(vendorId: id);
      },
    ),
  ],
);
