// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      userId: json['userId'] as String,
      type: json['type'] as String,
      date: const TimestampConverter().fromJson(json['date'] as Object),
      description: json['description'] as String,
      createdAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['createdAt'], const TimestampConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['updatedAt'], const TimestampConverter().fromJson),
      deletedAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['deletedAt'], const TimestampConverter().fromJson),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'type': instance.type,
      'userId': instance.userId,
      'date': const TimestampConverter().toJson(instance.date),
      'description': instance.description,
      'createdAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.createdAt, const TimestampConverter().toJson),
      'updatedAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.updatedAt, const TimestampConverter().toJson),
      'deletedAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.deletedAt, const TimestampConverter().toJson),
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'deletedBy': instance.deletedBy,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
