import 'dart:convert';

import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:http/http.dart' as http;

import 'abstract_patient_api.dart';

/// A class that implements the AbstractPatientApi with real API data.
class PatientImplApi implements AbstractPatientApi {
  final String apiUrl;

  PatientImplApi(this.apiUrl);

  /// Fetches a list of patients from the API.
  @override
  Future<List<PatientModel>> fetchPatients() async {
    final response = await http.get(Uri.parse('$apiUrl/patients'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => PatientModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load patients');
    }
  }

  /// Adds a new patient to the API.
  @override
  Future<PatientModel> addPatient(PatientModel patient) async {
    final response = await http.post(
      Uri.parse('$apiUrl/patients'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 201) {
      return PatientModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add patient');
    }
  }

  /// Updates an existing patient in the API.
  @override
  Future<PatientModel> updatePatient(PatientModel patient) async {
    final response = await http.put(
      Uri.parse('$apiUrl/patients/${patient.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 200) {
      return PatientModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update patient');
    }
  }

  /// Deletes a patient by their ID from the API.
  @override
  Future<void> deletePatient(String patientId) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/patients/$patientId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete patient');
    }
  }
}
