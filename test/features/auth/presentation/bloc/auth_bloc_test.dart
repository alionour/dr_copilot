import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late MockAuthUseCase mockUseCase;
  late AuthBloc bloc;

  setUp(() {
    mockUseCase = MockAuthUseCase();
    bloc = AuthBloc(mockUseCase);
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthSignedIn] when SignInWithGoogle succeeds',
    build: () {
      when(mockUseCase.signInWithGoogle())
          .thenAnswer((_) async => UserModel(uid: '1'));
      return bloc;
    },
    act: (bloc) => bloc.add(const SignInWithGoogle()),
    expect: () => [isA<AuthSignedIn>()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthError] when SignInWithGoogle fails',
    build: () {
      when(mockUseCase.signInWithGoogle()).thenThrow(Exception('fail'));
      return bloc;
    },
    act: (bloc) => bloc.add(const SignInWithGoogle()),
    expect: () => [isA<AuthError>()],
  );
}
