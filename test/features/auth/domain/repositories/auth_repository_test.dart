import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class FakeAuthRepository implements AbstractAuthRepository {
  @override
  Future<UserModel?> loginWithEmailAndPassword(
          String email, String password) async =>
      UserModel(uid: '1');
  @override
  Future<void> signOut() async {}
  @override
  Future<UserModel?> signInWithGoogle() async => UserModel(uid: '2');
  @override
  Future<UserModel?> signUpWithEmailAndPassword(
          String email, String password) async =>
      UserModel(uid: '3');
  @override
  Future<void> deleteCurrentUser() async {}
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Stream<UserModel?> authStateChanges() => Stream.value(UserModel(uid: '1'));
}

void main() {
  test('FakeAuthRepository returns user for login', () async {
    final repo = FakeAuthRepository();
    final user = await repo.loginWithEmailAndPassword('a@b.com', 'pass');
    expect(user, isA<UserModel>());
  });
}
