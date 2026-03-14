import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

class AuthRepository {
  final _storage = StorageService();
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _googleSignIn = gsi.GoogleSignIn.instance;

  AuthRepository() {
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is gsi.GoogleSignInAuthenticationEventSignIn) {
        _handleGoogleSignInResult(event.user);
      }
    });
  }

  Future<void> _handleGoogleSignInResult(gsi.GoogleSignInAccount account) async {
    try {
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return;

      final role = getUserRole() ?? 'CUSTOMER';
      final api = ApiService.instance;
      final result = await api.googleAuth(
        idToken: idToken,
        accountType: role,
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString('user_role', user['accountType'] ?? role.toUpperCase());
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }
    } catch (e) {
      // In a real app, you might want to expose this error via a stream
      print('Error in background Google Sign-In: $e');
    }
  }

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Current user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

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
      final onboardingCompleted = user['onboardingCompleted'] ?? true;
      await _storage.setString('onboarding_completed', onboardingCompleted.toString());
    } catch (e) {
      rethrow;
    }
  }

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
      await _storage.setString('user_role', user['accountType'] ?? role.toUpperCase());
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
    } catch (e) {
      rethrow;
    }
  }

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
      final result = await api.googleAuth(
        idToken: idToken,
        accountType: role,
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.setString('user_id', user['id']?.toString() ?? '');
      await _storage.setString('user_role', user['accountType'] ?? role.toUpperCase());
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
      if (user['image'] != null) {
        await _storage.setString('user_image', user['image']);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _storage.deleteToken();
    await _storage.remove('user_id');
    await _storage.remove('user_role');
    await _storage.remove('user_name');
    await _storage.remove('user_email');
    await _storage.remove('user_image');
    await _storage.remove('onboarding_completed');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

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
