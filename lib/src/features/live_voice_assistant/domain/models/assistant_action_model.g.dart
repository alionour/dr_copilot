// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_action_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistantActionModel _$AssistantActionModelFromJson(
        Map<String, dynamic> json) =>
    AssistantActionModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      actionType: const AssistantActionTypeConverter()
          .fromJson(json['actionType'] as String),
      status: const ActionExecutionStatusConverter()
          .fromJson(json['status'] as String),
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      result: json['result'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      executedAt: json['executedAt'] == null
          ? null
          : DateTime.parse(json['executedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      requiresConfirmation: json['requiresConfirmation'] as bool,
      isConfirmed: json['isConfirmed'] as bool,
    );

Map<String, dynamic> _$AssistantActionModelToJson(
        AssistantActionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'actionType':
          const AssistantActionTypeConverter().toJson(instance.actionType),
      'status': const ActionExecutionStatusConverter().toJson(instance.status),
      'description': instance.description,
      'parameters': instance.parameters,
      'result': instance.result,
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'executedAt': instance.executedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'requiresConfirmation': instance.requiresConfirmation,
      'isConfirmed': instance.isConfirmed,
    };
