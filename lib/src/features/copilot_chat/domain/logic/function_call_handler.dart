import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

class FunctionCallHandler {
  final PatientsUseCase patientsUseCase;
  final SessionsUseCase sessionsUseCase;
  final EvaluationsUseCase evaluationsUseCase;
  final OwnerNotifier ownerNotifier;

  FunctionCallHandler({
    required this.patientsUseCase,
    required this.sessionsUseCase,
    required this.evaluationsUseCase,
    required this.ownerNotifier,
  });

  Future<Map<String, dynamic>> handleFunctionCall(FunctionCall call) async {
    try {
      switch (call.name) {
        case 'add_patient':
          return await _addPatient(call.args);
        case 'edit_patient':
          return await _editPatient(call.args);
        case 'delete_patient':
          return await _deletePatient(call.args);
        case 'get_patient':
          return await _getPatient(call.args);
        case 'list_patients':
          return await _listPatients(call.args);
        case 'add_session':
          return await _addSession(call.args);
        case 'edit_session':
          return await _editSession(call.args);
        case 'delete_session':
          return await _deleteSession(call.args);
        case 'get_session':
          return await _getSession(call.args);
        case 'list_sessions':
          return await _listSessions(call.args);
        case 'add_evaluation':
          return await _addEvaluation(call.args);
        case 'edit_evaluation':
          return await _editEvaluation(call.args);
        case 'delete_evaluation':
          return await _deleteEvaluation(call.args);
        case 'get_evaluation':
          return await _getEvaluation(call.args);
        case 'list_evaluations':
          return await _listEvaluations(call.args);
        default:
          return {'error': 'Unknown function: ${call.name}'};
      }
    } catch (e) {
      return {'error': 'Error executing ${call.name}: $e'};
    }
  }

