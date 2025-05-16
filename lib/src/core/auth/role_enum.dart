// This file defines enums for all available roles in the Dr Copilot app.
// Use Role.values for iteration, or Role.<name> for type-safe checks.

/// Enum representing all roles in the app.
enum Role {
  admin,
  doctor,
  staff,
  financial,
  readonly;

  String get asString {
    switch (this) {
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

  static Role? fromString(String value) {
    for (final role in Role.values) {
      if (role.asString == value) return role;
    }
    return null;
  }
}
