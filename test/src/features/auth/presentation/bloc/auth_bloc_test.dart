import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignInHelper extends Mock implements GoogleSignInHelper {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late AuthBloc authBloc;
  late MockGoogleSignInHelper mockGoogleSignInHelper;

  setUp(() {
    mockGoogleSignInHelper = MockGoogleSignInHelper();
    authBloc = AuthBloc(); // Removed named parameter
  });

  tearDown(() {
    authBloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthSignedIn] when SignInWithGoogle is successful',
    build: () {
      when(() => mockGoogleSignInHelper.signIn())
          .thenAnswer((_) async => MockGoogleSignInAccount()); // Use a mock instance
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGoogle()),
    expect: () => [isA<AuthSignedIn>()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthError] when SignInWithGoogle fails',
    build: () {
      when(() => mockGoogleSignInHelper.signIn()).thenThrow(Exception('error'));
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGoogle()),
    expect: () => [isA<AuthError>()],
  );
}
