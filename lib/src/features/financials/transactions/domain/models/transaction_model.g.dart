// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate:
          const TimestampConverter().fromJson(json['transactionDate']),
      transactionSource: const TransactionSourceConverter()
          .fromJson(json['transactionSource'] as String),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      createdBy: json['createdBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
      userId: json['userId'] as String,
      currencyProfileId: json['currencyProfileId'] as String?,
      direction: const TransactionDirectionConverter()
          .fromJson(json['direction'] as String),
      notes: json['notes'] as String?,
      status: _$JsonConverterFromJson<String, TransactionStatus>(
          json['status'], const TransactionStatusConverter().fromJson),
      referenceId: json['referenceId'] as String,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'description': instance.description,
      'transactionDate':
          const TimestampConverter().toJson(instance.transactionDate),
      'transactionSource':
          const TransactionSourceConverter().toJson(instance.transactionSource),
      'direction':
          const TransactionDirectionConverter().toJson(instance.direction),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'deletedAt':
          const NullableTimestampConverter().toJson(instance.deletedAt),
      'updatedAt':
          const NullableTimestampConverter().toJson(instance.updatedAt),
      'userId': instance.userId,
      'createdBy': instance.createdBy,
      'deletedBy': instance.deletedBy,
      'updatedBy': instance.updatedBy,
      'currencyProfileId': instance.currencyProfileId,
      'notes': instance.notes,
      'status': _$JsonConverterToJson<String, TransactionStatus>(
          instance.status, const TransactionStatusConverter().toJson),
      'referenceId': instance.referenceId,
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
