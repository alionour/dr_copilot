import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'department_model.g.dart';

@JsonSerializable()
class DepartmentModel extends Equatable {
  final String id;
  final String clinicId;
  final String name;
  final String? description;
  
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  const DepartmentModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      _$DepartmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentModelToJson(this);

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  @override
  List<Object?> get props => [id, clinicId, name, description, createdAt];
}
