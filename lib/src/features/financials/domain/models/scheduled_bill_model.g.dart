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
      type: ScheduledBillType.fromString(json['type'] as String?),
      scheduledAt: const TimestampConverter().fromJson(json['scheduledAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      recurrence:
          ScheduledBillRecurrence.fromString(json['recurrence'] as String?),
    );

Map<String, dynamic> _$ScheduledBillModelToJson(ScheduledBillModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currencyProfileId': instance.currencyProfileId,
      'type': instance.type.asString,
      'scheduledAt': const TimestampConverter().toJson(instance.scheduledAt),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'recurrence': instance.recurrence.asString,
    };
