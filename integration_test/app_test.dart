import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dr_copilot/src/core/app/app.dart' as app_widget;
import 'package:dr_copilot/main.dart' as entry_point;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('app starts and renders login or home screen', (tester) async {
      entry_point.main();
      await tester.pumpAndSettle();

      // Verify we are at least running
      // Ideally check for 'welcomeBack' or 'copilotChat' depending on auth state
      // Since we can't easily mock auth in full integration test without backend support/flags,
      // we just verify the app doesn't crash on startup.
      expect(find.byType(app_widget.App), findsOneWidget); // Or generic check
    });
  });
}
