import 'package:json_annotation/json_annotation.dart';

part 'assistant_action_model.g.dart';

/// Enum for different types of actions the assistant can perform
enum AssistantActionType {
  addPatient,
  addSession,
  addEvaluation,
  searchPatients,
  viewAppointments,
  viewFinancials,
  createCalendarEvent,
  showCharts,
  navigateToPage,
  unknown
}

/// Enum for action execution status
enum ActionExecutionStatus { pending, inProgress, completed, failed, cancelled }

/// Converter for AssistantActionType enum
class AssistantActionTypeConverter
    implements JsonConverter<AssistantActionType, String> {
  const AssistantActionTypeConverter();

  @override
  AssistantActionType fromJson(String json) {
    return AssistantActionType.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => AssistantActionType.unknown,
    );
  }

  @override
  String toJson(AssistantActionType object) {
    return object.toString().split('.').last;
  }
}

/// Converter for ActionExecutionStatus enum
class ActionExecutionStatusConverter
    implements JsonConverter<ActionExecutionStatus, String> {
  const ActionExecutionStatusConverter();

  @override
  ActionExecutionStatus fromJson(String json) {
    return ActionExecutionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => ActionExecutionStatus.pending,
    );
  }

  @override
  String toJson(ActionExecutionStatus object) {
    return object.toString().split('.').last;
  }
}

/// Model representing an action that the assistant can perform
@JsonSerializable()
class AssistantActionModel {
  final String id;
  final String sessionId;

  @AssistantActionTypeConverter()
  final AssistantActionType actionType;

  @ActionExecutionStatusConverter()
  final ActionExecutionStatus status;

  final String description;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic>? result;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? executedAt;
  final DateTime? completedAt;
  final bool requiresConfirmation;
  final bool isConfirmed;

  const AssistantActionModel({
    required this.id,
    required this.sessionId,
    required this.actionType,
    required this.status,
    required this.description,
    required this.parameters,
    this.result,
    this.errorMessage,
    required this.createdAt,
    this.executedAt,
    this.completedAt,
    required this.requiresConfirmation,
    required this.isConfirmed,
  });

  factory AssistantActionModel.fromJson(Map<String, dynamic> json) =>
      _$AssistantActionModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssistantActionModelToJson(this);

  AssistantActionModel copyWith({
    String? id,
    String? sessionId,
    AssistantActionType? actionType,
    ActionExecutionStatus? status,
    String? description,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? result,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? executedAt,
    DateTime? completedAt,
    bool? requiresConfirmation,
    bool? isConfirmed,
  }) {
    return AssistantActionModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      actionType: actionType ?? this.actionType,
      status: status ?? this.status,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      executedAt: executedAt ?? this.executedAt,
      completedAt: completedAt ?? this.completedAt,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  /// Create an action for adding a patient
  factory AssistantActionModel.addPatient({
    required String id,
    required String sessionId,
    required Map<String, dynamic> patientData,
    bool requiresConfirmation = true,
  }) {
    return AssistantActionModel(
      id: id,
      sessionId: sessionId,
      actionType: AssistantActionType.addPatient,
      status: ActionExecutionStatus.pending,
      description: 'Add new patient: ${patientData['name'] ?? 'Unknown'}',
      parameters: patientData,
      createdAt: DateTime.now(),
      requiresConfirmation: requiresConfirmation,
      isConfirmed: !requiresConfirmation,
    );
  }

  /// Create an action for adding a session
  factory AssistantActionModel.addSession({
    required String id,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    bool requiresConfirmation = true,
  }) {
    return AssistantActionModel(
      id: id,
      sessionId: sessionId,
      actionType: AssistantActionType.addSession,
      status: ActionExecutionStatus.pending,
      description:
          'Schedule session for: ${sessionData['patientName'] ?? 'Unknown patient'}',
      parameters: sessionData,
      createdAt: DateTime.now(),
      requiresConfirmation: requiresConfirmation,
      isConfirmed: !requiresConfirmation,
    );
  }

  /// Create an action for adding an evaluation
  factory AssistantActionModel.addEvaluation({
    required String id,
    required String sessionId,
    required Map<String, dynamic> evaluationData,
    bool requiresConfirmation = true,
  }) {
    return AssistantActionModel(
      id: id,
      sessionId: sessionId,
      actionType: AssistantActionType.addEvaluation,
      status: ActionExecutionStatus.pending,
      description:
          'Schedule evaluation for: ${evaluationData['patientName'] ?? 'Unknown patient'}',
      parameters: evaluationData,
      createdAt: DateTime.now(),
      requiresConfirmation: requiresConfirmation,
      isConfirmed: !requiresConfirmation,
    );
  }

  /// Create a navigation action
  factory AssistantActionModel.navigateToPage({
    required String id,
    required String sessionId,
    required String pageName,
    Map<String, dynamic>? pageParameters,
  }) {
    return AssistantActionModel(
      id: id,
      sessionId: sessionId,
      actionType: AssistantActionType.navigateToPage,
      status: ActionExecutionStatus.pending,
      description: 'Navigate to $pageName',
      parameters: {
        'pageName': pageName,
        'parameters': pageParameters ?? {},
      },
      createdAt: DateTime.now(),
      requiresConfirmation: false,
      isConfirmed: true,
    );
  }

  /// Mark action as confirmed
  AssistantActionModel confirm() {
    return copyWith(isConfirmed: true);
  }

  /// Mark action as in progress
  AssistantActionModel markInProgress() {
    return copyWith(
      status: ActionExecutionStatus.inProgress,
      executedAt: DateTime.now(),
    );
  }

  /// Mark action as completed
  AssistantActionModel markCompleted({Map<String, dynamic>? result}) {
    return copyWith(
      status: ActionExecutionStatus.completed,
      completedAt: DateTime.now(),
      result: result,
    );
  }

  /// Mark action as failed
  AssistantActionModel markFailed(String errorMessage) {
    return copyWith(
      status: ActionExecutionStatus.failed,
      errorMessage: errorMessage,
      completedAt: DateTime.now(),
    );
  }

  /// Check if action can be executed
  bool get canExecute =>
      status == ActionExecutionStatus.pending &&
      (!requiresConfirmation || isConfirmed);

  /// Check if action is completed
  bool get isCompleted => status == ActionExecutionStatus.completed;

  /// Check if action failed
  bool get isFailed => status == ActionExecutionStatus.failed;

  /// Check if action is in progress
  bool get isInProgress => status == ActionExecutionStatus.inProgress;

  /// Get human-readable action type
  String get actionTypeDisplayName {
    switch (actionType) {
      case AssistantActionType.addPatient:
        return 'Add Patient';
      case AssistantActionType.addSession:
        return 'Schedule Session';
      case AssistantActionType.addEvaluation:
        return 'Schedule Evaluation';
      case AssistantActionType.searchPatients:
        return 'Search Patients';
      case AssistantActionType.viewAppointments:
        return 'View Appointments';
      case AssistantActionType.viewFinancials:
        return 'View Financials';
      case AssistantActionType.createCalendarEvent:
        return 'Create Calendar Event';
      case AssistantActionType.showCharts:
        return 'Show Charts';
      case AssistantActionType.navigateToPage:
        return 'Navigate';
      case AssistantActionType.unknown:
        return 'Unknown Action';
    }
  }
}