  Future<Map<String, dynamic>> _addPatient(Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;

    if (ownerId == null || clinicId == null) {
      return {'error': 'Owner ID or Clinic ID not available.'};
    }

    final patient = PatientModel(
      id: const Uuid().v4(),
      name: args['name'],
      age: args['age'],
      gender: args['gender'],
      address: args['address'],
      phoneNumber: args['phoneNumber'],
      alternativePhoneNumber: args['alternativePhoneNumber'],
      treatingDoctor: args['treatingDoctor'],
      occupation: args['occupation'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime.now()),
    );

    final result = await patientsUseCase.addPatient(patient);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Patient added successfully',
        'id': patient.id
      },
    );
  }

  Future<Map<String, dynamic>> _editPatient(Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;

    if (ownerId == null || clinicId == null) {
      return {'error': 'Owner ID or Clinic ID not available.'};
    }

    final patient = PatientModel(
      id: args['id'],
      name: args['name'] ?? '',
      age: args['age'],
      gender: args['gender'],
      address: args['address'],
      phoneNumber: args['phoneNumber'],
      alternativePhoneNumber: args['alternativePhoneNumber'],
      treatingDoctor: args['treatingDoctor'],
      occupation: args['occupation'],
      ownerId: ownerId,
      clinicId: clinicId,
      updatedAt: Timestamp.fromDate(DateTime.now()),
      createdAt: Timestamp.fromDate(
          DateTime.now()), // Dummy, won't be used for update usually
    );

    final result = await patientsUseCase.updatePatient(patient.id, patient);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Patient updated successfully'},
    );
  }

  Future<Map<String, dynamic>> _deletePatient(Map<String, dynamic> args) async {
    final result = await patientsUseCase.deletePatient(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Patient deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> _getPatient(Map<String, dynamic> args) async {
    if (args['id'] != null) {
      final result = await patientsUseCase.getPatientById(args['id']);
      return result.fold(
        (failure) => {'error': failure.message},
        (patient) => patient.toJson(),
      );
    } else if (args['name'] != null) {
      final result = await patientsUseCase.searchPatients(name: args['name']);
      return result.fold(
        (failure) => {'error': failure.message},
        (patients) {
          if (patients.isNotEmpty) {
            return patients.first.toJson();
          } else {
            return {'error': 'Patient not found'};
          }
        },
      );
    }
    return {'error': 'Missing id or name'};
  }

  Future<Map<String, dynamic>> _listPatients(Map<String, dynamic> args) async {
    final result = await patientsUseCase.getAllPatients();
    return result.fold(
      (failure) => {'error': failure.message},
      (patients) {
        if (args['name'] != null) {
          final filtered = patients
              .where((p) => p.name
                  .toLowerCase()
                  .contains((args['name'] as String).toLowerCase()))
              .toList();
          return {'patients': filtered.map((p) => p.toJson()).toList()};
        }
        return {'patients': patients.map((p) => p.toJson()).toList()};
      },
    );
  }

  Future<Map<String, dynamic>> _addSession(Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final createdBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || createdBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final session = SessionModel(
      id: const Uuid().v4(),
      patientId: args['patientId'],
      price: (args['price'] as num).toDouble(),
      startDateTime: Timestamp.fromDate(DateTime.parse(args['startDateTime'])),
      endDateTime: Timestamp.fromDate(DateTime.parse(args['endDateTime'])),
      sessionType: args['sessionType'] ?? 'standard',
      patientName: args['patientName'],
      doctorId: args['doctorId'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdBy: createdBy,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime
          .now()), // SessionModel seems to use Timestamp for updatedAt too based on errors?
    );

    final result = await sessionsUseCase.addSession(session);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Session added successfully',
        'id': session.id
      },
    );
  }

  Future<Map<String, dynamic>> _editSession(Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final updatedBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || updatedBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    // Fetch existing session first to be safe, but for now constructing minimal update
    // Assuming updateSession handles partial updates or we provide full object
    // Based on previous code, we need to fetch it first.

    final result = await sessionsUseCase.getSessionById(args['id']);

    return result.fold(
      (failure) => {'error': failure.message},
      (existingSession) async {
        final updatedSession = existingSession.copyWith(
          patientId: args['patientId'],
          price: (args['price'] as num?)?.toDouble(),
          startDateTime: args['startDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['startDateTime']))
              : null,
          endDateTime: args['endDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['endDateTime']))
              : null,
          sessionType: args['sessionType'],
          patientName: args['patientName'],
          doctorId: args['doctorId'],
          updatedBy: updatedBy,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );

        final updateResult =
            await sessionsUseCase.updateSession(args['id'], updatedSession);
        return updateResult.fold(
          (failure) => {'error': failure.message},
          (success) =>
              {'status': 'success', 'message': 'Session updated successfully'},
        );
      },
    );
  }

  Future<Map<String, dynamic>> _deleteSession(Map<String, dynamic> args) async {
    final result = await sessionsUseCase.deleteSession(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Session deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> _getSession(Map<String, dynamic> args) async {
    final result = await sessionsUseCase.getSessionById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (session) => session.toJson(),
    );
  }

  Future<Map<String, dynamic>> _listSessions(Map<String, dynamic> args) async {
    final result = await sessionsUseCase
        .getAllSessions(); // Assuming getAllSessions exists
    return result.fold(
      (failure) => {'error': failure.message},
      (sessions) {
        var filtered = sessions;
        if (args['patientName'] != null) {
          filtered = filtered
              .where((s) => (s.patientName ?? '')
                  .toLowerCase()
                  .contains((args['patientName'] as String).toLowerCase()))
              .toList();
        }
        return {'sessions': filtered.map((s) => s.toJson()).toList()};
      },
    );
  }

  Future<Map<String, dynamic>> _addEvaluation(Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final createdBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || createdBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final evaluation = EvaluationModel(
      id: const Uuid().v4(),
      patientId: args['patientId'],
      patientName: args['patientName'],
      price: (args['price'] as num).toDouble(),
      startDateTime: Timestamp.fromDate(DateTime.parse(args['startDateTime'])),
      endDateTime: Timestamp.fromDate(DateTime.parse(args['endDateTime'])),
      doctorId: args['doctorId'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdBy: createdBy,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime.now()),
    );

    final result = await evaluationsUseCase.addEvaluation(evaluation);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Evaluation added successfully',
        'id': evaluation.id
      },
    );
  }

  Future<Map<String, dynamic>> _editEvaluation(
      Map<String, dynamic> args) async {
    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final updatedBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || updatedBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final result = await evaluationsUseCase.getEvaluationById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (existingEvaluation) async {
        final updatedEvaluation = existingEvaluation.copyWith(
          patientId: args['patientId'],
          patientName: args['patientName'],
          price: (args['price'] as num?)?.toDouble(),
          startDateTime: args['startDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['startDateTime']))
              : null,
          endDateTime: args['endDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['endDateTime']))
              : null,
          doctorId: args['doctorId'],
          updatedBy: updatedBy,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );

        final updateResult = await evaluationsUseCase.updateEvaluation(
            args['id'], updatedEvaluation);
        return updateResult.fold(
          (failure) => {'error': failure.message},
          (success) => {
            'status': 'success',
            'message': 'Evaluation updated successfully'
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _deleteEvaluation(
      Map<String, dynamic> args) async {
    final result = await evaluationsUseCase.deleteEvaluation(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Evaluation deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> _getEvaluation(Map<String, dynamic> args) async {
    final result = await evaluationsUseCase.getEvaluationById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (evaluation) => evaluation.toJson(),
    );
  }

  Future<Map<String, dynamic>> _listEvaluations(
      Map<String, dynamic> args) async {
    final result = await evaluationsUseCase
        .getAllEvaluations(); // Assuming getAllEvaluations exists
    return result.fold(
      (failure) => {'error': failure.message},
      (evaluations) {
        var filtered = evaluations;
        if (args['patientName'] != null) {
          filtered = filtered
              .where((e) => e.patientName
                  .toLowerCase()
                  .contains((args['patientName'] as String).toLowerCase()))
              .toList();
        }
        return {'evaluations': filtered.map((e) => e.toJson()).toList()};
      },
    );
  }
}
