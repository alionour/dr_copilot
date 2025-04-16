import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for session types
enum SessionType {
  pediatricIntensive('Pediatric Intensive', 100.0),
  adultIntensive('Adult Intensive', 150.0),
  standard('Standard', 120.0),
  traction('Traction', 150.0);

  final String text;
  final double basePrice;

  const SessionType(this.text, this.basePrice);
}

class SessionModel {
  final String id;
  final String patientId;
  final double price;
  final Timestamp startDateTime;
  final Timestamp endDateTime;
  final SessionType sessionType;
  final String userId;
  final String createdBy;
  final String? patientName;
  final String? updatedBy;
  final String? deletedBy;
  final Timestamp? deletedAt;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  SessionModel({
    required this.id,
    required this.patientId,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.sessionType,
    required this.userId,
    required this.createdBy,
    this.patientName,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: json['startDateTime'] as Timestamp,
      endDateTime: json['endDateTime'] as Timestamp,
      sessionType: SessionType.values.firstWhere((e) => e.toString() == 'SessionType.${json['sessionType']}'),
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String,
      patientName: json['patientName'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: json['deletedAt'] as Timestamp?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'price': price,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'sessionType': sessionType.toString().split('.').last,
      'userId': userId,
      'createdBy': createdBy,
      'patientName': patientName,
      'updatedBy': updatedBy,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SessionModel copyWith({
    String? id,
    String? patientId,
    double? price,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    SessionType? sessionType,
    String? userId,
    String? createdBy,
    String? patientName,
    String? updatedBy,
    String? deletedBy,
    Timestamp? deletedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      sessionType: sessionType ?? this.sessionType,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      patientName: patientName ?? this.patientName,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
