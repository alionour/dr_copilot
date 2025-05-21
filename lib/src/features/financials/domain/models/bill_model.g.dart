// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillModel _$BillModelFromJson(Map<String, dynamic> json) => BillModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      clinicId: json['clinicId'] as String,
      scheduledBillId: json['scheduledBillId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyProfileId: json['currencyProfileId'] as String,
      dueDate: const TimestampConverter().fromJson(json['dueDate']),
      status: $enumDecodeNullable(_$BillStatusEnumMap, json['status']) ??
          BillStatus.unpaid,
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
      payedAt: const NullableTimestampConverter().fromJson(json['payedAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
    );

Map<String, dynamic> _$BillModelToJson(BillModel instance) => <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'clinicId': instance.clinicId,
      'scheduledBillId': instance.scheduledBillId,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currencyProfileId': instance.currencyProfileId,
      'dueDate': const TimestampConverter().toJson(instance.dueDate),
      'status': _$BillStatusEnumMap[instance.status]!,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'payedAt': const NullableTimestampConverter().toJson(instance.payedAt),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt':
          const NullableTimestampConverter().toJson(instance.updatedAt),
      'deletedAt':
          const NullableTimestampConverter().toJson(instance.deletedAt),
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'deletedBy': instance.deletedBy,
    };

const _$BillStatusEnumMap = {
  BillStatus.unpaid: 'unpaid',
  BillStatus.paid: 'paid',
  BillStatus.partiallyPaid: 'partiallyPaid',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
  PaymentMethod.bankTransfer: 'bankTransfer',
  PaymentMethod.other: 'other',
};
