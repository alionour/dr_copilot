import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

/// Enum representing the type of customer for an invoice.
enum CustomerType {
  /// Individual patient.
  patient,

  /// Corporate or organizational client.
  organization,

  /// Insurance company.
  insurance;

  /// Returns a user-friendly display name.
  String get displayName {
    switch (this) {
      case CustomerType.patient:
        return 'Patient';
      case CustomerType.organization:
        return 'Organization';
      case CustomerType.insurance:
        return 'Insurance';
    }
  }

  @override
  String toString() => displayName;
}

/// Enum representing the source of the invoice.
enum InvoiceSource {
  /// Invoice generated from therapy sessions.
  sessions,

  /// Invoice generated from evaluations.
  evaluations,

  /// Other miscellaneous sources.
  other;

  /// Returns a user-friendly display name.
  String get displayName {
    switch (this) {
      case InvoiceSource.sessions:
        return 'Sessions';
      case InvoiceSource.evaluations:
        return 'Evaluations';
      case InvoiceSource.other:
        return 'Other';
    }
  }

  @override
  String toString() => displayName;
}

/// Enum representing the payment status of an invoice.
enum InvoiceStatus {
  /// No payment has been made.
  unpaid,

  /// Fully paid.
  paid,

  /// Partially paid.
  partiallyPaid;

  /// Checks if the status is strictly unpaid.
  bool isUnpaid() => this == InvoiceStatus.unpaid;

  /// Returns a user-friendly display name.
  String get displayName {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
    }
  }

  @override
  String toString() => displayName;
}

/// A model class representing a financial invoice.
@JsonSerializable(explicitToJson: true)
class InvoiceModel {
  /// The unique identifier of the invoice.
  final String id;

  /// The ID of the owner entity (clinic/user).
  final String ownerId;

  /// The ID of the clinic associated with the invoice.
  final String clinicId;

  /// The title of the invoice.
  final String title;

  /// A description of the invoice contents.
  final String description;

  /// The total amount of the invoice.
  final double amount;

  /// The ID of the currency profile used for this invoice.
  final String currencyProfileId;

  /// The date and time when the invoice was issued (business meaning).
  @TimestampConverter()
  final Timestamp issuedAt;

  /// The date and time when the invoice record was created in the system (audit meaning).
  @TimestampConverter()
  final Timestamp createdAt;

  /// The ID of the user or system that created this invoice.
  final String createdBy;

  /// The ID of the user who last updated this invoice.
  final String? updatedBy;

  /// The ID of the user who deleted this invoice.
  final String? deletedBy;

  /// The timestamp when the invoice was last updated.
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// The timestamp when the invoice was soft deleted.
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  /// The due date for payment of this invoice.
  @TimestampConverter()
  final Timestamp dueDate;

  /// The ID of the customer (patient or organization).
  final String? customerId;

  /// The type of the customer.
  final CustomerType? customerType;

  /// The source of the invoice (e.g., sessions, evaluations).
  final InvoiceSource? source;

  /// The payment status of the invoice.
  final InvoiceStatus? status;

  /// The ID of the session or evaluation this invoice is for (if applicable).
  final String referenceId;

  InvoiceModel({
    required this.id,
    required this.ownerId,
    required this.clinicId,
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
    required this.referenceId,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceModelToJson(this);

  InvoiceModel copyWith({
    String? id,
    String? ownerId,
    String? clinicId,
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
    InvoiceStatus? status,
    String? referenceId,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      clinicId: clinicId ?? this.clinicId,
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
      referenceId: referenceId ?? this.referenceId,
    );
  }
}
