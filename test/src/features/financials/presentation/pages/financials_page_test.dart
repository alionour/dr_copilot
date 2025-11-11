import 'package:dr_copilot/src/features/financials/presentation/pages/financials_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  group('FinancialsPage', () {
    Widget createWidgetUnderTest() {
      return const MaterialApp(
        home: FinancialsPage(),
      );
    }

    // Since easy_localization is used, we need to initialize it.
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Mock EasyLocalization
      EasyLocalization.logger.enableBuildModes = [];
      await EasyLocalization.ensureInitialized();
    });

    testWidgets('renders correctly with initial page selected',
        (widgetTester) async {
      await widgetTester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(FinancialsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('financials'.tr()), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Initially, the DashboardPage should be displayed.
      // We can't directly test for DashboardPage without more complex setup,
      // but we can check for the navigation destinations.
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('tapping navigation items changes the selected page',
        (widgetTester) async {
      await widgetTester.pumpWidget(createWidgetUnderTest());

      // Tap on the 'Transactions' navigation item
      await widgetTester.tap(find.text('Transactions'));
      await widgetTester.pumpAndSettle();

      // The second page (TransactionsPage) should be displayed.
      // We can't directly test for the page type, but we can verify the index change
      // by checking the color of the icon, for example.
      // Or we can check if the content of the page is displayed.
      // For now, we will just verify the navigation bar behavior.

      final NavigationBar navigationBar =
          widgetTester.widget(find.byType(NavigationBar));
      expect(navigationBar.selectedIndex, 1);

      // Tap on the 'Charts' navigation item
      await widgetTester.tap(find.text('Charts'));
      await widgetTester.pumpAndSettle();

      final NavigationBar navigationBar2 =
          widgetTester.widget(find.byType(NavigationBar));
      expect(navigationBar2.selectedIndex, 2);
    });
  });
}
