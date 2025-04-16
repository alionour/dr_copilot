import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluationModel {
  final String id;
  final String patientId;
  final String patientName;
  final double price;
  final Timestamp startDateTime;
  final Timestamp endDateTime;
  final String userId;
  final String? createdBy;
  final String? updatedBy;
  final String? deletedBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
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

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: json['startDateTime'] as Timestamp,
      endDateTime: json['endDateTime'] as Timestamp,
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
      deletedAt: json['deletedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'price': price,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'userId': userId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedBy': deletedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

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
