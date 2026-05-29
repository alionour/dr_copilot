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
      debugPrint('[FunctionCallHandler] handling: ${call.name} args: ${call.args}');
      late final Map<String, dynamic> result;
      switch (call.name) {
        // Patient Actions
        case 'add_patient':
          result = await _patientHandler.addPatient(call.args);
        case 'edit_patient':
          result = await _patientHandler.editPatient(call.args);
        case 'delete_patient':
          result = await _patientHandler.deletePatient(call.args);
        case 'get_patient':
          result = await _patientHandler.getPatient(call.args);
        case 'list_patients':
          result = await _patientHandler.listPatients(call.args);

        // Session Actions
        case 'add_session':
          result = await _sessionHandler.addSession(call.args);
        case 'edit_session':
          result = await _sessionHandler.editSession(call.args);
        case 'delete_session':
          result = await _sessionHandler.deleteSession(call.args);
        case 'get_session':
          result = await _sessionHandler.getSession(call.args);
        case 'list_sessions':
          result = await _sessionHandler.listSessions(call.args);

        // Evaluation Actions
        case 'add_evaluation':
          result = await _evaluationHandler.addEvaluation(call.args);
        case 'edit_evaluation':
          result = await _evaluationHandler.editEvaluation(call.args);
        case 'delete_evaluation':
          result = await _evaluationHandler.deleteEvaluation(call.args);
        case 'get_evaluation':
          result = await _evaluationHandler.getEvaluation(call.args);
        case 'list_evaluations':
          result = await _evaluationHandler.listEvaluations(call.args);

        default:
          result = {'error': 'Unknown function: ${call.name}'};
      }
      debugPrint('[FunctionCallHandler] ${call.name} result: ${result.keys.join(", ")}');
      return result;
    } catch (e, stack) {
      debugPrint('[FunctionCallHandler] !!! EXCEPTION during ${call.name}: $e');
      debugPrint('[FunctionCallHandler] Stack: $stack');
      return {'error': 'Error executing ${call.name}: $e'};
    }
  }
}
