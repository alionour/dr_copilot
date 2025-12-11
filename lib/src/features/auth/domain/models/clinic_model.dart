import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clinic_model.g.dart';

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
class ClinicModel {
  final String id;
  final String name;
  final String? location;
  final String ownerId;
  final String adminEmail;
  @NullableTimestampConverter()
  final Timestamp? createdAt;

  // Subscription Fields
  final String? subscriptionTier; // 'free', 'pro', 'elite'
  final bool? isSubscriptionActive;
  @NullableTimestampConverter()
  final Timestamp? subscriptionUpdatedAt;

  ClinicModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.adminEmail,
    required this.createdAt,
    this.subscriptionTier,
    this.isSubscriptionActive,
    this.subscriptionUpdatedAt,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) =>
      _$ClinicModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClinicModelToJson(this);

  ClinicModel copyWith({
    String? id,
    String? name,
    String? location,
    String? ownerId,
    String? adminEmail,
    Timestamp? createdAt,
    String? subscriptionTier,
    bool? isSubscriptionActive,
    Timestamp? subscriptionUpdatedAt,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerId: ownerId ?? this.ownerId,
      adminEmail: adminEmail ?? this.adminEmail,
      createdAt: createdAt ?? this.createdAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      subscriptionUpdatedAt:
          subscriptionUpdatedAt ?? this.subscriptionUpdatedAt,
    );
  }
}
