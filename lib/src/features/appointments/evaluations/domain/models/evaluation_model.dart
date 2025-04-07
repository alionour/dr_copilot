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
  final String createdBy;

  EvaluationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.userId,
    required this.createdBy,
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
    );
  }
}
