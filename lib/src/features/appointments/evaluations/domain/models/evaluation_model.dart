import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'evaluation_model.g.dart';

class TimestampConverter implements JsonConverter<Timestamp, dynamic> {
  const TimestampConverter();

  @override
  Timestamp fromJson(dynamic json) {
    return json is Timestamp
        ? json
        : Timestamp.fromMillisecondsSinceEpoch(json as int);
  }

  @override
  dynamic toJson(Timestamp object) => object;
}

@JsonSerializable()
class EvaluationModel {
  final String id;
  final String patientId;
  final String patientName;
  final double price;

  @TimestampConverter()
  final Timestamp startDateTime;

  @TimestampConverter()
  final Timestamp endDateTime;

  final String userId;
  final String? createdBy;
  final String? updatedBy;
  final String? deletedBy;

  @TimestampConverter()
  final Timestamp? createdAt;

  @TimestampConverter()
  final Timestamp? updatedAt;

  @TimestampConverter()
  final Timestamp? deletedAt;

  EvaluationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.userId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);

  EvaluationModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    double? price,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    String? userId,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
  }) {
    return EvaluationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
