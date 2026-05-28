// This file defines enums for all available roles in the Dr AI app.
// Use Role.values for iteration, or Role.<name> for type-safe checks.
import 'package:json_annotation/json_annotation.dart';

/// Enum representing all roles in the app.
enum AppRole {
  admin,
  doctor,
  staff,
  financial,
  readonly;

  /// Maps [AppRole] enum to its string value (as used in Firestore and role_permissions.dart).
  String roleToString(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'admin';
      case AppRole.doctor:
        return 'doctor';
      case AppRole.staff:
        return 'staff';
      case AppRole.financial:
        return 'financial';
      case AppRole.readonly:
        return 'readonly';
    }
  }

  AppRole? roleFromString(String value) {
    for (final role in AppRole.values) {
      if (roleToString(role) == value) return role;
    }
    return null;
  }
}

class RoleListJsonConverter
    implements JsonConverter<List<AppRole>, List<dynamic>> {
  const RoleListJsonConverter();
  @override
  List<AppRole> fromJson(List<dynamic> json) => json
      .map((e) => AppRole.values.firstWhere(
          (role) => AppRole.admin.roleToString(role) == e as String))
      .toList();
  @override
  List<dynamic> toJson(List<AppRole> object) =>
      object.map((e) => AppRole.admin.roleToString(e)).toList();
}
