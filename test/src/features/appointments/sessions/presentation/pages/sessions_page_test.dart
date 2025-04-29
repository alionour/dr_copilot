// This file is responsible for registering the dependencies for the financials feature.import 'package:easy_localization/easy_localization.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/sessions_page.dart';

class MockSessionsBloc extends MockBloc<SessionsEvent, SessionsState>
    implements SessionsBloc {}

void main() {
  group('SessionsPage Tests', () {
    late MockSessionsBloc mockSessionsBloc;

    setUp(() {
      mockSessionsBloc = MockSessionsBloc();
      registerFallbackValue(SessionsLoading([]));
      registerFallbackValue(SessionsLoaded([]));
    });

    testWidgets('should render SessionsPage with initial state',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockSessionsBloc.state).thenReturn(SessionsLoading([]));

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale('en')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          startLocale: Locale('en'),
          child: MaterialApp(
            home: BlocProvider<SessionsBloc>.value(
              value: mockSessionsBloc,
              child: SessionsPage(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(SessionsPage), findsOneWidget);
    });

    testWidgets('should display loading indicator when state is loading',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockSessionsBloc.state).thenReturn(SessionsLoading([]));

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale('en')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          startLocale: Locale('en'),
          child: MaterialApp(
            home: BlocProvider<SessionsBloc>.value(
              value: mockSessionsBloc,
              child: SessionsPage(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display sessions list when state is loaded',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockSessionsBloc.state).thenReturn(SessionsLoaded([]));

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale('en')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          startLocale: Locale('en'),
          child: MaterialApp(
            home: BlocProvider<SessionsBloc>.value(
              value: mockSessionsBloc,
              child: SessionsPage(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
