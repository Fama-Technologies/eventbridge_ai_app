import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eventbridge/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:eventbridge/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';

final authRepositoryContractProvider = Provider<IAuthRepository>((ref) {
  return ref.watch(authRepositoryProvider);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryContractProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryContractProvider));
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(ref.watch(authRepositoryContractProvider));
});

final continueWithGoogleUseCaseProvider = Provider<ContinueWithGoogleUseCase>((ref) {
  return ContinueWithGoogleUseCase(ref.watch(authRepositoryContractProvider));
});

final saveUserRoleUseCaseProvider = Provider<SaveUserRoleUseCase>((ref) {
  return SaveUserRoleUseCase(ref.watch(authRepositoryContractProvider));
});