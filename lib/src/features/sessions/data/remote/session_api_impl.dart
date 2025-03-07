import 'dart:convert';

import 'package:http/http.dart' as http;

class SessionApiImpl {
  static const String baseUrl = 'https://api-7hdpiv4e4q-uc.a.run.app/sessions';

  Future<void> addSession(Map<String, dynamic> sessionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sessionData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add session');
    }
  }

  Future<void> updateSession(
      String sessionId, Map<String, dynamic> sessionData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update/$sessionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sessionData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update session');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$sessionId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete session');
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await http.get(Uri.parse('$baseUrl/list'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load sessions');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
