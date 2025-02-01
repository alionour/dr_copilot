
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
}