import 'package:dr_copilot/src/features/copilot_chat/domain/logic/handlers/evaluation_action_handler.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/handlers/patient_action_handler.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/handlers/session_action_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FunctionCallHandler {
  final PatientActionHandler _patientHandler;
  final SessionActionHandler _sessionHandler;
  final EvaluationActionHandler _evaluationHandler;

  FunctionCallHandler({
    required PatientsUseCase patientsUseCase,
    required SessionsUseCase sessionsUseCase,
    required EvaluationsUseCase evaluationsUseCase,
    required OwnerNotifier ownerNotifier,
    required PermissionService permissionService,
  })  : _patientHandler = PatientActionHandler(
          patientsUseCase: patientsUseCase,
          ownerNotifier: ownerNotifier,
          permissionService: permissionService,
        ),
        _sessionHandler = SessionActionHandler(
          sessionsUseCase: sessionsUseCase,
          ownerNotifier: ownerNotifier,
          permissionService: permissionService,
        ),
        _evaluationHandler = EvaluationActionHandler(
          evaluationsUseCase: evaluationsUseCase,
          ownerNotifier: ownerNotifier,
          permissionService: permissionService,
        );

  Future<Map<String, dynamic>> handleFunctionCall(FunctionCall call) async {
    try {
      debugPrint('[FunctionCallHandler] handling: ${call.name}');
      switch (call.name) {
        // Patient Actions
        case 'add_patient':
          return await _patientHandler.addPatient(call.args);
        case 'edit_patient':
          return await _patientHandler.editPatient(call.args);
        case 'delete_patient':
          return await _patientHandler.deletePatient(call.args);
        case 'get_patient':
          return await _patientHandler.getPatient(call.args);
        case 'list_patients':
          return await _patientHandler.listPatients(call.args);

        // Session Actions
        case 'add_session':
          return await _sessionHandler.addSession(call.args);
        case 'edit_session':
          return await _sessionHandler.editSession(call.args);
        case 'delete_session':
          return await _sessionHandler.deleteSession(call.args);
        case 'get_session':
          return await _sessionHandler.getSession(call.args);
        case 'list_sessions':
          return await _sessionHandler.listSessions(call.args);

        // Evaluation Actions
        case 'add_evaluation':
          return await _evaluationHandler.addEvaluation(call.args);
        case 'edit_evaluation':
          return await _evaluationHandler.editEvaluation(call.args);
        case 'delete_evaluation':
          return await _evaluationHandler.deleteEvaluation(call.args);
        case 'get_evaluation':
          return await _evaluationHandler.getEvaluation(call.args);
        case 'list_evaluations':
          return await _evaluationHandler.listEvaluations(call.args);

        default:
          return {'error': 'Unknown function: ${call.name}'};
      }
    } catch (e) {
      return {'error': 'Error executing ${call.name}: $e'};
    }
  }
}
