import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';

class MockAuthFirebaseApi extends Mock implements AuthFirebaseApi {}

class MockUserModel extends Mock implements UserModel {}

void main() {
  late AuthRepositoryImpl authRepository;
  late MockAuthFirebaseApi mockApi;

  setUp(() {
    mockApi = MockAuthFirebaseApi();
    authRepository = AuthRepositoryImpl(mockApi);
  });

  group('AuthRepositoryImpl', () {
    final tUser = MockUserModel();
    final tEmail = 'test@example.com';
    final tPassword = 'password';

    test('signInWithEmailAndPassword calls api', () async {
      when(
        () => mockApi.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => tUser);

      final result = await authRepository.signInWithEmailAndPassword(
        tEmail,
        tPassword,
      );

      expect(result, Right(tUser));
      verify(
        () => mockApi.signInWithEmailAndPassword(tEmail, tPassword),
      ).called(1);
    });

    test('signOut calls api', () async {
      when(() => mockApi.signOut()).thenAnswer((_) async => {});

      final result = await authRepository.signOut();

      expect(result, const Right(null));
      verify(() => mockApi.signOut()).called(1);
    });

    test('getCurrentUser calls api', () async {
      when(() => mockApi.getCurrentUser()).thenAnswer((_) async => tUser);

      final result = await authRepository.getCurrentUser();

      expect(result, Right(tUser));
      verify(() => mockApi.getCurrentUser()).called(1);
    });

    test('authStateChanges calls api', () {
      final tStream = Stream.value(tUser);
      when(() => mockApi.authStateChanges()).thenAnswer((_) => tStream);

      final result = authRepository.authStateChanges();

      expect(result, emits(tUser));
      verify(() => mockApi.authStateChanges()).called(1);
    });

    test('signUpWithEmailAndPassword calls api', () async {
      when(
        () => mockApi.signUpWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => tUser);

      final result = await authRepository.signUpWithEmailAndPassword(
        tEmail,
        tPassword,
      );

      expect(result, Right(tUser));
      verify(
        () => mockApi.signUpWithEmailAndPassword(tEmail, tPassword),
      ).called(1);
    });
  });
}
