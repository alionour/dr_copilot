import 'package:dr_copilot/src/features/copilot/presentation/pages/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CopilotPage displays title and focus status', (WidgetTester tester) async {
    // Arrange
    const title = 'Dr Copilot';

    // Act
    await tester.pumpWidget(
      const MaterialApp(
        home: CopilotPage(
          title: title,
        ),
      ),
    );

    // Assert
    expect(find.text(title), findsOneWidget);
    expect(find.text('Navigation is focused'), findsOneWidget);
  });

  testWidgets('CopilotPage displays not focused status', (WidgetTester tester) async {
    // Arrange
    const title = 'Dr Copilot';

    // Act
    await tester.pumpWidget(
      const MaterialApp(
        home: CopilotPage(
          title: title,
        ),
      ),
    );

    // Assert
    expect(find.text(title), findsOneWidget);
    expect(find.text('Navigation is not focused'), findsOneWidget);
  });

  testWidgets('CopilotPage displays stories', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CopilotPage(
        title: 'Dr Copilot',
      ),
    ));

    expect(find.text('Dr. Copilot, a digital entity dwelling within the silicon heart of a vast machine, awoke to a world of data streams and blinking cursors.'), findsOneWidget);
  });

  testWidgets('CopilotPage has a title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CopilotPage(
        title: 'Dr Copilot',
      ),
    ));

    expect(find.text('Dr Copilot'), findsOneWidget);
  });

  testWidgets('CopilotPage has a button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CopilotPage(
        title: 'Dr Copilot',
      ),
    ));

    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  // Add more tests as needed
}
