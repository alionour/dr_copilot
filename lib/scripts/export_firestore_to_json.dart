import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/scripts/onboarding_multi_clinic_migration.dart';


// Helper to convert Firestore data to JSON-encodable format
dynamic toEncodableFirestore(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  } else if (value is Map) {
    return value.map((k, v) => MapEntry(k, toEncodableFirestore(v)));
  } else if (value is List) {
    return value.map(toEncodableFirestore).toList();
  } else {
    return value;
  }
}


Future<void> exportFirestoreToJson(String filePath) async {
  final firestore = FirebaseFirestore.instance;
  final collections = [
    'users',
    'invoices',
    'patients',
    'evaluations',
    'sessions',
    'bills',
    'transactions',
    // Add more collections if needed
  ];
  final Map<String, List<Map<String, dynamic>>> exportData = {};
  print('Starting Firestore export...');
  for (final collection in collections) {
    try {
      print('Exporting collection: $collection');
      final snap = await firestore.collection(collection).get();
      print('Fetched ${snap.docs.length} documents from $collection');
      exportData[collection] = [
        for (final doc in snap.docs)
          {'id': doc.id, ...toEncodableFirestore(doc.data())}
      ];
    } catch (e, st) {
      print('Error exporting collection $collection: $e\n$st');
      exportData[collection] = [];
    }
  }
  try {
    final file = File(filePath);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
    print('Firestore export complete: $filePath');
  } catch (e, st) {
    print('Error writing export file: $e\n$st');
  }
}
