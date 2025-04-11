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
      transactionDate: const TimestampConverter()
          .fromJson(json['transactionDate'] as Object),
      transactionType: json['transactionType'] as String,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      updatedAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['updatedAt'], const TimestampConverter().fromJson),
      category: json['category'] as String?,
      createdBy: json['createdBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['deletedAt'], const TimestampConverter().fromJson),
      userId: json['userId'] as String,
      currency: json['currency'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      referenceId: json['referenceId'] as String?,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'description': instance.description,
      'transactionDate':
          const TimestampConverter().toJson(instance.transactionDate),
      'transactionType': instance.transactionType,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'deletedAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.deletedAt, const TimestampConverter().toJson),
      'updatedAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.updatedAt, const TimestampConverter().toJson),
      'category': instance.category,
      'userId': instance.userId,
      'createdBy': instance.createdBy,
      'deletedBy': instance.deletedBy,
      'updatedBy': instance.updatedBy,
      'currency': instance.currency,
      'notes': instance.notes,
      'status': instance.status,
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
