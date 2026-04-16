import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/services/notification_service.dart';
import 'package:eventbridge/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

class AuthRepository implements IAuthRepository {
  final _storage = StorageService();
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _googleSignIn = gsi.GoogleSignIn.instance;

  AuthRepository() {
    // The authentication-events listener only matters on Web, where
    // `continueWithGoogle()` delegates to `renderButton` /
    // `attemptLightweightAuthentication` and the sign-in completion arrives
    // asynchronously via this stream. On mobile, `continueWithGoogle()`
    // handles the backend exchange directly — registering the listener on
    // mobile would double-post /api/auth/google (once manually, once via
    // the event) and triple-post if the repository is ever re-instantiated.
    if (kIsWeb) {
      _googleSignIn.authenticationEvents.listen((event) {
        if (event is gsi.GoogleSignInAuthenticationEventSignIn) {
          _handleGoogleSignInResult(event.user);
        }
      });
    }
  }

  String get _firebaseCustomTokenUrl =>
      'https://us-central1-eventbridge-483019.cloudfunctions.net/createFirebaseCustomToken';

  Future<void> _signInToFirebaseMessagingUser({
    required Map<String, dynamic> user,
    String? fallbackEmail,
    String? fallbackRole,
  }) async {
    final userId = user['id']?.toString() ?? '';
    if (userId.isEmpty) return;

    if (_firebaseAuth.currentUser?.uid == userId) {
      debugPrint(
        'Firebase messaging auth already aligned for backend user $userId.',
      );
      return;
    }

    if (_firebaseAuth.currentUser != null) {
      debugPrint(
        'Switching Firebase messaging auth from ${_firebaseAuth.currentUser?.uid} to backend user $userId.',
      );
      await _firebaseAuth.signOut();
    }

    final backendToken = await _storage.getToken();
    final email =
        user['email']?.toString() ??
        fallbackEmail ??
        '$userId@eventbridge.local';
    final role = user['accountType']?.toString() ?? fallbackRole ?? 'CUSTOMER';
    final name =
        user['firstName']?.toString() ?? _storage.getString('user_name') ?? '';

    try {
      final response = await Dio().post(
        _firebaseCustomTokenUrl,
        data: {'userId': userId, 'email': email, 'name': name, 'role': role},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            if (backendToken != null && backendToken.isNotEmpty)
              'Authorization': 'Bearer $backendToken',
          },
        ),
      );

      final customToken = response.data['customToken']?.toString();
      if (customToken == null || customToken.isEmpty) {
        throw Exception('[Auth] Firebase custom token missing: ${response.data}');
      }

