// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_bill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduledBillModel _$ScheduledBillModelFromJson(Map<String, dynamic> json) =>
    ScheduledBillModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyProfileId: json['currencyProfileId'] as String,
      type:
          $enumDecodeNullable(_$ScheduledBillTypeEnumMap, json['type']) ??
          ScheduledBillType.expense,
      scheduledAt: const TimestampConverter().fromJson(json['scheduledAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      recurrence:
          $enumDecodeNullable(
            _$ScheduledBillRecurrenceEnumMap,
            json['recurrence'],
          ) ??
          ScheduledBillRecurrence.none,
    );

Map<String, dynamic> _$ScheduledBillModelToJson(
  ScheduledBillModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'amount': instance.amount,
  'currencyProfileId': instance.currencyProfileId,
  'type': _$ScheduledBillTypeEnumMap[instance.type]!,
  'scheduledAt': const TimestampConverter().toJson(instance.scheduledAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableTimestampConverter().toJson(instance.deletedAt),
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'deletedBy': instance.deletedBy,
  'recurrence': _$ScheduledBillRecurrenceEnumMap[instance.recurrence]!,
};

const _$ScheduledBillTypeEnumMap = {
  ScheduledBillType.income: 'income',
  ScheduledBillType.expense: 'expense',
};

const _$ScheduledBillRecurrenceEnumMap = {
  ScheduledBillRecurrence.none: 'none',
  ScheduledBillRecurrence.weekly: 'weekly',
  ScheduledBillRecurrence.monthly: 'monthly',
  ScheduledBillRecurrence.yearly: 'yearly',
};

