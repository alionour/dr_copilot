// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepartmentModel _$DepartmentModelFromJson(Map<String, dynamic> json) =>
    DepartmentModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DepartmentModel._timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$DepartmentModelToJson(DepartmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clinicId': instance.clinicId,
      'name': instance.name,
      'description': instance.description,
      'createdAt': DepartmentModel._timestampToJson(instance.createdAt),
    };
