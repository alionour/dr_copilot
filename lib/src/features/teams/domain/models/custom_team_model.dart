import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'custom_team_model.g.dart';

@JsonSerializable()
class CustomTeamModel extends Equatable {
  final String id;
  final String clinicId;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final bool isArchived;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  const CustomTeamModel({
    required this.id,
    required this.clinicId,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    this.isArchived = false,
    required this.createdAt,
  });

  factory CustomTeamModel.fromJson(Map<String, dynamic> json) =>
      _$CustomTeamModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomTeamModelToJson(this);

  factory CustomTeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomTeamModel(
      id: doc.id,
      clinicId: data['clinicId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isArchived: data['isArchived'] ?? false,
      createdAt: _timestampFromJson(data['createdAt']),
    );
  }

  CustomTeamModel copyWith({
    String? id,
    String? clinicId,
    String? ownerId,
    String? name,
    List<String>? memberIds,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return CustomTeamModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  @override
  List<Object?> get props => [
    id,
    clinicId,
    ownerId,
    name,
    memberIds,
    isArchived,
    createdAt,
  ];
}

