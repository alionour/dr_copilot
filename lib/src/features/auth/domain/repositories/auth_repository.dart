import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

/// An abstract repository that defines authentication-related operations.
///
/// Implementations of this repository are responsible for handling user
/// authentication, registration, and session management within the application.
abstract class AbstractAuthRepository {
  /// Authenticates a user with the provided [email] and [password].
  ///
  /// Returns a [Right(User)] object if authentication is successful.
  /// Returns a [Left(Failure)] if the login fails.
  Future<Either<Failure, UserModel?>> signInWithEmailAndPassword(
      String email, String password);

  /// Signs out the currently authenticated user.
  Future<Either<Failure, void>> signOut();

  /// Returns the current authenticated user, or null if not signed in.
  Future<Either<Failure, UserModel?>> getCurrentUser();

  /// Returns a stream of authentication state changes as UserModel.
  Stream<UserModel?> authStateChanges();

  /// Signs in the user using Google authentication.
  Future<Either<Failure, UserModel?>> signInWithGoogle();

  /// Registers a new user with email and password.
  Future<Either<Failure, UserModel?>> signUpWithEmailAndPassword(
      String email, String password);

  /// Deletes the currently authenticated user.
  Future<Either<Failure, void>> deleteCurrentUser();

  /// Updates the current user's display name and/or photo URL.
  Future<Either<Failure, void>> updateProfile(
      {String? displayName, String? photoURL});

  /// Checks if a user with the given [email] already exists in the system.
  Future<Either<Failure, bool>> doesUserExist(String email);

  /// Manually creates a clinic for the current user.
  Future<Either<Failure, void>> createClinicForUser(String clinicName);

  /// Manually accepts an invitation for the current user.
  Future<Either<Failure, void>> acceptInvitationForUser(String invitationId);
}
