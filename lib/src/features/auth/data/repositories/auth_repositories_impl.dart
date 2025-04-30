import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';

/// Implementation of AbstractAuthRepository using AuthFirebaseApi
class AuthRepositoryImpl implements AbstractAuthRepository {
  final AuthFirebaseApi api;
  AuthRepositoryImpl(this.api);

  @override
  Future<UserModel?> loginWithEmailAndPassword(String email, String password) {
    return api.loginWithEmailAndPassword(email, password);
  }

  @override
  Future<void> signOut() {
    return api.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() {
    return api.getCurrentUser();
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return api.authStateChanges();
  }

  @override
  Future<UserModel?> signInWithGoogle() {
    return api.signInWithGoogle();
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password) {
    return api.signUpWithEmailAndPassword(email, password);
  }

  @override
  Future<void> deleteCurrentUser() {
    return api.deleteCurrentUser();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) {
    return api.updateProfile(displayName: displayName, photoURL: photoURL);
  }
}
