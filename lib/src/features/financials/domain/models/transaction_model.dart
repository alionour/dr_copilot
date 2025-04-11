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
  final String userId;

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
    required this.userId,
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

class Transaction {
  final String id; // Unique identifier for the transaction, used to distinguish it in the database.
  final double amount; // The monetary value of the transaction.
  final String description; // A brief description or note about the transaction.
  final Timestamp transactionDate; // The date and time when the transaction occurred.
  final String transactionType; // Type of transaction, e.g., "Income" or "Expense".
  final Timestamp createdAt; // The timestamp when the transaction was created in the system.
  final Timestamp? updatedAt; // (Optional) The timestamp when the transaction was last updated.
  final String? category; // (Optional) The category of the transaction, e.g., "Rent", "Salary".
  final String? userId; // (Optional) The ID of the user associated with the transaction.
  final String? paymentMethod; // (Optional) The method of payment, e.g., "Cash", "Credit Card".
  final String? currency; // (Optional) The currency of the transaction, e.g., "USD".
  final String? notes; // (Optional) Additional notes or comments about the transaction.
  final String? status; // (Optional) The status of the transaction, e.g., "Pending", "Completed".
  final String? referenceId; // (Optional) A reference to an external system or invoice.

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.transactionType,
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.userId,
    this.paymentMethod,
    this.currency,
    this.notes,
    this.status,
    this.referenceId,
  });

  // Convert the transaction object to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'transactionDate': transactionDate,
      'transactionType': transactionType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'category': category,
      'userId': userId,
      'paymentMethod': paymentMethod,
      'currency': currency,
      'notes': notes,
      'status': status,
      'referenceId': referenceId,
    };
  }
}
