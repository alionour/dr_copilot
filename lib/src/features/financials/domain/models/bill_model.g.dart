// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillModel _$BillModelFromJson(Map<String, dynamic> json) => BillModel(
      id: json['id'] as String,
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
    );

Map<String, dynamic> _$BillModelToJson(BillModel instance) => <String, dynamic>{
      'id': instance.id,
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
