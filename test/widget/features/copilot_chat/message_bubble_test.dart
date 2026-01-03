import 'dart:ui';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createMessageBubble(Map<String, dynamic> message,
      {Function(String)? onEdit}) {
    return MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: message,
          onEdit: onEdit ?? (_) {},
          currentUserDisplayName: 'Test User',
        ),
      ),
    );
  }

  testWidgets('MessageBubble renders user message correctly',
      (WidgetTester tester) async {
    const message = {
      'isUser': true,
      'message': 'Hello AI',
      'id': '123',
    };

    await tester.pumpWidget(createMessageBubble(message));

    expect(find.text('Hello AI'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    // User messages are aligned to the right (checking Column crossAxisAlignment is hard, but we can check icon/layout)
    // User message should have an avatar with 'T' (Test User)
    expect(find.text('T'), findsOneWidget);
  });

  testWidgets('MessageBubble renders bot message correctly with Markdown',
      (WidgetTester tester) async {
    const message = {
      'isUser': false,
      'message': '**Bold Response**',
      'id': '124',
    };

    await tester.pumpWidget(createMessageBubble(message));

    // Markdown should be rendered
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Bold Response'),
        findsOneWidget); // Markdown strips the ** but text remains?
    // MarkdownBody usually finds RichText.
  });

  testWidgets('Hovering over user message shows actions',
      (WidgetTester tester) async {
    const message = {
      'isUser': true,
      'message': 'Hover me',
      'id': '125',
    };

    await tester.pumpWidget(createMessageBubble(message));

    final mouseRegion = find.byType(MouseRegion).first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await tester.pump();
    await gesture.moveTo(tester.getCenter(mouseRegion));
    await tester.pumpAndSettle();

    // Verify actions appear (Edit icon)
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
  });

  testWidgets('Edit mode works correctly', (WidgetTester tester) async {
    bool editCallbackCalled = false;
    String editedText = '';

    final message = {
      'isUser': true,
      'message': 'Original Text',
      'id': '126',
    };

    await tester.pumpWidget(createMessageBubble(message, onEdit: (text) {
      editCallbackCalled = true;
      editedText = text;
    }));

    // Hover to show edit button
    final mouseRegion = find.byType(MouseRegion).first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(mouseRegion));
    await tester.pumpAndSettle();

    // Click edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Verify TextField appears
    expect(find.byType(TextFormField), findsOneWidget);

    // Enter new text
    await tester.enterText(find.byType(TextFormField), 'New Text');

    // Click save
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(editCallbackCalled, isTrue);
    expect(editedText, 'New Text');
  });
}
