// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceMessageModel _$VoiceMessageModelFromJson(Map<String, dynamic> json) =>
    VoiceMessageModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      content: json['content'] as String,
      audioPath: json['audioPath'] as String?,
      audioDuration: (json['audioDuration'] as num?)?.toDouble(),
      type: const MessageTypeConverter().fromJson(json['type'] as String),
      status: const VoiceMessageStatusConverter()
          .fromJson(json['status'] as String),
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      actionType: json['actionType'] as String?,
      actionData: json['actionData'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      isProcessing: json['isProcessing'] as bool? ?? false,
    );

Map<String, dynamic> _$VoiceMessageModelToJson(VoiceMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'content': instance.content,
      'audioPath': instance.audioPath,
      'audioDuration': instance.audioDuration,
      'type': const MessageTypeConverter().toJson(instance.type),
      'status': const VoiceMessageStatusConverter().toJson(instance.status),
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'actionType': instance.actionType,
      'actionData': instance.actionData,
      'errorMessage': instance.errorMessage,
      'isProcessing': instance.isProcessing,
    };
