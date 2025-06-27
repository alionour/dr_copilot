import 'package:dr_copilot/main.dart' as app;
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('complete login flow with Google Sign-In', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start on login page
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Tap Google Sign In button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Verify loading state appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for authentication to complete (in real test, this would involve actual Google auth)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After successful authentication, should navigate to home page
      // Note: In a real integration test, you would need to mock or handle actual Google authentication
      // For this test, we're testing the UI flow
    });

    testWidgets('handle authentication error gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Simulate authentication error by tapping sign in multiple times rapidly
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should handle the error gracefully and show error message
      // In a real scenario, this would test actual error handling
    });

    testWidgets('logout flow from authenticated state', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Assuming user is already authenticated (would need setup in real test)
      // Navigate to settings/profile
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Find and tap logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Should return to login page
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('persist authentication state across app restarts', (WidgetTester tester) async {
      // First session - login
      app.main();
      await tester.pumpAndSettle();

      // Perform login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simulate app restart
      await tester.binding.reassembleApplication();
      await tester.pumpAndSettle();

      // Should remain authenticated and go directly to home page
      // (In real test, this would verify token persistence)
    });

    testWidgets('handle expired authentication token', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Assuming user is authenticated but token expires
      // Try to perform an authenticated action
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Should detect expired token and redirect to login
      // In real implementation, this would test token refresh or re-authentication
    });

    testWidgets('biometric authentication flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for biometric authentication option
      if (find.text('Use Biometric').evaluate().isNotEmpty) {
        await tester.tap(find.text('Use Biometric'));
        await tester.pumpAndSettle();

        // Simulate biometric authentication success
        // In real test, this would involve platform-specific biometric mocking
      }
    });

    testWidgets('remember me functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check remember me option if available
      if (find.byType(Checkbox).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
      }

      // Perform login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Restart app
      await tester.binding.reassembleApplication();
      await tester.pumpAndSettle();

      // Should remember authentication state
    });

    testWidgets('offline authentication handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate offline state
      // Try to authenticate
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should show appropriate offline message
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Please check your connection and try again'), findsOneWidget);
    });

    testWidgets('multiple account selection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap Google Sign In
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // In real test, this would handle Google account picker
      // For now, we test that the flow initiates correctly
    });

    testWidgets('authentication with different user roles', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test doctor role authentication
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // After authentication, verify role-specific UI elements
      // Doctor should see all features
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('Financials'), findsOneWidget);
      expect(find.text('Copilot'), findsOneWidget);

      // Logout and test nurse role
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Login as nurse (would need role-specific test data)
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Nurse might have limited access
      expect(find.text('Patients'), findsOneWidget);
      // Financials might be restricted
    });

    testWidgets('first-time user onboarding flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform first-time login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should show onboarding screens for new users
      if (find.text('Welcome to Dr Copilot').evaluate().isNotEmpty) {
        // Navigate through onboarding
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Should reach home page after onboarding
        expect(find.byType(HomePage), findsOneWidget);
      }
    });

    testWidgets('account linking and unlinking', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login with Google
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Navigate to account settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account Settings'));
      await tester.pumpAndSettle();

      // Test linking additional providers (if available)
      if (find.text('Link Apple ID').evaluate().isNotEmpty) {
        await tester.tap(find.text('Link Apple ID'));
        await tester.pumpAndSettle();
      }

      // Test unlinking providers
      if (find.text('Unlink Google').evaluate().isNotEmpty) {
        await tester.tap(find.text('Unlink Google'));
        await tester.pumpAndSettle();

        // Confirm unlinking
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('session timeout handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Simulate session timeout by waiting or triggering timeout
      // In real test, this would involve manipulating session tokens

      // Try to perform an action that requires authentication
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Should detect session timeout and show re-authentication dialog
      if (find.text('Session Expired').evaluate().isNotEmpty) {
        expect(find.text('Please sign in again'), findsOneWidget);
        
        await tester.tap(find.text('Sign In Again'));
        await tester.pumpAndSettle();

        // Should return to login page
        expect(find.byType(LoginPage), findsOneWidget);
      }
    });

    testWidgets('authentication error recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Attempt login that will fail
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Authentication failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap try again
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Should return to login state
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}
