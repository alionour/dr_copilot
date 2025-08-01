import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

import 'login_page_test.mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

@GenerateMocks([AuthBloc])
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

  group('LoginPage', () {
    final userModel = UserModel(uid: '123', email: 'test@test.com');

    testWidgets('renders correctly when user is not signed in', (widgetTester) async {
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.fromIterable([]),
        initialState: const AuthInitial(),
      );
      when(mockAuthBloc.userAuthenticationStream()).thenAnswer((_) => Stream.value(null));

      await widgetTester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('welcomeBack'.tr()), findsOneWidget);
      expect(find.text('signIn'.tr()), findsOneWidget);
      expect(find.text('SignInWithGoogle'.tr()), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('dispatches SignInWithGoogle event when the button is tapped', (widgetTester) async {
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.fromIterable([]),
        initialState: const AuthInitial(),
      );
      when(mockAuthBloc.userAuthenticationStream()).thenAnswer((_) => Stream.value(null));

      await widgetTester.pumpWidget(createWidgetUnderTest());

      await widgetTester.tap(find.byType(ElevatedButton));
      await widgetTester.pump();

      verify(() => mockAuthBloc.add(const SignInWithGoogle())).called(1);
    });

    testWidgets('shows SnackBar when state is AuthError', (widgetTester) async {
      const errorMessage = 'An error occurred';
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.fromIterable([const AuthError(message: errorMessage)]),
        initialState: const AuthInitial(),
      );
      when(mockAuthBloc.userAuthenticationStream()).thenAnswer((_) => Stream.value(null));

      await widgetTester.pumpWidget(createWidgetUnderTest());
      await widgetTester.pump(); // for the SnackBar to appear

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    // Note: Testing navigation is complex in widget tests.
    // This is better suited for integration tests.
    // However, we can verify that the UI is not rendered when the user is signed in.
    testWidgets('does not render login UI when user is signed in', (widgetTester) async {
      when(mockAuthBloc.userAuthenticationStream()).thenAnswer((_) => Stream.value(userModel));

      await widgetTester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget); // The shrink box
    });
  });
}
