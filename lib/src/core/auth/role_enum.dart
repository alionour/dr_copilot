// This file defines enums for all available roles in the Dr Copilot app.
// Use Role.values for iteration, or Role.<name> for type-safe checks.

/// Enum representing all roles in the app.
enum Role {
  admin,
  doctor,
  staff,
  financial,
  readonly;

  /// Maps [Role] enum to its string value (as used in Firestore and role_permissions.dart).
  String roleToString(Role role) {
    switch (role) {
      case Role.admin:
        return 'admin';
      case Role.doctor:
        return 'doctor';
      case Role.staff:
        return 'staff';
      case Role.financial:
        return 'financial';
      case Role.readonly:
        return 'readonly';
    }
  }

  /// Optionally, add a function to parse a string to Role enum.
  Role? roleFromString(String value) {
    for (final role in Role.values) {
      if (roleToString(role) == value) return role;
    }
    return null;
  }
}
