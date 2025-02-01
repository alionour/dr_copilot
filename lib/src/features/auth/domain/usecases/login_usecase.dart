
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<User> call(String email, String password) async {
    return await repository.login(email, password);
  }
}