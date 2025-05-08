import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/helper/timestamp_helper.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bill_model.g.dart';

enum BillStatus {
  unpaid,
  paid,
  partiallyPaid;

  String get asString => name;

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
enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  other;

  String get asString => name;

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
class BillModel {
  final String id;
  final String? scheduledBillId;
  final String title;
  final String description;
  final double amount;
  final String currencyProfileId;
  @TimestampConverter()
  final Timestamp dueDate;
  final BillStatus status;

  /// The payment method used for this bill (nullable, only set if paid)
  final PaymentMethod? paymentMethod;

  /// The timestamp when the bill was paid (nullable, only set if paid)
  @NullableTimestampConverter()
  final Timestamp? payedAt;
  @TimestampConverter()
  final Timestamp createdAt;

  BillModel({
    required this.id,
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
  });

  factory BillModel.fromJson(Map<String, dynamic> json) =>
      _$BillModelFromJson(json);
  Map<String, dynamic> toJson() => _$BillModelToJson(this);

  BillModel copyWith({
    String? id,
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
  }) {
    return BillModel(
      id: id ?? this.id,
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
    );
  }
}
