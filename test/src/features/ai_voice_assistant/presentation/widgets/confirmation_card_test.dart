import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/confirmation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConfirmationCard displays command and calls callbacks',
      (WidgetTester tester) async {
    const command = Command(
      intent: 'test_intent',
      entities: {'entity1': 'value1', 'entity2': 'value2'},
    );
    var confirmed = false;
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfirmationCard(
            command: command,
            onConfirm: (updatedCommand) {
              confirmed = true;
            },
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Intent: test_intent'), findsOneWidget);
    expect(find.text('Entities:'), findsOneWidget);
    expect(find.text('- entity1: value1'), findsOneWidget);
    expect(find.text('- entity2: value2'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(confirmed, isTrue);

    // Reset confirmed to false to test the cancel button
    confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfirmationCard(
            command: command,
            onConfirm: (updatedCommand) {
              confirmed = true;
            },
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(confirmed, isFalse);
    expect(cancelled, isTrue);
  });
}
