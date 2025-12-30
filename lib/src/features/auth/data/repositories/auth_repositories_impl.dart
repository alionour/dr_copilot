import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/error_handler.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';

/// Implementation of AbstractAuthRepository using AuthFirebaseApi
class AuthRepositoryImpl implements AbstractAuthRepository {
  final AuthFirebaseApi api;
  AuthRepositoryImpl(this.api);

  @override
  Future<Either<Failure, UserModel?>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final user = await api.signInWithEmailAndPassword(email, password);
      return Right(user);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await api.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    try {
      final user = await api.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return api.authStateChanges();
  }

  @override
  Future<Either<Failure, UserModel?>> signInWithGoogle() async {
    try {
      final user = await api.signInWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final user = await api.signUpWithEmailAndPassword(email, password);
      return Right(user);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCurrentUser() async {
    try {
      await api.deleteCurrentUser();
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(
      {String? displayName, String? photoURL}) async {
    try {
      await api.updateProfile(displayName: displayName, photoURL: photoURL);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.mapExceptionToFailure(e));
    }
  }
}
