import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/helper/timestamp_helper.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scheduled_bill_model.g.dart';

/// The recurrence frequency for a scheduled bill.
enum ScheduledBillRecurrence {
  none,
  weekly,
  monthly,
  yearly;

  String get asString => name;

  static ScheduledBillRecurrence fromString(String? value) {
    switch (value) {
      case 'weekly':
        return ScheduledBillRecurrence.weekly;
      case 'monthly':
        return ScheduledBillRecurrence.monthly;
      case 'yearly':
        return ScheduledBillRecurrence.yearly;
      default:
        return ScheduledBillRecurrence.none;
    }
  }
}

/// The type of scheduled bill: income or expense.
enum ScheduledBillType {
  income,
  expense;

  /// Convert enum to string for storage.
  String get asString => name;

  /// Parse from string, defaulting to expense if unknown.
  static ScheduledBillType fromString(String? value) {
    switch (value) {
      case 'income':
        return ScheduledBillType.income;
      case 'expense':
        return ScheduledBillType.expense;
      default:
        return ScheduledBillType.expense;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class ScheduledBillModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currencyProfileId;
  final ScheduledBillType type;
  @TimestampConverter()
  final Timestamp scheduledAt;
  @TimestampConverter()
  final Timestamp createdAt;
  @NullableTimestampConverter()
  final Timestamp? updatedAt;
  @NullableTimestampConverter()
  final Timestamp? deletedAt;
  final String createdBy;
  final String? updatedBy;
  final String? deletedBy;
  final ScheduledBillRecurrence recurrence;

  ScheduledBillModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currencyProfileId,
    this.type = ScheduledBillType.expense,
    required this.scheduledAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.recurrence = ScheduledBillRecurrence.none,
  });

  factory ScheduledBillModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledBillModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduledBillModelToJson(this);

  ScheduledBillModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? currencyProfileId,
    ScheduledBillType? type,
    Timestamp? scheduledAt,
    Timestamp? createdAt,
    String? createdBy,
    ScheduledBillRecurrence? recurrence,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? updatedBy,
    String? deletedBy,
  }) {
    return ScheduledBillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyProfileId: currencyProfileId ?? this.currencyProfileId,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      recurrence: recurrence ?? this.recurrence,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
