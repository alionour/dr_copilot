import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/navigation_side.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavigationSide displays side menu', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NavigationSide(child: Text('Test'))));

    expect(find.text('Dr Copilot'), findsOneWidget);
  });
}
