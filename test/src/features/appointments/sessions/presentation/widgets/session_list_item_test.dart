import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/widgets/session_list_item.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  group('SessionListItem Widget Tests', () {
    testWidgets('should render session list item correctly',
        (WidgetTester tester) async {
      // Arrange
      final sessionModel = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: Timestamp.fromDate(DateTime.now()),
        endDateTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        sessionType: SessionType.standard,
        userId: 'user_1',
        createdBy: 'admin',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionListItem(
            sessionModel: sessionModel,
            onTap: () {},
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('100.0'), findsOneWidget);
    });

    testWidgets('should display session type and price',
        (WidgetTester tester) async {
      // Arrange
      final sessionModel = SessionModel(
        id: '2',
        patientId: '456',
        price: 200.0,
        startDateTime: Timestamp.fromDate(DateTime.now()),
        endDateTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))),
        sessionType: SessionType.adultIntensive,
        userId: 'user_2',
        createdBy: 'admin',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionListItem(
            sessionModel: sessionModel,
            onTap: () {},
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      debugPrint('Session Type: ${sessionModel.sessionType.text}');
      expect(find.text('Adult Intensive'), findsOneWidget);
      expect(find.text('200.0'), findsOneWidget);
    });

    testWidgets('should render session list item correctly in Arabic',
        (WidgetTester tester) async {
      // Arrange
      final sessionModel = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: Timestamp.fromDate(DateTime.now()),
        endDateTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        sessionType: SessionType.standard,
        userId: 'user_1',
        createdBy: 'admin',
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ar')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          startLocale: Locale('ar'),
          child: MaterialApp(
            home: SessionListItem(
              sessionModel: sessionModel,
              onTap: () {},
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('قياسي'), findsOneWidget); // Arabic for 'Standard'
      expect(find.text('100.0'), findsOneWidget);
    });
  });
}
