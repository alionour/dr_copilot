import 'package:firebase_auth/firebase_auth.dart';

/// An abstract repository that defines authentication-related operations.
///
/// Implementations of this repository are responsible for handling user
/// authentication, registration, and session management within the application.
abstract class AuthRepository {
  /// Authenticates a user with the provided [email] and [password].
  ///
  /// Returns a [User] object if authentication is successful.
  ///
  /// Throws an [AuthException] if the login fails due to invalid credentials
  /// or other authentication errors.
  Future<User> loginWithEmailAndPassword(String email, String password);
}
