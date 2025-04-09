import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

/// A custom converter for Firestore [Timestamp] to JSON and vice versa.
class TimestampConverter implements JsonConverter<Timestamp, Object> {
  const TimestampConverter();

  @override
  Timestamp fromJson(Object json) {
    return Timestamp.fromMillisecondsSinceEpoch(json as int);
  }

  @override
  Object toJson(Timestamp object) {
    return object.millisecondsSinceEpoch;
  }
}

/// Represents a financial transaction, such as an income or expense.
@JsonSerializable()
class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'

  @TimestampConverter()
  final Timestamp date;

  final String description;

  @TimestampConverter()
  final Timestamp? createdAt;

  @TimestampConverter()
  final Timestamp? updatedAt;

  @TimestampConverter()
  final Timestamp? deletedAt;

  final String? createdBy;
  final String? updatedBy;
  final String? deletedBy;

  /// Constructor for [TransactionModel].
  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
  });

  /// Converts a [TransactionModel] to a JSON map for Firestore.
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Creates a [TransactionModel] from a Firestore document.
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
