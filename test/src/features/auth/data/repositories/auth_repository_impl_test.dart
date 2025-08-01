import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthFirebaseApi])
void main() {
  late AuthRepositoryImpl authRepository;
  late MockAuthFirebaseApi mockAuthFirebaseApi;

  setUp(() {
    mockAuthFirebaseApi = MockAuthFirebaseApi();
    authRepository = AuthRepositoryImpl(mockAuthFirebaseApi);
  });

  group('AuthRepositoryImpl', () {
    final userModel = UserModel(uid: '123', email: 'test@test.com');
    const email = 'test@test.com';
    const password = 'password';

    test('should call loginWithEmailAndPassword on the api', () async {
      when(mockAuthFirebaseApi.loginWithEmailAndPassword(email, password))
          .thenAnswer((_) async => userModel);

      final result = await authRepository.loginWithEmailAndPassword(email, password);

      expect(result, userModel);
      verify(mockAuthFirebaseApi.loginWithEmailAndPassword(email, password));
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call signOut on the api', () async {
      when(mockAuthFirebaseApi.signOut()).thenAnswer((_) async => {});

      await authRepository.signOut();

      verify(mockAuthFirebaseApi.signOut());
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call getCurrentUser on the api', () async {
      when(mockAuthFirebaseApi.getCurrentUser()).thenAnswer((_) async => userModel);

      final result = await authRepository.getCurrentUser();

      expect(result, userModel);
      verify(mockAuthFirebaseApi.getCurrentUser());
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call authStateChanges on the api', () {
      when(mockAuthFirebaseApi.authStateChanges()).thenAnswer((_) => Stream.value(userModel));

      final result = authRepository.authStateChanges();

      expect(result, isA<Stream<UserModel?>>());
      verify(mockAuthFirebaseApi.authStateChanges());
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call signInWithGoogle on the api', () async {
      when(mockAuthFirebaseApi.signInWithGoogle()).thenAnswer((_) async => userModel);

      final result = await authRepository.signInWithGoogle();

      expect(result, userModel);
      verify(mockAuthFirebaseApi.signInWithGoogle());
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call signUpWithEmailAndPassword on the api', () async {
      when(mockAuthFirebaseApi.signUpWithEmailAndPassword(email, password))
          .thenAnswer((_) async => userModel);

      final result = await authRepository.signUpWithEmailAndPassword(email, password);

      expect(result, userModel);
      verify(mockAuthFirebaseApi.signUpWithEmailAndPassword(email, password));
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call deleteCurrentUser on the api', () async {
      when(mockAuthFirebaseApi.deleteCurrentUser()).thenAnswer((_) async => {});

      await authRepository.deleteCurrentUser();

      verify(mockAuthFirebaseApi.deleteCurrentUser());
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });

    test('should call updateProfile on the api', () async {
      const displayName = 'Test';
      const photoURL = 'http://test.com/test.jpg';
      when(mockAuthFirebaseApi.updateProfile(displayName: displayName, photoURL: photoURL))
          .thenAnswer((_) async => {});

      await authRepository.updateProfile(displayName: displayName, photoURL: photoURL);

      verify(mockAuthFirebaseApi.updateProfile(displayName: displayName, photoURL: photoURL));
      verifyNoMoreInteractions(mockAuthFirebaseApi);
    });
  });
}
