import 'package:eventbridge/features/auth/domain/repositories/i_auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call(String email, String password) {
    return _repository.login(email, password);
  }
}

class LogoutUseCase {
  LogoutUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call() {
    return _repository.logout();
  }
}

class SignupUseCase {
  SignupUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call(
    String fullName,
    String email,
    String password, {
    String role = 'customer',
  }) {
    return _repository.signup(fullName, email, password, role: role);
  }
}

class ContinueWithGoogleUseCase {
  ContinueWithGoogleUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call({String role = 'CUSTOMER'}) {
    return _repository.continueWithGoogle(role: role);
  }
}

class SaveUserRoleUseCase {
  SaveUserRoleUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call(String role) {
    return _repository.saveUserRole(role);
  }
}