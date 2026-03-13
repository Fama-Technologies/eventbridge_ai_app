import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final _storage = StorageService();
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

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
      await _storage.setString('user_role', user['accountType'] ?? 'CUSTOMER');
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
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
      await _storage.setString('user_role', user['accountType'] ?? role.toUpperCase());
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> continueWithGoogle({String role = 'CUSTOMER'}) async {
    try {
      // It is recommended to call initialize before using the instance.
      // We can call it here with nulls if no special config is needed.
      await _googleSignIn.initialize();
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
      await _storage.setString('user_role', user['accountType'] ?? role.toUpperCase());
      await _storage.setString('user_name', user['firstName'] ?? '');
      await _storage.setString('user_email', user['email'] ?? '');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _storage.deleteToken();
  }

  Future<void> saveUserRole(String role) async {
    await _storage.setString('user_role', role);
  }

  String? getUserRole() {
    return _storage.getString('user_role');
  }
}
