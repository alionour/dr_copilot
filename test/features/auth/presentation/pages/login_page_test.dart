import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
