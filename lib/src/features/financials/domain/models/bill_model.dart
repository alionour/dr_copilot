import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/helper/timestamp_helper.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bill_model.g.dart';

/// Enum representing the payment status of a bill.
enum BillStatus {
  /// No payment has been made.
  unpaid,

  /// Fully paid.
  paid,

  /// Partially paid.
  partiallyPaid;

  /// Returns the string representation of the status.
  String get asString => name;

  /// Parses a string to a [BillStatus], defaulting to [unpaid] if unknown.
  static BillStatus fromString(String? value) {
    switch (value) {
      case 'paid':
        return BillStatus.paid;
      case 'partiallyPaid':
        return BillStatus.partiallyPaid;
      default:
        return BillStatus.unpaid;
    }
  }
}

/// The payment method used for the bill (e.g., cash, card, bank transfer, etc.)
/// The payment method used for the bill.
enum PaymentMethod {
  /// Cash payment.
  cash,

  /// Card payment (credit/debit).
  card,

  /// Bank transfer.
  bankTransfer,

  /// Other payment methods.
  other;

  /// Returns the string representation of the method.
  String get asString => name;

  /// Parses a string to a [PaymentMethod], defaulting to [other] if unknown.
  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.other;
    }
  }
}

@JsonSerializable(explicitToJson: true)

/// A model class representing a bill (expense).
@JsonSerializable(explicitToJson: true)
class BillModel {
  /// The unique identifier of the bill.
  final String id;

  /// The ID of the owner entity (clinic/user).
  final String ownerId;

  /// The ID of the clinic associated with the bill.
  final String clinicId;

  /// The ID of the scheduled bill this was generated from (if applicable).
  final String? scheduledBillId;

  /// The title of the bill.
  final String title;

  /// A description of the bill.
  final String description;

  /// The total amount of the bill.
  final double amount;

  /// The ID of the currency profile used for this bill.
  final String currencyProfileId;

  /// The due date for payment of this bill.
  @TimestampConverter()
  final Timestamp dueDate;

  /// The payment status of the bill.
  final BillStatus status;

  /// The payment method used for this bill (nullable, only set if paid).
  final PaymentMethod? paymentMethod;

  /// The timestamp when the bill was paid (nullable, only set if paid).
  @NullableTimestampConverter()
  final Timestamp? payedAt;

  /// The date and time when the bill record was created.
  @TimestampConverter()
  final Timestamp createdAt;

  /// The timestamp when the bill was last updated.
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// The timestamp when the bill was soft deleted.
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  /// The ID of the user who created this bill.
  final String createdBy;

  /// The ID of the user who last updated this bill.
  final String? updatedBy;

  /// The ID of the user who deleted this bill.
  final String? deletedBy;

  BillModel({
    required this.id,
    required this.ownerId,
    required this.clinicId,
    this.scheduledBillId,
    required this.title,
    required this.description,
    required this.amount,
    required this.currencyProfileId,
    required this.dueDate,
    this.status = BillStatus.unpaid,
    this.paymentMethod,
    this.payedAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) =>
      _$BillModelFromJson(json);
  Map<String, dynamic> toJson() => _$BillModelToJson(this);

  BillModel copyWith({
    String? id,
    String? ownerId,
    String? clinicId,
    String? scheduledBillId,
    String? title,
    String? description,
    double? amount,
    String? currencyProfileId,
    Timestamp? dueDate,
    BillStatus? status,
    PaymentMethod? paymentMethod,
    Timestamp? payedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
  }) {
    return BillModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      clinicId: clinicId ?? this.clinicId,
      scheduledBillId: scheduledBillId ?? this.scheduledBillId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyProfileId: currencyProfileId ?? this.currencyProfileId,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payedAt: payedAt ?? this.payedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
