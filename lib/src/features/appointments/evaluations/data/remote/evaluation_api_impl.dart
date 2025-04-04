import 'dart:convert';

import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:http/http.dart' as http;

class EvaluationApiImpl {
  static const String baseUrl = 'https://api-7hdpiv4e4q-uc.a.run.app/evaluations';

  Future<void> addEvaluation(EvaluationModel evaluation) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evaluation.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add evaluation');
    }
  }

  Future<void> updateEvaluation(String id, EvaluationModel evaluation) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evaluation.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update evaluation');
    }
  }

  Future<void> deleteEvaluation(String evaluationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$evaluationId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete evaluation');
    }
  }

  Future<List<EvaluationModel>> getEvaluations() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load evaluations');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => EvaluationModel.fromJson(json)).toList();
  }
}
