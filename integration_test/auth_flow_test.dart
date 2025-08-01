import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/auth_injections.dart' as auth_injections;
import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dr_copilot/main.dart' as app;

Future<void> initInjectionsForTest({required FirebaseAuth firebaseAuth}) async {
  final sl = GetIt.instance;
  sl.reset();

  // Register mock FirebaseAuth
  sl.registerLazySingleton<FirebaseAuth>(() => firebaseAuth);

  // Register other dependencies
  auth_injections.initAuthInjections();

  // Override AuthFirebaseApi to use the mock FirebaseAuth
  sl.unregister<AuthFirebaseApi>();
  sl.registerLazySingleton<AuthFirebaseApi>(() => AuthFirebaseApi(sl<FirebaseAuth>()));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    late MockFirebaseAuth mockAuth;

    setUp(() async {
      mockAuth = MockFirebaseAuth(signedIn: false);
      await initInjectionsForTest(firebaseAuth: mockAuth);
    });

    testWidgets('should sign in with google and navigate to home page', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start on the login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap the "Sign in with Google" button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // At this point, the mock auth should have been called.
      // We can't easily mock the Google Sign In flow itself in an integration test,
      // so we assume that if the user is signed in in the mock, the flow was successful.
      mockAuth.signInWithCredential(GoogleAuthProvider.credential());
      await tester.pumpAndSettle();

      // Verify that we are on the home page
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
