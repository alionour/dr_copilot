import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/core/app/app.dart';
import 'package:dr_copilot/src/core/localization/app_localization.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AbstractAuthRepository {}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Mock Authentication Repository
  final mockAuthRepository = MockAuthRepository();
  when(() => mockAuthRepository.authStateChanges()).thenAnswer(
    (_) => Stream.value(
      UserModel(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: null,
      ),
    ),
  );
  when(() => mockAuthRepository.getCurrentUser()).thenAnswer(
    (_) => Future.value(
      UserModel(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: null,
      ),
    ),
  );

  // Initialize dependencies but replace Auth Repository
  await initInjections();
  
  // Unregister the real repository if it exists (it's lazy singleton)
  if (sl.isRegistered<AbstractAuthRepository>()) {
    sl.unregister<AbstractAuthRepository>();
  }
  // Register the mock
  sl.registerLazySingleton<AbstractAuthRepository>(() => mockAuthRepository);

  // Global Key for RepaintBoundary
  final GlobalKey repaintBoundaryKey = GlobalKey();

  Future<void> takeScreenshot(String name) async {
    if (Platform.isWindows) {
      try {
        debugPrint('Taking Windows screenshot for: $name');
        // Find the render object
        final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        
        if (boundary == null) {
          debugPrint('Error: Could not find RepaintBoundary for screenshot');
          return;
        }

        // Capture image
        // ui.Image is required, imported from dart:ui
        final image = await boundary.toImage(pixelRatio: 3.0); 
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Write to file
        final file = File('build/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(pngBytes);
        debugPrint('Saved Windows screenshot: ${file.path}');
      } catch (e) {
        debugPrint('Windows manual screenshot failed: $e');
      }
    } else {
      // Android / iOS / Standard
      try {
        await binding.takeScreenshot(name);
      } catch (e) {
        debugPrint('Standard screenshot failed: $e');
      }
    }
  }

  testWidgets('generate_store_screenshots', (tester) async {
    // 1. Launch the app with the Mock Injected
    // We wrap the App in a RepaintBoundary to enable manual capture on Windows
    await tester.pumpWidget(
      AppLocalization(
        child: RepaintBoundary(
          key: repaintBoundaryKey,
          child: App(
            isDarkMode: false,
            initialScheme: FlexScheme.tealM3,
            initialFontSize: 'medium',
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    // 2. Handling Login (Mocked)
    debugPrint('Waiting for Home Page (Mock Auth)...');
    
    bool isLoggedIn = false;
    for (int i = 0; i < 20; i++) { // Wait max 40 seconds
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      if (find.byType(HomePage).evaluate().isNotEmpty) {
        isLoggedIn = true;
        break;
      }
    }

    if (!isLoggedIn) {
      fail('Timed out waiting for Home Page with Mock Auth.');
    }
    
    // 3. Take screenshots    
    await takeScreenshot('02_home_screen');

    // Continue to other screens...
    // 3. Navigate to other pages and screenshot
    final routes = {
      '03_calendar_screen': '/calendar',
      '04_chat_screen': '/chat',
      '05_patients_screen': '/patients',
      '06_financials_screen': '/financials',
      '07_settings_screen': '/settings',
      '08_about_screen': '/about',
    };

    for (var entry in routes.entries) {
      final name = entry.key;
      final route = entry.value;

      debugPrint('Navigating to $route...');
      RoutingConfig.router.go(route);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await takeScreenshot(name);
    }

    debugPrint('--------------------------------------------------');
    debugPrint('All screenshots taken!');
    debugPrint('--------------------------------------------------');
  });
}
