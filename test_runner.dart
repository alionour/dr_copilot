#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:developer' as developer;

/// Test runner script for Dr Copilot Flutter project
///
/// This script provides convenient commands to run different types of tests:
/// - Unit tests
/// - Widget tests
/// - Integration tests
/// - All tests with coverage
/// - Performance tests
/// - Specific feature tests
///
/// Usage:
/// dart test_runner.dart [command] [options]
///
/// Commands:
/// - unit: Run only unit tests
/// - widget: Run only widget tests
/// - integration: Run only integration tests
/// - all: Run all tests
/// - coverage: Run all tests with coverage report
/// - performance: Run performance tests
/// - feature [name]: Run tests for specific feature
/// - auth: Run authentication flow tests
/// - patients: Run patient management tests
/// - financials: Run financial management tests
/// - copilot: Run AI copilot tests
/// - smoke: Run smoke tests (quick validation)
/// - regression: Run regression test suite
/// - help: Show this help message

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('help')) {
    printHelp();
    return;
  }

  final command = arguments.first.toLowerCase();

  switch (command) {
    case 'unit':
      await runUnitTests();
      break;
    case 'widget':
      await runWidgetTests();
      break;
    case 'integration':
      await runIntegrationTests();
      break;
    case 'all':
      await runAllTests();
      break;
    case 'coverage':
      await runTestsWithCoverage();
      break;
    case 'performance':
      await runPerformanceTests();
      break;
    case 'auth':
      await runAuthTests();
      break;
    case 'patients':
      await runPatientTests();
      break;
    case 'financials':
      await runFinancialTests();
      break;
    case 'copilot':
      await runCopilotTests();
      break;
    case 'smoke':
      await runSmokeTests();
      break;
    case 'regression':
      await runRegressionTests();
      break;
    case 'feature':
      if (arguments.length > 1) {
        await runFeatureTests(arguments[1]);
      } else {
        developer.log('Please specify a feature name', name: 'TestRunner');
        exit(1);
      }
      break;
    default:
      developer.log('Unknown command: $command', name: 'TestRunner');
      printHelp();
      exit(1);
  }
}

/// Helper function to log test runner messages
void logMessage(String message) {
  developer.log(message, name: 'TestRunner');
}

/// Helper function to log test results
void logResult(String message, {bool success = true}) {
  final emoji = success ? '✅' : '❌';
  developer.log('$emoji $message', name: 'TestRunner');
}

/// Helper function to log test steps
void logStep(String message) {
  developer.log('🧪 $message', name: 'TestRunner');
}

void printHelp() {
  const helpText = '''
Dr Copilot Test Runner

Usage: dart test_runner.dart [command]

Commands:
  unit        Run only unit tests (domain, data layer tests)
  widget      Run only widget tests (presentation layer UI tests)
  integration Run only integration tests (end-to-end tests)
  all         Run all tests
  coverage    Run all tests with coverage report
  help        Show this help message

Examples:
  dart test_runner.dart unit
  dart test_runner.dart coverage
  dart test_runner.dart all
''';
  developer.log(helpText, name: 'TestRunner');
}

Future<void> runUnitTests() async {
  print('🧪 Running Unit Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/core/',
      'test/src/features/*/domain/',
      'test/src/features/*/data/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Unit tests passed!');
  } else {
    print('❌ Unit tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runWidgetTests() async {
  print('🎨 Running Widget Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/*/presentation/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Widget tests passed!');
  } else {
    print('❌ Widget tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runIntegrationTests() async {
  print('🔗 Running Integration Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'integration_test/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Integration tests passed!');
  } else {
    print('❌ Integration tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runAllTests() async {
  print('🚀 Running All Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ All tests passed!');
  } else {
    print('❌ Some tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runTestsWithCoverage() async {
  print('📊 Running Tests with Coverage...');

  // Run tests with coverage
  final testResult = await Process.run(
    'flutter',
    [
      'test',
      '--coverage',
      '--reporter=expanded',
    ],
  );

  print(testResult.stdout);
  if (testResult.stderr.isNotEmpty) {
    print('Errors: ${testResult.stderr}');
  }

  if (testResult.exitCode != 0) {
    print('❌ Tests failed!');
    exit(testResult.exitCode);
  }

  // Generate HTML coverage report
  print('📈 Generating coverage report...');

  final coverageResult = await Process.run(
    'genhtml',
    [
      'coverage/lcov.info',
      '-o',
      'coverage/html',
    ],
  );

  if (coverageResult.exitCode == 0) {
    print('✅ Coverage report generated at coverage/html/index.html');

    // Try to open the coverage report
    if (Platform.isWindows) {
      await Process.run('start', ['coverage/html/index.html'],
          runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['coverage/html/index.html']);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', ['coverage/html/index.html']);
    }
  } else {
    print(
        '⚠️  Could not generate HTML coverage report. Install lcov for HTML reports.');
    print('Coverage data available at: coverage/lcov.info');
  }

  print('✅ Tests with coverage completed!');
}

Future<void> runPerformanceTests() async {
  print('⚡ Running Performance Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/',
      '--tags=performance',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Performance tests passed!');
  } else {
    print('❌ Performance tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runAuthTests() async {
  print('🔐 Running Authentication Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/auth/',
      'integration_test/auth_flow_test.dart',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Authentication tests passed!');
  } else {
    print('❌ Authentication tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runPatientTests() async {
  print('👥 Running Patient Management Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/patients/',
      'integration_test/patient_management_test.dart',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Patient management tests passed!');
  } else {
    print('❌ Patient management tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runFinancialTests() async {
  print('💰 Running Financial Management Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/financials/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Financial management tests passed!');
  } else {
    print('❌ Financial management tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runCopilotTests() async {
  print('🤖 Running AI Copilot Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/copilot_chat/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ AI Copilot tests passed!');
  } else {
    print('❌ AI Copilot tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runSmokeTests() async {
  print('💨 Running Smoke Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      '--tags=smoke',
      'test/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Smoke tests passed!');
  } else {
    print('❌ Smoke tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runRegressionTests() async {
  print('🔄 Running Regression Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      '--tags=regression',
      'test/',
      'integration_test/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Regression tests passed!');
  } else {
    print('❌ Regression tests failed!');
    exit(result.exitCode);
  }
}

Future<void> runFeatureTests(String featureName) async {
  print('🎯 Running $featureName Feature Tests...');

  final result = await Process.run(
    'flutter',
    [
      'test',
      '--reporter=expanded',
      'test/src/features/$featureName/',
    ],
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ $featureName feature tests passed!');
  } else {
    print('❌ $featureName feature tests failed!');
    exit(result.exitCode);
  }
}
