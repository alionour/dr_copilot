import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/copilot_view.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/screenshot/mock_data/copilot_mock_data.dart';
import '../test/screenshot/screenshot_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Capture Copilot View Screenshots', (WidgetTester tester) async {
    // 1. Setup harness
    final harness = ScreenshotTestHarness(tester);
    final mockMessages = CopilotMockData.generateMockMessages();
    final textController = TextEditingController();
    final scrollController = ScrollController();

    // 2. Define View
    final copilotWidget = CopilotView(
      messages: mockMessages,
      textController: textController,
      scrollController: scrollController,
      isButtonEnabled: true,
      isRecording: false,
      micState: CopilotMicState.idle,
      isLoading: false,
      currentTier: SubscriptionTier.pro, // Show tokens
      tokenUsage: 1500,
      tokenLimit: 100000,
      onSendMessage: () {},
      onPickImage: () {},
      onCancelImage: () {},
      onToggleHistory: () {},
      onStopGeneration: () {},
      onHistoryToggle: (_) {},
      onEditMessage: (_, __) {},
      currentUserDisplayName: 'Dr. Copilot User',
      currentUserPhotoUrl: null, // Test default avatar
    );

    // 3. Define devices
    final devices = {
      'desktop': {
        '1920x1080': const Size(1920, 1080),
      },
      'mobile': {
        'iPhone14': const Size(390, 844),
      },
      'tablet': {
        'iPadPro': const Size(1024, 1366),
      },
    };

    // 4. Loop and capture
    final now = DateTime.now();
    // Use simple date string to avoid intl dependency issues in test
    final dateStr = now.toIso8601String().split('T')[0];

    for (final categoryEntry in devices.entries) {
      final categoryName = categoryEntry.key;
      final sizes = categoryEntry.value;

      for (final sizeEntry in sizes.entries) {
        final deviceName = sizeEntry.key;
        final size = sizeEntry.value;

        debugPrint('Capturing Copilot for $categoryName - $deviceName...');

        // Use hierarchical path
        final filename =
            '$categoryName/copilot_screen/04_copilot_screen_${dateStr}_$deviceName.png';

        try {
          // Harness handles App wrapping and Localization
          await harness.captureWidgetScreenshot(
            widget: copilotWidget,
            filename: filename,
            windowSize: size,
          );
        } catch (e) {
          debugPrint('Error capturing $filename: $e');
        }
      }
    }
  });
}
