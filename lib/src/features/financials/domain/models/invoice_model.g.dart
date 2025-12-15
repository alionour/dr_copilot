// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceModel _$InvoiceModelFromJson(Map<String, dynamic> json) => InvoiceModel(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  clinicId: json['clinicId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  currencyProfileId: json['currencyProfileId'] as String,
  issuedAt: const TimestampConverter().fromJson(json['issuedAt']),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
  createdBy: json['createdBy'] as String,
  updatedBy: json['updatedBy'] as String?,
  deletedBy: json['deletedBy'] as String?,
  dueDate: const TimestampConverter().fromJson(json['dueDate']),
  customerId: json['customerId'] as String?,
  customerType: $enumDecodeNullable(
    _$CustomerTypeEnumMap,
    json['customerType'],
  ),
  source: $enumDecodeNullable(_$InvoiceSourceEnumMap, json['source']),
  status: $enumDecodeNullable(_$InvoiceStatusEnumMap, json['status']),
  referenceId: json['referenceId'] as String,
);

Map<String, dynamic> _$InvoiceModelToJson(
  InvoiceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'clinicId': instance.clinicId,
  'title': instance.title,
  'description': instance.description,
  'amount': instance.amount,
  'currencyProfileId': instance.currencyProfileId,
  'issuedAt': const TimestampConverter().toJson(instance.issuedAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'deletedBy': instance.deletedBy,
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableTimestampConverter().toJson(instance.deletedAt),
  'dueDate': const TimestampConverter().toJson(instance.dueDate),
  'customerId': instance.customerId,
  'customerType': _$CustomerTypeEnumMap[instance.customerType],
  'source': _$InvoiceSourceEnumMap[instance.source],
  'status': _$InvoiceStatusEnumMap[instance.status],
  'referenceId': instance.referenceId,
};

const _$CustomerTypeEnumMap = {
  CustomerType.patient: 'patient',
  CustomerType.organization: 'organization',
  CustomerType.insurance: 'insurance',
};

const _$InvoiceSourceEnumMap = {
  InvoiceSource.sessions: 'sessions',
  InvoiceSource.evaluations: 'evaluations',
  InvoiceSource.other: 'other',
};

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.unpaid: 'unpaid',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.partiallyPaid: 'partiallyPaid',
};

