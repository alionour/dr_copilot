import 'dart:io';
import 'dart:convert';

void main() async {
  print('Starting localization audit...\n');

  // Read translation files
  final enFile = File('assets/translations/en.json');
  final arFile = File('assets/translations/ar.json');

  if (!await enFile.exists() || !await arFile.exists()) {
    print('Error: Translation files not found');
    return;
  }

  final enJson =
      jsonDecode(await enFile.readAsString()) as Map<String, dynamic>;
  final arJson =
      jsonDecode(await arFile.readAsString()) as Map<String, dynamic>;

  final enKeys = enJson.keys.toSet();
  final arKeys = arJson.keys.toSet();

  // Find all Dart files
  final libDir = Directory('lib');
  final dartFiles = <File>[];

  await for (var entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      dartFiles.add(entity);
    }
  }

  print('Scanning ${dartFiles.length} Dart files...\n');

  final keysUsedInCode = <String>{};
  final hardcodedTexts = <Map<String, String>>[];

  int fileCount = 0;
  for (var file in dartFiles) {
    final content = await file.readAsString();
    final lines = content.split('\n');

    fileCount++;
    if (fileCount % 100 == 0) {
      print('  Processed $fileCount files...');
    }

    // Find .tr() keys - simple string search
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Match .tr() calls - look for string before .tr()
      if (line.contains('.tr()')) {
        // Extract keys using string manipulation
        final parts = line.split('.tr()');
        for (var part in parts) {
          // Find the last quoted string in this part
          final singleQuoteMatch = RegExp(r"'(\w+)'$").firstMatch(part);
          final doubleQuoteMatch = RegExp(r'"(\w+)"$').firstMatch(part);

          if (singleQuoteMatch != null) {
            keysUsedInCode.add(singleQuoteMatch.group(1)!);
          } else if (doubleQuoteMatch != null) {
            keysUsedInCode.add(doubleQuoteMatch.group(1)!);
          }
        }
      }

      // Find potential hardcoded Text widgets
      if (line.contains('Text(') && !line.contains('.tr()')) {
        // Simple pattern for Text("...")
        final pattern = RegExp(r'Text\s*\(\s*"([^"]{3,}?)"');
        final matches = pattern.allMatches(line);
        for (var match in matches) {
          final text = match.group(1)!;
          // Filter out likely variables and special cases
          if (!text.startsWith(r'$') &&
              !text.contains('{') &&
              !text.contains(r'\\') &&
              !text.contains(r'/') &&
              text.length > 2) {
            hardcodedTexts.add({
              'file': file.path.replaceAll(r'\', '/'),
              'line': (i + 1).toString(),
              'text': text,
            });
          }
        }
      }
    }
  }

  // Find missing keys
  final missingInEn = keysUsedInCode.difference(enKeys);
  final missingInAr = keysUsedInCode.difference(arKeys);
  final onlyInEn = enKeys.difference(arKeys);
  final onlyInAr = arKeys.difference(enKeys);

  print('\n=== LOCALIZATION AUDIT REPORT ===\n');

  print('📊 Statistics:');
  print('  - Keys used in code: ${keysUsedInCode.length}');
  print('  - Keys in en.json: ${enKeys.length}');
  print('  - Keys in ar.json: ${arKeys.length}');
  print('  - Potential hardcoded texts found: ${hardcodedTexts.length}');
  print('');

  if (missingInEn.isNotEmpty) {
    print('❌ MISSING IN en.json (${missingInEn.length} keys):');
    final sorted = missingInEn.toList()..sort();
    for (var key in sorted.take(30)) {
      print('  - $key');
    }
    if (sorted.length > 30) {
      print('  ... and ${sorted.length - 30} more');
    }
    print('');
  } else {
    print('✅ No missing keys in en.json\n');
  }

  if (missingInAr.isNotEmpty) {
    print('❌ MISSING IN ar.json (${missingInAr.length} keys):');
    final sorted = missingInAr.toList()..sort();
    for (var key in sorted.take(30)) {
      print('  - $key');
    }
    if (sorted.length > 30) {
      print('  ... and ${sorted.length - 30} more');
    }
    print('');
  } else {
    print('✅ No missing keys in ar.json\n');
  }

  if (onlyInEn.isNotEmpty) {
    print('⚠️  Keys only in en.json (${onlyInEn.length} keys):');
    final sorted = onlyInEn.toList()..sort();
    for (var key in sorted.take(20)) {
      print('  - $key');
    }
    if (sorted.length > 20) {
      print('  ... and ${sorted.length - 20} more');
    }
    print('');
  }

  if (onlyInAr.isNotEmpty) {
    print('⚠️  Keys only in ar.json (${onlyInAr.length} keys):');
    final sorted = onlyInAr.toList()..sort();
    for (var key in sorted.take(20)) {
      print('  - $key');
    }
    if (sorted.length > 20) {
      print('  ... and ${sorted.length - 20} more');
    }
    print('');
  }

  if (hardcodedTexts.isNotEmpty) {
    print(
        '⚠️  POTENTIAL HARDCODED TEXTS (sample of ${hardcodedTexts.length}):');
    for (var item in hardcodedTexts.take(30)) {
      print('  - ${item['file']}:${item['line']} -> "${item['text']}"');
    }
    if (hardcodedTexts.length > 30) {
      print('  ... and ${hardcodedTexts.length - 30} more');
    }
    print('');
  }

  // Save detailed report
  try {
    final reportFile = File('localization_audit_report.txt');
    final report = StringBuffer();
    report.writeln('================================');
    report.writeln('LOCALIZATION AUDIT REPORT');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('================================\n');

    report.writeln('STATISTICS:');
    report.writeln('  Keys used in code: ${keysUsedInCode.length}');
    report.writeln('  Keys in en.json: ${enKeys.length}');
    report.writeln('  Keys in ar.json: ${arKeys.length}');
    report.writeln('  Hardcoded texts: ${hardcodedTexts.length}\n');

    report.writeln('MISSING IN EN.JSON (${missingInEn.length}):');
    report.writeln('=' * 50);
    for (var key in missingInEn.toList()..sort()) {
      report.writeln(key);
    }

    report.writeln('\nMISSING IN AR.JSON (${missingInAr.length}):');
    report.writeln('=' * 50);
    for (var key in missingInAr.toList()..sort()) {
      report.writeln(key);
    }

    report.writeln('\nKEYS ONLY IN EN.JSON (${onlyInEn.length}):');
    report.writeln('=' * 50);
    for (var key in onlyInEn.toList()..sort()) {
      report.writeln(key);
    }

    report.writeln('\nKEYS ONLY IN AR.JSON (${onlyInAr.length}):');
    report.writeln('=' * 50);
    for (var key in onlyInAr.toList()..sort()) {
      report.writeln(key);
    }

    report.writeln('\nHARDCODED TEXTS (${hardcodedTexts.length}):');
    report.writeln('=' * 50);
    for (var item in hardcodedTexts) {
      report.writeln('${item['file']}:${item['line']} -> "${item['text']}"');
    }

    await reportFile.writeAsString(report.toString());
    print('📝 Detailed report saved to: localization_audit_report.txt');
  } catch (e) {
    print('Failed to save report: $e');
  }

  print('\nAudit complete!');
}
