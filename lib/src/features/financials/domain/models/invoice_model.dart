import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

enum CustomerType {
  patient,
  organization,
  insurance;

  // Getter to return a user-friendly string
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

  // Overriding toString for custom string representation
  @override
  String toString() => displayName;
}

enum InvoiceSource {
  sessions,
  evaluations,
  other;

  // Getter to return a user-friendly string
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

  // Overriding toString for custom string representation
  @override
  String toString() => displayName;
}

enum InvoiceStatus {
  unpaid,
  paid,
  partiallyPaid;

  // Method to check if the status is unpaid
  bool isUnpaid() => this == InvoiceStatus.unpaid;

  // Getter to return a user-friendly string
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

  // Overriding toString for custom string representation
  @override
  String toString() => displayName;
}

@JsonSerializable(explicitToJson: true)
class InvoiceModel {
  final String id;
  final String ownerId; // The parent user document this invoice belongs to
  final String clinicId;
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
  final InvoiceStatus? status; // Changed from String? to InvoiceStatus?

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
