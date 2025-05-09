
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';


/// JsonConverter for TransactionSource enum
class TransactionSourceConverter implements JsonConverter<TransactionSource, String> {
  const TransactionSourceConverter();

  @override
  TransactionSource fromJson(String json) => TransactionSource.fromString(json);

  @override
  String toJson(TransactionSource object) => object.value;
}

/// JsonConverter for TransactionDirection enum
class TransactionDirectionConverter implements JsonConverter<TransactionDirection, String> {
  const TransactionDirectionConverter();

  @override
  TransactionDirection fromJson(String json) => TransactionDirection.fromString(json);

  @override
  String toJson(TransactionDirection object) => object.value;
}

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

/// Enum for transaction direction.
enum TransactionDirection {
  inwards('in'),
  outwards('out');

  final String value;
  const TransactionDirection(this.value);

  @override
  String toString() => value;

  static TransactionDirection fromString(String value) {
    return TransactionDirection.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionDirection.inwards,
    );
  }
}

/// Enum for transaction source with unique string values.
enum TransactionSource {
  manual('manual'),
  invoice('invoice'),
  bill('bill'),
  transfer('transfer'),
  refund('refund'),
  adjustment('adjustment');

  final String value;
  const TransactionSource(this.value);

  @override
  String toString() => value;

  static TransactionSource fromString(String value) {
    return TransactionSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionSource.manual,
    );
  }
}

/// Represents a financial transaction, such as an income or expense.
@JsonSerializable()
class TransactionModel {
  final String
      id; // Unique identifier for the transaction, used to distinguish it in the database.
  final double amount; // The monetary value of the transaction.
  final String
      description; // A brief description or note about the transaction.
  @TimestampConverter()
  final Timestamp
      transactionDate; // The date and time when the transaction occurred.
  @TransactionSourceConverter()
  final TransactionSource transactionSource; // Source of transaction, e.g., "invoice", "bill", etc.
  @TransactionDirectionConverter()
  final TransactionDirection direction; // 'in' or 'out', explicit field
  @TimestampConverter()
  final Timestamp
      createdAt; // The timestamp when the transaction was created in the system.
  @TimestampConverter()
  final Timestamp?
      deletedAt; // The timestamp when the transaction was deleted in the system.
  @TimestampConverter()
  final Timestamp?
      updatedAt; // (Optional) The timestamp when the transaction was last updated.
  final String?
      category; // (Optional) The category of the transaction, e.g., "Rent", "Salary".
  final String userId; //  The ID of the user associated with the transaction.
  final String?
      createdBy; //  The ID of the user associated with the transaction.
  final String?
      deletedBy; //  The ID of the user associated with the transaction.
  final String?
      updatedBy; //  The ID of the user associated with the transaction.
  final String?
      currency; // (Optional) The currency of the transaction, e.g., "USD".
  final String?
      notes; // (Optional) Additional notes or comments about the transaction.
  final String?
      status; // (Optional) The status of the transaction, e.g., "Pending", "Completed".
  final String?
      referenceId; // (Optional) A reference to an external system or invoice.

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.transactionSource,
    required this.direction,
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
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // If direction is missing, infer from source
    final map = Map<String, dynamic>.from(json);
    if (map['direction'] == null && map['transactionSource'] != null) {
      map['direction'] = _directionForSource(map['transactionSource'] as String).value;
    }
    return _$TransactionModelFromJson(map);
  }

  /// Helper to infer direction from transaction source string if not present in JSON.
  static TransactionDirection _directionForSource(String source) {
    switch (source) {
      case 'invoice':
      case 'refund':
        return TransactionDirection.inwards;
      case 'bill':
      case 'transfer':
      case 'adjustment':
        return TransactionDirection.outwards;
      default:
        return TransactionDirection.inwards;
    }
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? description,
    Timestamp? transactionDate,
    TransactionSource? transactionSource,
    TransactionDirection? direction,
    Timestamp? createdAt,
    Timestamp? deletedAt,
    Timestamp? updatedAt,
    String? category,
    String? userId,
    String? createdBy,
    String? deletedBy,
    String? updatedBy,
    String? currency,
    String? notes,
    String? status,
    String? referenceId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionSource: transactionSource ?? this.transactionSource,
      direction: direction ?? this.direction,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      deletedBy: deletedBy ?? this.deletedBy,
      updatedBy: updatedBy ?? this.updatedBy,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}
