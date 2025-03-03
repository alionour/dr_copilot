import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<User> call(String email, String password) async {
    return await repository.login(email, password);
  }
}
