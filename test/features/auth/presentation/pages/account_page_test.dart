import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';

void main() {
  testWidgets('AccountPage renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountPage()));
    expect(find.byType(AccountPage), findsOneWidget);
  });
}
