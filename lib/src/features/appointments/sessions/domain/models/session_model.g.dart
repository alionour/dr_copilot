// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: const TimestampConverter().fromJson(json['startDateTime']),
      endDateTime: const TimestampConverter().fromJson(json['endDateTime']),
      sessionType: $enumDecode(_$SessionTypeEnumMap, json['sessionType']),
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientName': instance.patientName,
      'price': instance.price,
      'startDateTime':
          const TimestampConverter().toJson(instance.startDateTime),
      'endDateTime': const TimestampConverter().toJson(instance.endDateTime),
      'sessionType': _$SessionTypeEnumMap[instance.sessionType]!,
      'userId': instance.userId,
      'createdBy': instance.createdBy,
    };

const _$SessionTypeEnumMap = {
  SessionType.pediatricIntensive: 'pediatricIntensive',
  SessionType.adultIntensive: 'adultIntensive',
  SessionType.standard: 'standard',
  SessionType.traction: 'traction',
};
