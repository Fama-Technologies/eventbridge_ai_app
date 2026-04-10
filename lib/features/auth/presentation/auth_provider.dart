import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:eventbridge/features/auth/presentation/auth_di.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

@riverpod
Stream<firebase_auth.User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryContractProvider).authStateChanges;
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
      () => ref.read(loginUseCaseProvider)(email, password),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(logoutUseCaseProvider)(),
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
      () => ref.read(signupUseCaseProvider)(
        fullName,
        email,
        password,
        role: role,
          ),
    );
  }

  Future<void> continueWithGoogle({String role = 'CUSTOMER'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(continueWithGoogleUseCaseProvider)(role: role),
    );
  }

  Future<void> saveUserRole(String role) async {
    await ref.read(saveUserRoleUseCaseProvider)(role);
  }
}
