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
  final String id; // Unique identifier for the transaction, used to distinguish it in the database.
  final double amount; // The monetary value of the transaction.
  final String description; // A brief description or note about the transaction.
  @TimestampConverter()
  final Timestamp transactionDate; // The date and time when the transaction occurred.
  final String transactionType; // Type of transaction, e.g., "Income" or "Expense".
  @TimestampConverter()
  final Timestamp createdAt; // The timestamp when the transaction was created in the system.
  @TimestampConverter()
  final Timestamp? deletedAt; // The timestamp when the transaction was deleted in the system.
  @TimestampConverter()
  final Timestamp? updatedAt; // (Optional) The timestamp when the transaction was last updated.
  final String? category; // (Optional) The category of the transaction, e.g., "Rent", "Salary".
  final String userId; //  The ID of the user associated with the transaction.
  final String? createdBy; //  The ID of the user associated with the transaction.
  final String? deletedBy; //  The ID of the user associated with the transaction.
  final String? updatedBy; //  The ID of the user associated with the transaction.
  final String? currency; // (Optional) The currency of the transaction, e.g., "USD".
  final String? notes; // (Optional) Additional notes or comments about the transaction.
  final String? status; // (Optional) The status of the transaction, e.g., "Pending", "Completed".
  final String? referenceId; // (Optional) A reference to an external system or invoice.

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.transactionType,
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.createdBy,
    this.deletedBy,
    this.updatedBy,
    this.deletedAt,

   required this.userId,
    
    
    this.currency,
    this.notes,
    this.status,
    this.referenceId,
  });

  // Converts a [TransactionModel] to a JSON map for Firestore.
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Creates a [TransactionModel] from a Firestore document.
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
