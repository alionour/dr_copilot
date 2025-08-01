import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package.dart';
import 'package:mockito/mockito.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthUseCase])
void main() {
  late AuthBloc authBloc;
  late MockAuthUseCase mockAuthUseCase;

  setUp(() {
    mockAuthUseCase = MockAuthUseCase();
    authBloc = AuthBloc(mockAuthUseCase);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final userModel = UserModel(uid: '123', email: 'test@test.com');

    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    group('SignInWithGoogle', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSignedIn] when signInWithGoogle is successful',
        build: () {
          when(mockAuthUseCase.signInWithGoogle())
              .thenAnswer((_) async => userModel);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogle()),
        expect: () => [
          AuthSignedIn(message: 'User signed in successfully', userId: userModel.uid),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when signInWithGoogle returns null',
        build: () {
          when(mockAuthUseCase.signInWithGoogle()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogle()),
        expect: () => [
          const AuthError(message: 'Google sign-in aborted'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when signInWithGoogle throws an exception',
        build: () {
          when(mockAuthUseCase.signInWithGoogle())
              .thenThrow(Exception('Something went wrong'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogle()),
        expect: () => [
          const AuthError(message: 'Exception: Something went wrong'),
        ],
      );
    });

    group('SignOutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSignedOut] when signOut is successful',
        build: () {
          when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => userModel);
          when(mockAuthUseCase.signOut()).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => [
          const AuthSignedOut(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when signOut throws an exception',
        build: () {
          when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => userModel);
          when(mockAuthUseCase.signOut()).thenThrow(Exception('Something went wrong'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => [
          const AuthError(message: 'Exception: Something went wrong'),
        ],
      );
    });

    test('userAuthenticationStream should call authStateChanges on the use case', () {
      when(mockAuthUseCase.authStateChanges()).thenAnswer((_) => Stream.value(userModel));

      authBloc.userAuthenticationStream();

      verify(mockAuthUseCase.authStateChanges());
      verifyNoMoreInteractions(mockAuthUseCase);
    });
  });
}
