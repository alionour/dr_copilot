import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

/// A use case class responsible for handling the login logic within the authentication feature.
///
/// This class encapsulates the business logic required to authenticate a user,
/// typically by interacting with a repository or data source.
///
/// Usage of this class promotes separation of concerns and makes the authentication
/// process more testable and maintainable.
class AuthUseCase {
  /// The repository responsible for handling authentication-related operations.
  ///
  /// This is an instance of [AbstractAuthRepository] that provides methods for user
  /// authentication, such as login, registration, and token management.
  final AbstractAuthRepository repository;

  /// Creates an instance of [AuthUseCase] with the required [repository].
  ///
  /// The [repository] parameter is used to handle authentication-related operations.
  AuthUseCase(this.repository);

  /// Authenticates a user with the provided [email] and [password].
  ///
  /// Returns a [Right(UserModel)] object if authentication is successful.
  /// Returns a [Left(Failure)] if authentication fails.
  Future<Either<Failure, UserModel?>> signInWithEmailAndPassword(
      String email, String password) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }

  /// Signs out the currently authenticated user.
  Future<Either<Failure, void>> signOut() async {
    return await repository.signOut();
  }

  /// Returns the current authenticated user, or null if not signed in.
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    return await repository.getCurrentUser();
  }

  /// Returns a stream of authentication state changes.
  Stream<UserModel?> authStateChanges() {
    return repository.authStateChanges();
  }

  /// Signs in the user using Google authentication.
  Future<Either<Failure, UserModel?>> signInWithGoogle() async {
    return await repository.signInWithGoogle();
  }

  /// Registers a new user with email and password.
  Future<Either<Failure, UserModel?>> signUpWithEmailAndPassword(
      String email, String password) async {
    return await repository.signUpWithEmailAndPassword(email, password);
  }

  /// Deletes the currently authenticated user.
  Future<Either<Failure, void>> deleteCurrentUser() async {
    return await repository.deleteCurrentUser();
  }

  /// Updates the current user's display name and/or photo URL.
  Future<Either<Failure, void>> updateProfile(
      {String? displayName, String? photoURL}) async {
    return await repository.updateProfile(
        displayName: displayName, photoURL: photoURL);
  }
}
