import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// An abstract repository that defines authentication-related operations.
///
/// Implementations of this repository are responsible for handling user
/// authentication, registration, and session management within the application.
abstract class AbstractAuthRepository {
  /// Authenticates a user with the provided [email] and [password].
  ///
  /// Returns a [User] object if authentication is successful.
  ///
  /// Throws an [AuthException] if the login fails due to invalid credentials
  /// or other authentication errors.
  Future<UserModel?> loginWithEmailAndPassword(String email, String password);

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Returns the current authenticated user, or null if not signed in.
  Future<UserModel?> getCurrentUser();

  /// Returns a stream of authentication state changes as UserModel.
  Stream<UserModel?> authStateChanges();

  /// Signs in the user using Google authentication.
  Future<UserModel?> signInWithGoogle();

  /// Registers a new user with email and password.
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password);

  /// Deletes the currently authenticated user.
  Future<void> deleteCurrentUser();

  /// Updates the current user's display name and/or photo URL.
  Future<void> updateProfile({String? displayName, String? photoURL});
}
