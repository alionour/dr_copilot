import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/core/services/fcm_service.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthUseCase extends Mock implements AuthUseCase {}

class MockFCMService extends Mock implements FCMService {}

class MockUserModel extends Mock implements UserModel {
  @override
  String get uid => 'test_uid';
}

void main() {
  late MockAuthUseCase mockAuthUseCase;
  late MockFCMService mockFCMService;

  setUp(() {
    mockAuthUseCase = MockAuthUseCase();
    mockFCMService = MockFCMService();

    // Setup GetIt for FCMService
    if (GetIt.instance.isRegistered<FCMService>()) {
      GetIt.instance.unregister<FCMService>();
    }
    GetIt.instance.registerSingleton<FCMService>(mockFCMService);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('AuthBloc', () {
    final tUser = MockUserModel();

    test('initial state is AuthInitial', () {
      expect(AuthBloc(mockAuthUseCase).state, AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSignedIn] when SignInWithEmailAndPassword is user is returned',
      build: () {
        when(
          () => mockAuthUseCase.signInWithEmailAndPassword(any(), any()),
        ).thenAnswer((_) async => tUser);
        when(
          () => mockFCMService.initialize(any()),
        ).thenAnswer((_) async => {});
        return AuthBloc(mockAuthUseCase);
      },
      act: (bloc) => bloc.add(
        const SignInWithEmailAndPassword(
          email: 'test@test.com',
          password: 'pass',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        AuthSignedIn(message: 'User signed in successfully', user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when SignInWithEmailAndPassword fails',
      build: () {
        when(
          () => mockAuthUseCase.signInWithEmailAndPassword(any(), any()),
        ).thenThrow(Exception('Login failed'));
        return AuthBloc(mockAuthUseCase);
      },
      act: (bloc) => bloc.add(
        const SignInWithEmailAndPassword(
          email: 'test@test.com',
          password: 'pass',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Exception: Login failed'),
      ],
    );

    // Note: SignOutEvent test is skipped due to static dependency on RoutingConfig.router
    // which cannot be easily mocked in this unit test setup without refactoring.
  });
}
