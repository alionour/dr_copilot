// This file defines enums for all available roles in the Dr Copilot app.
// Use Role.values for iteration, or Role.<name> for type-safe checks.

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

  /// Optionally, add a function to parse a string to Role enum.
  AppRole? roleFromString(String value) {
    for (final role in AppRole.values) {
      if (roleToString(role) == value) return role;
    }
    return null;
  }
}
