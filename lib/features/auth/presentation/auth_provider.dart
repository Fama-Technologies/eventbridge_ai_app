import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eventbridge_ai/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

@riverpod
Stream<firebase_auth.User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).logout(),
    );
  }

  Future<void> signup(
    String fullName,
    String email,
    String password, {
    String role = 'customer',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signup(fullName, email, password, role: role),
    );
  }

  Future<void> continueWithGoogle({String role = 'CUSTOMER'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).continueWithGoogle(role: role),
    );
  }

  Future<void> saveUserRole(String role) async {
    await ref.read(authRepositoryProvider).saveUserRole(role);
  }
}
