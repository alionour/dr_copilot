import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/sessions_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:mockito/annotations.dart';
import 'sessions_page_test.mocks.dart';

@GenerateMocks([SessionsBloc])
void main() {
  group('SessionsPage Tests', () {
    late MockSessionsBloc mockSessionsBloc;

    setUp(() {
      mockSessionsBloc = MockSessionsBloc();
    });

    testWidgets('should render SessionsPage with initial state',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: SessionsPage(),
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
      when(mockSessionsBloc.state).thenReturn(SessionsLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: SessionsPage(),
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
      when(mockSessionsBloc.state).thenReturn(SessionsLoaded(sessions: []));

      await tester.pumpWidget(
        MaterialApp(
          home: SessionsPage(),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
