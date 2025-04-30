
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthFirebaseApi extends Mock implements AuthFirebaseApi {}

class MockFirebaseUser extends Mock implements User {}

void main() {
  late MockAuthFirebaseApi mockApi;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockApi = MockAuthFirebaseApi();
    repository = AuthRepositoryImpl(mockApi);
  });

  test('loginWithEmailAndPassword calls api and returns user', () async {
    final user = UserModel(uid: '123');
    when(mockApi.loginWithEmailAndPassword('a@b.com', 'pass'))
        .thenAnswer((_) async => user);
    final result =
        await repository.loginWithEmailAndPassword('a@b.com', 'pass');
    expect(result, user);
    verify(mockApi.loginWithEmailAndPassword('a@b.com', 'pass')).called(1);
  });

  test('signOut calls api', () async {
    when(mockApi.signOut()).thenAnswer((_) async {});
    await repository.signOut();
    verify(mockApi.signOut()).called(1);
  });

  test('getCurrentUser calls api and returns user', () async {
    final userModel = UserModel(uid: '999');
    when(mockApi.getCurrentUser()).thenAnswer((_) async => userModel);
    final result = await repository.getCurrentUser();
    expect(result, userModel);
    verify(mockApi.getCurrentUser()).called(1);
  });

  test('authStateChanges calls api and returns stream', () async {
    final userModel = UserModel(uid: '456');
    final stream = Stream<UserModel?>.value(userModel);
    when(mockApi.authStateChanges()).thenAnswer((_) => stream);
    final result = repository.authStateChanges();
    expect(await result.first, userModel);
    verify(mockApi.authStateChanges()).called(1);
  });

  test('signInWithGoogle calls api and returns user', () async {
    final user = UserModel(uid: '789');
    when(mockApi.signInWithGoogle()).thenAnswer((_) async => user);
    final result = await repository.signInWithGoogle();
    expect(result, user);
    verify(mockApi.signInWithGoogle()).called(1);
  });

  test('signUpWithEmailAndPassword calls api and returns user', () async {
    final user = UserModel(uid: 'abc');
    when(mockApi.signUpWithEmailAndPassword('x@y.com', 'secret'))
        .thenAnswer((_) async => user);
    final result =
        await repository.signUpWithEmailAndPassword('x@y.com', 'secret');
    expect(result, user);
    verify(mockApi.signUpWithEmailAndPassword('x@y.com', 'secret')).called(1);
  });

  test('deleteCurrentUser calls api', () async {
    when(mockApi.deleteCurrentUser()).thenAnswer((_) async {});
    await repository.deleteCurrentUser();
    verify(mockApi.deleteCurrentUser()).called(1);
  });

  test('updateProfile calls api with correct params', () async {
    when(mockApi.updateProfile(displayName: 'Ali', photoURL: 'url'))
        .thenAnswer((_) async {});
    await repository.updateProfile(displayName: 'Ali', photoURL: 'url');
    verify(mockApi.updateProfile(displayName: 'Ali', photoURL: 'url')).called(1);
  });
}
