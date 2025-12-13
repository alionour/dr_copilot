import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('LoginPage renders and handles Google Sign In', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify key elements are present by Key
    final googleButton = find.byKey(const Key('google_sign_in_button'));
    expect(googleButton, findsOneWidget);

    // Tap the button
    await tester.tap(googleButton);
    await tester.pump();

    // Verify event added
    verify(() => mockAuthBloc.add(SignInWithGoogle())).called(1);
  });
}
