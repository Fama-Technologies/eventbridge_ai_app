import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class IAuthRepository {
  Stream<firebase_auth.User?> get authStateChanges;

  Future<void> login(String email, String password);

  Future<void> logout();

  Future<void> signup(
    String fullName,
    String email,
    String password, {
    String role = 'customer',
  });

  Future<void> continueWithGoogle({String role = 'CUSTOMER'});

  Future<void> saveUserRole(String role);
}