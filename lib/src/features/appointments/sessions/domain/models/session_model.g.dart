// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      sessionType: $enumDecode(_$SessionTypeEnumMap, json['sessionType']),
    );

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientName': instance.patientName,
      'price': instance.price,
      'startDateTime': instance.startDateTime.toIso8601String(),
      'endDateTime': instance.endDateTime.toIso8601String(),
      'sessionType': _$SessionTypeEnumMap[instance.sessionType]!,
    };

const _$SessionTypeEnumMap = {
  SessionType.pediatricIntensive: 'pediatricIntensive',
  SessionType.adultIntensive: 'adultIntensive',
  SessionType.standard: 'standard',
  SessionType.traction: 'traction',
};
