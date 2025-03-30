import 'dart:convert';

import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:http/http.dart' as http;

class SessionApiImpl {
  static const String baseUrl = 'https://api-7hdpiv4e4q-uc.a.run.app/sessions';

  Future<void> addSession(SessionModel session) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(session.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add session');
    }
  }

  Future<void> updateSession(SessionModel session) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${session.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(session.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update session');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$sessionId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete session');
    }
  }

  Future<List<SessionModel>> getSessions() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load sessions');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => SessionModel.fromJson(json)).toList();
  }
}
