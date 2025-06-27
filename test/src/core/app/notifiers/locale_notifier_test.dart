import 'package:dr_copilot/src/core/app/notifiers/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleNotifier Tests', () {
    late LocaleNotifier localeNotifier;

    setUp(() {
      localeNotifier = LocaleNotifier();
    });

    tearDown(() {
      localeNotifier.dispose();
    });

    group('Initial State', () {
      test('should initialize with English locale by default', () {
        expect(localeNotifier.currentLocale, equals(const Locale('en')));
        expect(localeNotifier.currentLocale.languageCode, equals('en'));
      });

      test('should have valid default locale', () {
        final locale = localeNotifier.currentLocale;
        expect(locale.languageCode.length, greaterThanOrEqualTo(2));
        expect(locale.languageCode, isA<String>());
      });
    });

    group('Locale Changes', () {
      test('should change locale to Arabic', () {
        const arabicLocale = Locale('ar');

        localeNotifier.setLocale(arabicLocale);

        expect(localeNotifier.currentLocale, equals(arabicLocale));
        expect(localeNotifier.currentLocale.languageCode, equals('ar'));
      });

      test('should change locale to English', () {
        const englishLocale = Locale('en');

        localeNotifier.setLocale(englishLocale);

        expect(localeNotifier.currentLocale, equals(englishLocale));
        expect(localeNotifier.currentLocale.languageCode, equals('en'));
      });

      test('should change locale to French', () {
        const frenchLocale = Locale('fr');

        localeNotifier.setLocale(frenchLocale);

        expect(localeNotifier.currentLocale, equals(frenchLocale));
        expect(localeNotifier.currentLocale.languageCode, equals('fr'));
      });

      test('should notify listeners when locale changes', () {
        bool notified = false;
        localeNotifier.addListener(() {
          notified = true;
        });

        localeNotifier.setLocale(const Locale('ar'));

        expect(notified, isTrue);
      });
    });

    group('Locale Validation', () {
      test('should handle valid locale codes', () {
        const validLocales = [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
          Locale('de'),
        ];

        for (final locale in validLocales) {
          localeNotifier.setLocale(locale);
          expect(localeNotifier.currentLocale, equals(locale));
        }
      });

      test('should handle locale with country code', () {
        const localeWithCountry = Locale('en', 'US');

        localeNotifier.setLocale(localeWithCountry);

        expect(localeNotifier.currentLocale, equals(localeWithCountry));
        expect(localeNotifier.currentLocale.languageCode, equals('en'));
        expect(localeNotifier.currentLocale.countryCode, equals('US'));
      });

      test('should handle locale with script code', () {
        const localeWithScript = Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        );

        localeNotifier.setLocale(localeWithScript);

        expect(localeNotifier.currentLocale, equals(localeWithScript));
        expect(localeNotifier.currentLocale.languageCode, equals('zh'));
        expect(localeNotifier.currentLocale.scriptCode, equals('Hans'));
        expect(localeNotifier.currentLocale.countryCode, equals('CN'));
      });
    });

    group('Persistence', () {
      test('should maintain locale state across multiple changes', () {
        const testLocales = [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('en'),
        ];

        for (final locale in testLocales) {
          localeNotifier.setLocale(locale);
          expect(localeNotifier.currentLocale, equals(locale));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle same locale change gracefully', () {
        const locale = Locale('en');

        localeNotifier.setLocale(locale);
        final firstChange = localeNotifier.currentLocale;

        localeNotifier.setLocale(locale);
        final secondChange = localeNotifier.currentLocale;

        expect(firstChange, equals(secondChange));
      });

      test('should handle rapid locale changes', () {
        const locales = [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
          Locale('de'),
        ];

        for (final locale in locales) {
          localeNotifier.setLocale(locale);
        }

        expect(localeNotifier.currentLocale, equals(locales.last));
      });

      test('should handle unusual locale codes', () {
        const unusualLocales = [
          Locale('xx'), // Non-standard code
          Locale('en', 'XX'), // Non-standard country
          Locale('a'), // Single character
        ];

        for (final locale in unusualLocales) {
          localeNotifier.setLocale(locale);
          expect(localeNotifier.currentLocale, equals(locale));
        }
      });
    });

    group('Listener Management', () {
      test('should properly notify multiple listeners', () {
        int notificationCount = 0;

        void listener() {
          notificationCount++;
        }

        localeNotifier.addListener(listener);
        localeNotifier.addListener(listener);

        localeNotifier.setLocale(const Locale('ar'));

        expect(notificationCount, equals(2));
      });

      test('should stop notifying after listener removal', () {
        int notificationCount = 0;

        void listener() {
          notificationCount++;
        }

        localeNotifier.addListener(listener);
        localeNotifier.setLocale(const Locale('ar'));

        localeNotifier.removeListener(listener);
        localeNotifier.setLocale(const Locale('en'));

        expect(notificationCount, equals(1));
      });

      test('should handle listener operations during locale change', () {
        int callCount = 0;
        bool addedNewListener = false;

        void dynamicListener() {
          callCount++;
          if (!addedNewListener) {
            localeNotifier.addListener(() => callCount++);
            addedNewListener = true;
          }
        }

        localeNotifier.addListener(dynamicListener);
        localeNotifier.setLocale(const Locale('ar'));

        expect(callCount, greaterThan(0));
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state after multiple operations', () {
        const targetLocale = Locale('ar');

        localeNotifier.setLocale(targetLocale);
        localeNotifier.setLocale(const Locale('en'));
        localeNotifier.setLocale(targetLocale);

        expect(localeNotifier.currentLocale, equals(targetLocale));
      });

      test('should preserve locale properties correctly', () {
        const locale = Locale('en', 'US');

        localeNotifier.setLocale(locale);

        expect(localeNotifier.currentLocale.languageCode, equals('en'));
        expect(localeNotifier.currentLocale.countryCode, equals('US'));
        expect(localeNotifier.currentLocale.toString(), equals('en_US'));
      });
    });

    group('Memory Management', () {
      test('should properly dispose and not notify after disposal', () {
        bool listenerCalled = false;

        localeNotifier.addListener(() {
          listenerCalled = true;
        });

        localeNotifier.dispose();

        // This should not throw or call listeners
        expect(() => localeNotifier.setLocale(const Locale('ar')),
            throwsFlutterError);
        expect(listenerCalled, isFalse);
      });

      test('should handle multiple dispose calls gracefully', () {
        localeNotifier.dispose();

        expect(() => localeNotifier.dispose(), returnsNormally);
      });
    });

    group('ChangeNotifier Behavior', () {
      test('should be a ChangeNotifier', () {
        expect(localeNotifier, isA<ChangeNotifier>());
      });

      test('should support listener management', () {
        void testListener() {}

        // Test that listeners can be added and removed without errors
        expect(() => localeNotifier.addListener(testListener), returnsNormally);
        expect(
            () => localeNotifier.removeListener(testListener), returnsNormally);
      });
    });

    group('Locale Equality', () {
      test('should correctly compare locales', () {
        const locale1 = Locale('en');
        const locale2 = Locale('en');
        const locale3 = Locale('ar');

        localeNotifier.setLocale(locale1);
        expect(localeNotifier.currentLocale, equals(locale2));
        expect(localeNotifier.currentLocale, isNot(equals(locale3)));
      });

      test('should handle locale with different country codes', () {
        const localeUS = Locale('en', 'US');
        const localeUK = Locale('en', 'GB');

        localeNotifier.setLocale(localeUS);
        expect(localeNotifier.currentLocale, equals(localeUS));
        expect(localeNotifier.currentLocale, isNot(equals(localeUK)));
      });
    });

    group('Advanced Locale Features', () {
      test('should handle rapid locale changes', () {
        int notificationCount = 0;

        localeNotifier.addListener(() {
          notificationCount++;
        });

        final locales = [
          const Locale('en', 'US'),
          const Locale('es', 'ES'),
          const Locale('fr', 'FR'),
          const Locale('de', 'DE'),
          const Locale('ar', 'SA'),
        ];

        // Rapidly change locales
        for (final locale in locales) {
          localeNotifier.setLocale(locale);
        }

        expect(notificationCount, equals(locales.length));
        expect(localeNotifier.currentLocale, equals(const Locale('ar', 'SA')));
      });

      test('should handle locale changes with persistence', () {
        const testLocale = Locale('ja', 'JP');

        localeNotifier.setLocale(testLocale);
        expect(localeNotifier.currentLocale, equals(testLocale));

        // In a real app, this would test SharedPreferences persistence
        // For now, we just verify the state is maintained
        expect(localeNotifier.currentLocale.languageCode, equals('ja'));
        expect(localeNotifier.currentLocale.countryCode, equals('JP'));
      });

      test('should handle locale fallbacks', () {
        // Test with a locale that might not be fully supported
        const unsupportedLocale = Locale('xyz', 'ABC');

        localeNotifier.setLocale(unsupportedLocale);

        // Should still accept the locale (fallback handling would be in the app)
        expect(localeNotifier.currentLocale, equals(unsupportedLocale));
      });

      test('should handle locale without country code', () {
        const localeWithoutCountry = Locale('en');

        localeNotifier.setLocale(localeWithoutCountry);

        expect(localeNotifier.currentLocale.languageCode, equals('en'));
        expect(localeNotifier.currentLocale.countryCode, isNull);
      });
    });

    group('Locale Validation', () {
      test('should handle common language codes', () {
        final commonLanguages = [
          'en',
          'es',
          'fr',
          'de',
          'it',
          'pt',
          'ru',
          'zh',
          'ja',
          'ko',
          'ar',
          'hi',
          'th',
          'vi',
          'tr',
          'pl',
          'nl',
          'sv',
          'da',
          'no'
        ];

        for (final langCode in commonLanguages) {
          final locale = Locale(langCode);
          localeNotifier.setLocale(locale);

          expect(localeNotifier.currentLocale.languageCode, equals(langCode));
        }
      });

      test('should handle common country codes', () {
        final commonCountries = [
          'US',
          'GB',
          'CA',
          'AU',
          'DE',
          'FR',
          'ES',
          'IT',
          'JP',
          'KR',
          'CN',
          'IN',
          'BR',
          'MX',
          'RU',
          'SA',
          'AE',
          'EG',
          'ZA',
          'NG'
        ];

        for (final countryCode in commonCountries) {
          final locale = Locale('en', countryCode);
          localeNotifier.setLocale(locale);

          expect(localeNotifier.currentLocale.countryCode, equals(countryCode));
        }
      });

      test('should handle RTL languages', () {
        final rtlLanguages = ['ar', 'he', 'fa', 'ur'];

        for (final langCode in rtlLanguages) {
          final locale = Locale(langCode);
          localeNotifier.setLocale(locale);

          expect(localeNotifier.currentLocale.languageCode, equals(langCode));
          // In a real app, you might test RTL text direction here
        }
      });

      test('should handle script codes', () {
        // Some locales might include script codes
        const localeWithScript = Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        );

        localeNotifier.setLocale(localeWithScript);

        expect(localeNotifier.currentLocale.languageCode, equals('zh'));
        expect(localeNotifier.currentLocale.scriptCode, equals('Hans'));
        expect(localeNotifier.currentLocale.countryCode, equals('CN'));
      });
    });

    group('Performance Tests', () {
      test('should handle many locale changes efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          final locale = Locale('en', 'US');
          localeNotifier.setLocale(locale);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle many listeners efficiently', () {
        final listeners = <VoidCallback>[];

        // Add many listeners
        for (int i = 0; i < 100; i++) {
          void listener() {}
          listeners.add(listener);
          localeNotifier.addListener(listener);
        }

        final stopwatch = Stopwatch()..start();
        localeNotifier.setLocale(const Locale('fr', 'FR'));
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        // Clean up listeners
        for (final listener in listeners) {
          localeNotifier.removeListener(listener);
        }
      });
    });

    group('Error Handling', () {
      test('should handle listener exceptions gracefully', () {
        // Add a listener that throws an exception
        localeNotifier.addListener(() {
          throw Exception('Test exception');
        });

        // Add a normal listener
        bool normalListenerCalled = false;
        localeNotifier.addListener(() {
          normalListenerCalled = true;
        });

        // Setting locale should not crash despite the exception
        expect(() => localeNotifier.setLocale(const Locale('de', 'DE')),
            returnsNormally);

        // Normal listener should still be called
        expect(normalListenerCalled, isTrue);
      });

      test('should maintain state consistency after errors', () {
        const targetLocale = Locale('it', 'IT');

        // Add a problematic listener
        localeNotifier.addListener(() {
          throw Exception('Test exception');
        });

        // Set locale
        localeNotifier.setLocale(targetLocale);

        // State should still be updated correctly
        expect(localeNotifier.currentLocale, equals(targetLocale));
      });
    });

    group('Locale Formatting', () {
      test('should handle locale string representation', () {
        const locale = Locale('en', 'US');
        localeNotifier.setLocale(locale);

        final localeString = localeNotifier.currentLocale.toString();
        expect(localeString, equals('en_US'));
      });

      test('should handle locale comparison', () {
        const locale1 = Locale('en', 'US');
        const locale2 = Locale('en', 'US');
        const locale3 = Locale('en', 'GB');

        expect(locale1, equals(locale2));
        expect(locale1, isNot(equals(locale3)));
      });

      test('should handle locale hash codes', () {
        const locale1 = Locale('fr', 'FR');
        const locale2 = Locale('fr', 'FR');

        expect(locale1.hashCode, equals(locale2.hashCode));
      });
    });
  });
}