      await _firebaseAuth
          .signInWithCustomToken(customToken)
          .timeout(const Duration(seconds: 10));
      debugPrint('Firebase messaging auth restored for backend user $userId.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?.toString();
      throw Exception(
        '[Auth] Custom token request failed ($status): ${msg ?? e.message}',
      );
    } catch (e) {
      throw Exception('[Auth] Failed to sign in to Firebase: $e');
    }
  }

  Future<void> restoreFirebaseMessagingAuthIfNeeded() async {
    final token = await _storage.getToken();
    final userId = _storage.getString('user_id');

    debugPrint('[Auth] Checking restoration: userId=$userId, firebaseUid=${_firebaseAuth.currentUser?.uid}');

    if (token == null ||
        token.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        _firebaseAuth.currentUser?.uid == userId) {
      return;
    }

    await forceRestoreFirebaseSession();
  }

  /// Forcefully restores the Firebase session by requesting a new custom token.
  /// Useful for manual "Fix" triggers or when the app detects a mismatch.
  Future<void> forceRestoreFirebaseSession() async {
    final userId = _storage.getString('user_id');
    if (userId == null || userId.isEmpty) return;

    final email =
        _storage.getString('user_email') ?? '$userId@eventbridge.local';
    final name = _storage.getString('user_name') ?? '';
    final role = _storage.getString('user_role') ?? 'CUSTOMER';

    debugPrint('[Auth] FORCING restoration for backend user $userId...');

    try {
      await _signInToFirebaseMessagingUser(
        user: {
          'id': userId,
          'email': email,
          'firstName': name,
          'accountType': role,
        },
        fallbackEmail: email,
        fallbackRole: role,
      );
      await NotificationService().updateToken();
      debugPrint('[Auth] Force restore SUCCESSFUL for $userId');
    } catch (e) {
      debugPrint('[Auth] CRITICAL: forceRestoreFirebaseSession failed: $e');
      rethrow;
    }
  }

  Future<void> _handleGoogleSignInResult(
    gsi.GoogleSignInAccount account,
  ) async {
    try {
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return;

      final role = getUserRole() ?? 'CUSTOMER';
      final api = ApiService.instance;
      final result = await api.googleAuth(idToken: idToken, accountType: role);

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString(
        'user_role',
        user['accountType'] ?? role.toUpperCase(),
      );
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }

      // Save vendor onboarding status
      final accountType = user['accountType'] ?? role.toUpperCase();
      final onboardingCompleted =
          user['onboardingCompleted'] ??
          (accountType == 'VENDOR' ? false : true);
      await _storage.setString(
        'onboarding_completed',
        onboardingCompleted.toString(),
      );

      await _signInToFirebaseMessagingUser(
        user: user,
        fallbackRole: role.toUpperCase(),
      );

      // Sync FCM Token
      await NotificationService().updateToken();
    } catch (e) {
      debugPrint('Error in background Google Sign-In: $e');
    }
  }

  // Stream of auth state changes
  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Current user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> login(String email, String password) async {
    try {
      final api = ApiService.instance;
      final result = await api.login(email, password);

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString('user_role', user['accountType'] ?? 'CUSTOMER');
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }
      // Save vendor onboarding status
      final accountType = user['accountType'] ?? 'CUSTOMER';
      final onboardingCompleted =
          user['onboardingCompleted'] ??
          (accountType == 'VENDOR' ? false : true);
      await _storage.setString(
        'onboarding_completed',
        onboardingCompleted.toString(),
      );

      // Save vendor verification status
      final verificationStatus = user['verificationStatus'] ?? 'not_submitted';
      await _storage.setString('verification_status', verificationStatus);

      await _signInToFirebaseMessagingUser(user: user);

      // Sync FCM Token
      await NotificationService().updateToken();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signup(
    String fullName,
    String email,
    String password, {
    String role = 'customer',
  }) async {
    try {
      final api = ApiService.instance;
      final result = await api.signup(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString(
        'user_role',
        user['accountType'] ?? role.toUpperCase(),
      );
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }
      // New vendor hasn't completed onboarding yet
      if (role.toUpperCase() == 'VENDOR') {
        await _storage.setString('onboarding_completed', 'false');
      } else {
        await _storage.setString('onboarding_completed', 'true');
      }

      await _signInToFirebaseMessagingUser(
        user: user,
        fallbackEmail: email,
        fallbackRole: role.toUpperCase(),
      );

      // Sync FCM Token
      await NotificationService().updateToken();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> continueWithGoogle({String role = 'CUSTOMER'}) async {
    try {
      // Save role so it's available to our listener
      await saveUserRole(role);

      if (kIsWeb) {
        // On Web, authenticate() is unimplemented.
        // We rely on renderButton and the authenticationEvents listener.
        await _googleSignIn.attemptLightweightAuthentication();
        return;
      }

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to obtain Google ID Token.');
      }

      final api = ApiService.instance;
      final result = await api.googleAuth(idToken: idToken, accountType: role);

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString(
        'user_role',
        user['accountType'] ?? role.toUpperCase(),
      );
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }

      // Save vendor onboarding status
      final accountType = user['accountType'] ?? role.toUpperCase();
      final onboardingCompleted =
          user['onboardingCompleted'] ??
          (accountType == 'VENDOR' ? false : true);
      await _storage.setString(
        'onboarding_completed',
        onboardingCompleted.toString(),
      );

      // Save vendor verification status
      final verificationStatus = user['verificationStatus'] ?? 'not_submitted';
      await _storage.setString('verification_status', verificationStatus);

      await _signInToFirebaseMessagingUser(
        user: user,
        fallbackRole: role.toUpperCase(),
      );

      // Sync FCM Token
      await NotificationService().updateToken();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // Clear local storage FIRST so Riverpod providers that depend on
    // user_id will invalidate and tear down Firestore listeners before
    // we revoke the Firebase Auth session.  This prevents the
    // PERMISSION_DENIED errors from orphaned Firestore queries.
    await _storage.deleteToken();
    await _storage.remove('user_id');
    await _storage.remove('user_role');
    await _storage.remove('user_name');
    await _storage.remove('user_email');
    await _storage.remove('user_image');
    await _storage.remove('onboarding_completed');
    await _storage.remove('verification_status');

    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Firebase signout error: $e');
    }

    try {
      if (kIsWeb) {
        await _googleSignIn.disconnect();
      } else {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google signout error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveUserRole(String role) async {
    await _storage.setString('user_role', role);
  }

  String? getUserRole() {
    return _storage.getString('user_role');
  }

  String? getUserId() {
    return _storage.getString('user_id');
  }

  String? getUserName() {
    return _storage.getString('user_name');
  }

  String? getUserEmail() {
    return _storage.getString('user_email');
  }

  String? getUserImage() {
    return _storage.getString('user_image');
  }

  bool isOnboardingCompleted() {
    final val = _storage.getString('onboarding_completed');
    return val == 'true';
  }

  Future<void> setOnboardingCompleted() async {
    await _storage.setString('onboarding_completed', 'true');
  }
}
