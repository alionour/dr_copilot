import 'dart:convert';

import 'package:http/http.dart' as http;

class EvaluationApiImpl {
  static const String baseUrl =
      'https://api-7hdpiv4e4q-uc.a.run.app/evaluations';

  Future<void> addEvaluation(Map<String, dynamic> evaluationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evaluationData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add evaluation');
    }
  }

  Future<void> updateEvaluation(
      String evaluationId, Map<String, dynamic> evaluationData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update/$evaluationId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evaluationData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update evaluation');
    }
  }

  Future<void> deleteEvaluation(String evaluationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$evaluationId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete evaluation');
    }
  }

  Future<List<Map<String, dynamic>>> getEvaluations() async {
    final response = await http.get(Uri.parse('$baseUrl/list'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load evaluations');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
