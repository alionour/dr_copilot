import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A use case class responsible for handling the login logic within the authentication feature.
///
/// This class encapsulates the business logic required to authenticate a user,
/// typically by interacting with a repository or data source.
///
/// Usage of this class promotes separation of concerns and makes the authentication
/// process more testable and maintainable.
class LoginUseCase {
  /// The repository responsible for handling authentication-related operations.
  ///
  /// This is an instance of [AuthRepository] that provides methods for user
  /// authentication, such as login, registration, and token management.
  final AuthRepository repository;

  /// Creates an instance of [LoginUseCase] with the required [repository].
  ///
  /// The [repository] parameter is used to handle authentication-related operations.
  LoginUseCase({required this.repository});

  /// Authenticates a user with the provided [email] and [password].
  ///
  /// Returns a [User] object if authentication is successful.
  ///
  /// Throws an exception if authentication fails.
  Future<User> loginWithEmailAndPassword(String email, String password) async {
    return await repository.loginWithEmailAndPassword(email, password);
  }
}
