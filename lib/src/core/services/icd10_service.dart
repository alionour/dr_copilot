import 'dart:convert';
import 'package:flutter/services.dart';

class ICD10Code {
  final String code;
  final String description;

  ICD10Code({required this.code, required this.description});

  factory ICD10Code.fromJson(Map<String, dynamic> json) {
    return ICD10Code(
      code: json['code'] as String,
      description: json['description'] as String,
    );
  }

  @override
  String toString() => '$code - $description';
}

class ICD10Service {
  static final ICD10Service _instance = ICD10Service._internal();
  factory ICD10Service() => _instance;
  ICD10Service._internal();

  List<ICD10Code>? _codes;

  Future<void> loadCodes() async {
    if (_codes != null) return; // Already loaded

    try {
      final String response =
          await rootBundle.loadString('assets/data/icd10_codes.json');
      final List<dynamic> data = json.decode(response);
      _codes = data.map((json) => ICD10Code.fromJson(json)).toList();
    } catch (e) {
      print('Error loading ICD-10 codes: $e');
      _codes = [];
    }
  }

  List<ICD10Code> searchCodes(String query) {
    if (_codes == null || query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return _codes!
        .where((code) {
          final codeMatch = code.code.toLowerCase().contains(lowerQuery);
          final descMatch = code.description.toLowerCase().contains(lowerQuery);
          return codeMatch || descMatch;
        })
        .take(20)
        .toList(); // Limit to 20 results
  }

  List<ICD10Code> getAllCodes() {
    return _codes ?? [];
  }
}
