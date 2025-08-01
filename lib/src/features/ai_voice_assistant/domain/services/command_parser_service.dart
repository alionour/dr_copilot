import 'dart:convert';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:uuid/uuid.dart';

import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';

class CommandParser.dart';

class CommandParserService {
  final GeminiService _geminiService;
  final PatientsUseCase _patientsUseCase;
  final SessionsUseCase _sessionsUseCase;
  final EvaluationsUseCase _evaluationsUseCase;
  final FinancialsUseCase _financialsUseCase;
  final FirebaseAuth _firebaseAuth;

  CommandParserService(
      this._geminiService,
      this._patientsUseCase,
      this._sessionsUseCase,
      this._evaluationsUseCase,
      this._financialsUseCase,
      this._firebaseAuth);

  Future<void> parseCommand(String command) async {
    final prompt = """
      You are a command parser for a medical assistant app.
      Your task is to parse the user's voice command and extract the intent and the entities.
      The output should be a JSON object with the following structure:
      {
        "intent": "intent_name",
        "entities": {
          "entity_name": "entity_value",
          ...
        }
      }

      Here are the possible intents and their entities:
      - add_patient:
        - name (string)
        - age (integer)
        - phone (string)
        - address (string)
        - gender (string)
      - schedule_session:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
        - time (string, in HH:MM format)
      - record_evaluation:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
      - show_appointments:
        - date (string, in YYYY-MM-DD format, e.g., "today", "tomorrow")
      - show_revenue:
        - period (string, e.g., "this month", "last month")

      User command: "$command"

      JSON output:
    """;

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse = response.parts.map((part) => (part as TextPart).text).join('');
    final decoded = jsonDecode(jsonResponse);

    final intent = decoded['intent'];
    final entities = decoded['entities'];

    switch (intent) {
      case 'add_patient':
        final user = _firebaseAuth.currentUser;
        if (user == null) {
          // Handle user not logged in
          return;
        }

        final patient = PatientModel(
          id: Uuid().v4(),
          name: entities['name'],
          age: entities['age'],
          phoneNumber: entities['phone'],
          address: entities['address'],
          gender: entities['gender'],
          userId: user.uid,
        );
        await _patientsUseCase.addPatient(patient);
        break;
      case 'schedule_session':
        final patientName = entities['patient_name'];
        final date = entities['date'];
        final time = entities['time'];

        final failureOrPatients =
            await _patientsUseCase.searchPatients(name: patientName);
        failureOrPatients.fold(
          (failure) {
            print('Error searching for patient: $failure');
          },
          (patients) async {
            if (patients.isEmpty) {
              print('Patient not found: $patientName');
              return;
            }
            final patient = patients.first;
            final user = _firebaseAuth.currentUser;
            if (user == null) {
              return;
            }

            final startDateTime = DateTime.parse('$date $time');
            final endDateTime = startDateTime.add(const Duration(hours: 1));

            final session = SessionModel(
              id: Uuid().v4(),
              patientId: patient.id,
              price: SessionType.standard.basePrice,
              startDateTime: Timestamp.fromDate(startDateTime),
              endDateTime: Timestamp.fromDate(endDateTime),
              sessionType: SessionType.standard,
              userId: user.uid,
              createdBy: user.uid,
              patientName: patient.name,
            );
            await _sessionsUseCase.addSession(session);
          },
        );
        break;
      case 'record_evaluation':
        final patientName = entities['patient_name'];
        final date = entities['date'];

        final failureOrPatients =
            await _patientsUseCase.searchPatients(name: patientName);
        failureOrPatients.fold(
          (failure) {
            print('Error searching for patient: $failure');
          },
          (patients) async {
            if (patients.isEmpty) {
              print('Patient not found: $patientName');
              return;
            }
            final patient = patients.first;
            final user = _firebaseAuth.currentUser;
            if (user == null) {
              return;
            }

            final startDateTime = DateTime.parse('$date 09:00:00');
            final endDateTime = startDateTime.add(const Duration(hours: 1));

            final evaluation = EvaluationModel(
              id: Uuid().v4(),
              patientId: patient.id,
              patientName: patient.name,
              price: 200.0,
              startDateTime: Timestamp.fromDate(startDateTime),
              endDateTime: Timestamp.fromDate(endDateTime),
              userId: user.uid,
              createdBy: user.uid,
            );
            await _evaluationsUseCase.addEvaluation(evaluation);
          },
        );
        break;
      case 'show_appointments':
        final dateString = entities['date'];
        DateTime date;
        if (dateString == 'today') {
          date = DateTime.now();
        } else if (dateString == 'tomorrow') {
          date = DateTime.now().add(const Duration(days: 1));
        } else {
          date = DateTime.parse(dateString);
        }

        final failureOrSessions = await _sessionsUseCase.getSessionsByDate(date);
        final failureOrEvaluations =
            await _evaluationsUseCase.getEvaluationsByDate(date);

        failureOrSessions.fold(
          (failure) => print('Error getting sessions: $failure'),
          (sessions) {
            failureOrEvaluations.fold(
              (failure) => print('Error getting evaluations: $failure'),
              (evaluations) {
                final appointments = [...sessions, ...evaluations];
                print('Appointments for $date:');
                for (final appointment in appointments) {
                  print((appointment as dynamic).toJson());
                }
              },
            );
          },
        );
        break;
      case 'show_revenue':
        final period = entities['period'];
        if (period == 'this month') {
          final now = DateTime.now();
          final firstDayOfMonth = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

          final failureOrTransactions =
              await _financialsUseCase.getTransactions();
          failureOrTransactions.fold(
            (failure) => print('Error getting transactions: $failure'),
            (transactions) {
              final monthlyTransactions = transactions.where((t) {
                final transactionDate = t.transactionDate.toDate();
                return transactionDate.isAfter(firstDayOfMonth) &&
                    transactionDate.isBefore(lastDayOfMonth);
              }).toList();

              final totalRevenue = monthlyTransactions.fold<double>(
                  0, (sum, t) => sum + t.amount);
              print('Total revenue for this month: $totalRevenue');
            },
          );
        }
        break;
      // TODO: Handle other intents
    }
  }
}
