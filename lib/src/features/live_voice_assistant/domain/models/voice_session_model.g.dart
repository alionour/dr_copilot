// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSessionModel _$VoiceSessionModelFromJson(Map<String, dynamic> json) =>
    VoiceSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String?,
      status: const VoiceSessionStatusConverter()
          .fromJson(json['status'] as String),
      startTime: const TimestampConverter().fromJson(json['startTime']),
      endTime: const TimestampConverter().fromJson(json['endTime']),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => VoiceMessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      context: json['context'] as Map<String, dynamic>,
      selectedAiModel: json['selectedAiModel'] as String?,
      isActive: json['isActive'] as bool,
      messageCount: (json['messageCount'] as num).toInt(),
      totalDuration: (json['totalDuration'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$VoiceSessionModelToJson(VoiceSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'status': const VoiceSessionStatusConverter().toJson(instance.status),
      'startTime': const TimestampConverter().toJson(instance.startTime),
      'endTime': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.endTime, const TimestampConverter().toJson),
      'messages': instance.messages,
      'context': instance.context,
      'selectedAiModel': instance.selectedAiModel,
      'isActive': instance.isActive,
      'messageCount': instance.messageCount,
      'totalDuration': instance.totalDuration,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
