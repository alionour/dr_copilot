import 'package:dr_copilot/src/core/app/notifiers/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeNotifier Tests', () {
    late ThemeNotifier themeNotifier;

    setUp(() {
      themeNotifier = ThemeNotifier(isDarkMode: false);
    });

    tearDown(() {
      themeNotifier.dispose();
    });

    group('Initial State', () {
      test('should initialize with light mode when isDarkMode is false', () {
        final lightThemeNotifier = ThemeNotifier(isDarkMode: false);

        expect(lightThemeNotifier.isDarkMode, isFalse);
        expect(lightThemeNotifier.currentTheme, isA<ThemeData>());
        expect(lightThemeNotifier.currentTheme.brightness,
            equals(Brightness.light));

        lightThemeNotifier.dispose();
      });

      test('should initialize with dark mode when isDarkMode is true', () {
        final darkThemeNotifier = ThemeNotifier(isDarkMode: true);

        expect(darkThemeNotifier.isDarkMode, isTrue);
        expect(darkThemeNotifier.currentTheme, isA<ThemeData>());
        expect(
            darkThemeNotifier.currentTheme.brightness, equals(Brightness.dark));

        darkThemeNotifier.dispose();
      });
    });

    group('Theme Toggle', () {
      test('should toggle from light to dark mode', () {
        expect(themeNotifier.isDarkMode, isFalse);

        themeNotifier.toggleTheme();

        expect(themeNotifier.isDarkMode, isTrue);
        expect(themeNotifier.currentTheme.brightness, equals(Brightness.dark));
      });

      test('should toggle from dark to light mode', () {
        final darkThemeNotifier = ThemeNotifier(isDarkMode: true);
        expect(darkThemeNotifier.isDarkMode, isTrue);

        darkThemeNotifier.toggleTheme();

        expect(darkThemeNotifier.isDarkMode, isFalse);
        expect(darkThemeNotifier.currentTheme.brightness,
            equals(Brightness.light));

        darkThemeNotifier.dispose();
      });

      test('should toggle multiple times correctly', () {
        expect(themeNotifier.isDarkMode, isFalse);

        themeNotifier.toggleTheme();
        expect(themeNotifier.isDarkMode, isTrue);

        themeNotifier.toggleTheme();
        expect(themeNotifier.isDarkMode, isFalse);

        themeNotifier.toggleTheme();
        expect(themeNotifier.isDarkMode, isTrue);
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners when theme is toggled', () {
        bool listenerCalled = false;

        themeNotifier.addListener(() {
          listenerCalled = true;
        });

        themeNotifier.toggleTheme();

        expect(listenerCalled, isTrue);
      });

      test('should notify multiple listeners', () {
        int listener1CallCount = 0;
        int listener2CallCount = 0;

        void listener1() => listener1CallCount++;
        void listener2() => listener2CallCount++;

        themeNotifier.addListener(listener1);
        themeNotifier.addListener(listener2);

        themeNotifier.toggleTheme();

        expect(listener1CallCount, equals(1));
        expect(listener2CallCount, equals(1));
      });

      test('should not notify removed listeners', () {
        int listenerCallCount = 0;

        void listener() => listenerCallCount++;

        themeNotifier.addListener(listener);
        themeNotifier.toggleTheme();
        expect(listenerCallCount, equals(1));

        themeNotifier.removeListener(listener);
        themeNotifier.toggleTheme();
        expect(listenerCallCount, equals(1)); // Should not increment
      });
    });

    group('Theme Data Properties', () {
      test('should return valid ThemeData for light mode', () {
        final lightTheme = themeNotifier.currentTheme;

        expect(lightTheme, isA<ThemeData>());
        expect(lightTheme.brightness, equals(Brightness.light));
        expect(lightTheme.colorScheme, isNotNull);
        expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
      });

      test('should return valid ThemeData for dark mode', () {
        themeNotifier.toggleTheme();
        final darkTheme = themeNotifier.currentTheme;

        expect(darkTheme, isA<ThemeData>());
        expect(darkTheme.brightness, equals(Brightness.dark));
        expect(darkTheme.colorScheme, isNotNull);
        expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
      });

      test('should return different themes for light and dark modes', () {
        final lightTheme = themeNotifier.currentTheme;

        themeNotifier.toggleTheme();
        final darkTheme = themeNotifier.currentTheme;

        expect(lightTheme.brightness, isNot(equals(darkTheme.brightness)));
        expect(lightTheme.colorScheme.brightness,
            isNot(equals(darkTheme.colorScheme.brightness)));
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state after multiple operations', () {
        final initialState = themeNotifier.isDarkMode;

        // Perform multiple toggles (even number should return to initial state)
        for (int i = 0; i < 10; i++) {
          themeNotifier.toggleTheme();
        }

        expect(themeNotifier.isDarkMode, equals(initialState));
      });

      test('should have consistent theme data with isDarkMode property', () {
        expect(themeNotifier.isDarkMode, isFalse);
        expect(themeNotifier.currentTheme.brightness, equals(Brightness.light));

        themeNotifier.toggleTheme();

        expect(themeNotifier.isDarkMode, isTrue);
        expect(themeNotifier.currentTheme.brightness, equals(Brightness.dark));
      });
    });

    group('Edge Cases', () {
      test('should handle rapid successive toggles', () {
        bool finalState = themeNotifier.isDarkMode;

        // Rapid toggles
        for (int i = 0; i < 100; i++) {
          themeNotifier.toggleTheme();
          finalState = !finalState;
        }

        expect(themeNotifier.isDarkMode, equals(finalState));
      });

      test('should handle listener operations during toggle', () {
        int callCount = 0;
        bool addedNewListener = false;

        void dynamicListener() {
          callCount++;
          if (!addedNewListener) {
            themeNotifier.addListener(() => callCount++);
            addedNewListener = true;
          }
        }

        themeNotifier.addListener(dynamicListener);
        themeNotifier.toggleTheme();

        expect(callCount, greaterThan(0));
      });
    });

    group('Memory Management', () {
      test('should properly dispose and not notify after disposal', () {
        final testNotifier = ThemeNotifier(isDarkMode: false);
        bool listenerCalled = false;

        testNotifier.addListener(() {
          listenerCalled = true;
        });

        testNotifier.dispose();

        // This should not throw or call listeners
        expect(() => testNotifier.toggleTheme(), throwsFlutterError);
        expect(listenerCalled, isFalse);
      });

      test('should handle multiple dispose calls gracefully', () {
        final testNotifier = ThemeNotifier(isDarkMode: false);
        testNotifier.dispose();

        expect(() => testNotifier.dispose(), throwsFlutterError);
      });
    });

    group('ChangeNotifier Behavior', () {
      test('should be a ChangeNotifier', () {
        expect(themeNotifier, isA<ChangeNotifier>());
      });

      test('should support listener management', () {
        void testListener() {}

        // Test that listeners can be added and removed without errors
        expect(() => themeNotifier.addListener(testListener), returnsNormally);
        expect(
            () => themeNotifier.removeListener(testListener), returnsNormally);
      });
    });

    group('Advanced Theme Features', () {
      test('should handle rapid theme toggles', () {
        int notificationCount = 0;

        themeNotifier.addListener(() {
          notificationCount++;
        });

        // Rapidly toggle theme multiple times
        for (int i = 0; i < 10; i++) {
          themeNotifier.toggleTheme();
        }

        expect(notificationCount, equals(10));
        expect(themeNotifier.isDarkMode,
            isFalse); // Should end up back to light mode
      });

      test('should maintain theme consistency across multiple instances', () {
        final notifier1 = ThemeNotifier(isDarkMode: false);
        final notifier2 = ThemeNotifier(isDarkMode: false);

        notifier1.toggleTheme();
        notifier2.toggleTheme();

        expect(notifier1.isDarkMode, equals(notifier2.isDarkMode));

        notifier1.dispose();
        notifier2.dispose();
      });

      test('should handle theme changes with different initial states', () {
        final lightNotifier = ThemeNotifier(isDarkMode: false);
        final darkNotifier = ThemeNotifier(isDarkMode: true);

        expect(lightNotifier.isDarkMode, isFalse);
        expect(darkNotifier.isDarkMode, isTrue);

        lightNotifier.toggleTheme();
        darkNotifier.toggleTheme();

        expect(lightNotifier.isDarkMode, isTrue);
        expect(darkNotifier.isDarkMode, isFalse);

        lightNotifier.dispose();
        darkNotifier.dispose();
      });
    });

    group('Theme Data Validation', () {
      test('should provide valid light theme data', () {
        final lightTheme = themeNotifier.currentTheme;

        expect(lightTheme.brightness, equals(Brightness.light));
        expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
        expect(lightTheme.scaffoldBackgroundColor, isNotNull);
        expect(lightTheme.appBarTheme, isNotNull);
        expect(lightTheme.textTheme, isNotNull);
      });

      test('should provide valid dark theme data', () {
        themeNotifier.toggleTheme();
        final darkTheme = themeNotifier.currentTheme;

        expect(darkTheme.brightness, equals(Brightness.dark));
        expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
        expect(darkTheme.scaffoldBackgroundColor, isNotNull);
        expect(darkTheme.appBarTheme, isNotNull);
        expect(darkTheme.textTheme, isNotNull);
      });

      test('should have consistent color schemes', () {
        final lightTheme = themeNotifier.currentTheme;
        themeNotifier.toggleTheme();
        final darkTheme = themeNotifier.currentTheme;

        // Both themes should have complete color schemes
        expect(lightTheme.colorScheme.primary, isNotNull);
        expect(lightTheme.colorScheme.secondary, isNotNull);
        expect(lightTheme.colorScheme.surface, isNotNull);

        expect(darkTheme.colorScheme.primary, isNotNull);
        expect(darkTheme.colorScheme.secondary, isNotNull);
        expect(darkTheme.colorScheme.surface, isNotNull);
      });

      test('should have different colors for light and dark themes', () {
        final lightTheme = themeNotifier.currentTheme;
        themeNotifier.toggleTheme();
        final darkTheme = themeNotifier.currentTheme;

        // Background colors should be different
        expect(lightTheme.scaffoldBackgroundColor,
            isNot(equals(darkTheme.scaffoldBackgroundColor)));

        // Surface colors should be different
        expect(lightTheme.colorScheme.surface,
            isNot(equals(darkTheme.colorScheme.surface)));
      });
    });

    group('Performance Tests', () {
      test('should handle many theme toggles efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          themeNotifier.toggleTheme();
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
        expect(
            themeNotifier.isDarkMode, isFalse); // Should end up back to light
      });

      test('should handle many listeners efficiently', () {
        final listeners = <VoidCallback>[];

        // Add many listeners
        for (int i = 0; i < 100; i++) {
          void listener() {}
          listeners.add(listener);
          themeNotifier.addListener(listener);
        }

        final stopwatch = Stopwatch()..start();
        themeNotifier.toggleTheme(); // Should notify all listeners
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        // Clean up listeners
        for (final listener in listeners) {
          themeNotifier.removeListener(listener);
        }
      });

      test('should create theme data efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final theme = themeNotifier.currentTheme;
          expect(theme, isNotNull);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('Error Handling', () {
      test('should handle listener exceptions gracefully', () {
        // Add a listener that throws an exception
        themeNotifier.addListener(() {
          throw Exception('Test exception');
        });

        // Add a normal listener
        bool normalListenerCalled = false;
        themeNotifier.addListener(() {
          normalListenerCalled = true;
        });

        // Toggle theme should not crash despite the exception
        expect(() => themeNotifier.toggleTheme(), returnsNormally);

        // Normal listener should still be called
        expect(normalListenerCalled, isTrue);
      });

      test('should maintain state consistency after errors', () {
        final initialState = themeNotifier.isDarkMode;

        // Add a problematic listener
        themeNotifier.addListener(() {
          throw Exception('Test exception');
        });

        // Toggle theme
        themeNotifier.toggleTheme();

        // State should still be updated correctly
        expect(themeNotifier.isDarkMode, isNot(equals(initialState)));
      });
    });
  });
}
