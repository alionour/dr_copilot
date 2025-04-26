import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
/// Represents a user in the authentication domain.
///
/// Contains basic user information such as [id], [name], [email], and an optional [profilePicture].
///
/// Provides methods for serializing to and from JSON.
/// 
/// Contains user-related information and properties used throughout the application.
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? profilePicture;

  UserModel({
    required this.id,
     this.name,
     this.email,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
