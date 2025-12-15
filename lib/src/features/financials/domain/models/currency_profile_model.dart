import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'currency_profile_model.g.dart';

class TimestampConverter implements JsonConverter<Timestamp, dynamic> {
  const TimestampConverter();

  @override
  Timestamp fromJson(dynamic json) {
    if (json is Timestamp) {
      return json;
    } else if (json is int) {
      return Timestamp.fromMillisecondsSinceEpoch(json);
    } else if (json is String) {
      return Timestamp.fromDate(DateTime.parse(json));
    } else {
      throw Exception('Invalid type for Timestamp conversion: $json');
    }
  }

  @override
  dynamic toJson(Timestamp? object) => object;
}

class NullableTimestampConverter implements JsonConverter<Timestamp?, dynamic> {
  const NullableTimestampConverter();

  @override
  Timestamp? fromJson(dynamic json) {
    if (json == null) {
      return null;
    } else if (json is Timestamp) {
      return json;
    } else if (json is int) {
      return Timestamp.fromMillisecondsSinceEpoch(json);
    } else if (json is String) {
      return Timestamp.fromDate(DateTime.parse(json));
    } else {
      throw Exception('Invalid type for Timestamp conversion: $json');
    }
  }

  @override
  dynamic toJson(Timestamp? object) => object;
}

@JsonSerializable()
class CurrencyProfileModel {
  final String id;
  final String currency;
  final String name;
  final String? description;
  @TimestampConverter()
  final Timestamp createdAt;
  @NullableTimestampConverter()
  final Timestamp? updatedAt;
  @NullableTimestampConverter()
  final Timestamp? deletedAt;
  final String createdBy;
  final String? updatedBy;
  final String? deletedBy;

  CurrencyProfileModel({
    required this.id,
    required this.currency,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
  });

  factory CurrencyProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$CurrencyProfileModelToJson(this);

  CurrencyProfileModel copyWith({
    String? id,
    String? currency,
    String? name,
    String? description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
  }) {
    return CurrencyProfileModel(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}

