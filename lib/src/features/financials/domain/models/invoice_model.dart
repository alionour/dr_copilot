import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

enum CustomerType { patient, organization, insurance }

enum InvoiceSource { sessions, evaluations, other }

// String converters for enums
String customerTypeToString(CustomerType type) {
  switch (type) {
    case CustomerType.patient:
      return 'patient';
    case CustomerType.organization:
      return 'organization';
    case CustomerType.insurance:
      return 'insurance';
  }
}

CustomerType customerTypeFromString(String value) {
  switch (value) {
    case 'patient':
      return CustomerType.patient;
    case 'organization':
      return CustomerType.organization;
    case 'insurance':
      return CustomerType.insurance;
    default:
      return CustomerType.patient;
  }
}

String invoiceSourceToString(InvoiceSource source) {
  switch (source) {
    case InvoiceSource.sessions:
      return 'sessions';
    case InvoiceSource.evaluations:
      return 'evaluations';
    case InvoiceSource.other:
      return 'other';
  }
}

InvoiceSource invoiceSourceFromString(String value) {
  switch (value) {
    case 'sessions':
      return InvoiceSource.sessions;
    case 'evaluations':
      return InvoiceSource.evaluations;
    case 'other':
      return InvoiceSource.other;
    default:
      return InvoiceSource.other;
  }
}

@JsonSerializable(explicitToJson: true)
class InvoiceModel {
  final String id;
  final String userId; // The parent user document this invoice belongs to
  final String title;
  final String description;
  final double amount;
  final String currencyProfileId;

  /// The date and time when the invoice was issued (business meaning).
  @TimestampConverter()
  final Timestamp issuedAt;

  /// The date and time when the invoice record was created in the system (audit meaning).
  @TimestampConverter()
  final Timestamp createdAt;

  /// The user ID or system that created this invoice (should not be null).
  final String createdBy; // Not nullable, always required

  final String? updatedBy;
  final String? deletedBy;
  @NullableTimestampConverter()
  final Timestamp? updatedAt;
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  @TimestampConverter()
  final Timestamp dueDate;
  final String? customerId;
  final CustomerType? customerType;
  final InvoiceSource? source;
  final String? status; // e.g., 'unpaid', 'paid', 'overdue', etc.

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.currencyProfileId,
    required this.issuedAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    required this.dueDate,
    this.customerId,
    this.customerType,
    this.source,
    this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceModelToJson(this);

  InvoiceModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    String? currencyProfileId,
    Timestamp? issuedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    Timestamp? dueDate,
    String? customerId,
    CustomerType? customerType,
    InvoiceSource? source,
    String? status,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyProfileId: currencyProfileId ?? this.currencyProfileId,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      dueDate: dueDate ?? this.dueDate,
      customerId: customerId ?? this.customerId,
      customerType: customerType ?? this.customerType,
      source: source ?? this.source,
      status: status ?? this.status,
    );
  }
}
