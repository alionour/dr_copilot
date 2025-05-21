# Roles and Permissions Strategy

_Last updated: 2025-05-16_

## Overview
This document describes the strategy for implementing roles and permissions in the Dr Copilot app. The approach is inspired by best practices from Google Cloud IAM and other enterprise systems, providing both flexibility and fine-grained access control.

---

## Key Concepts


### 👥 Roles
- **Definition:** Named groups representing sets of permissions (e.g., `admin`, `doctor`, `staff`).
- **Purpose:** Assigning a role to a user grants them all permissions associated with that role.
- **Storage:** Each user document contains a `roles` array (e.g., `["doctor", "editor"]`).

### 🛡️ Permissions
- **Definition:** Fine-grained actions a user can perform (e.g., `can_edit_patient`, `can_view_financials`).
- **Purpose:** Permissions can be assigned directly to users for custom or exceptional access.
- **Storage:** Each user document contains a `permissions` array (e.g., `["can_view_financials"]`).

### 🗂️ Role Groups (Role-to-Permissions Mapping)
- **Definition:** Each role is mapped to a set of permissions, defined centrally (in Firestore or config).
- **Purpose:** Assigning a role automatically grants all its permissions to the user.

---

## How It Works
1. **User Model**
   - Each user has `roles` (array of strings) and `permissions` (array of strings).
2. **Backend Storage**
   - User document example:
     ```json
     {
       "uid": "abc123",
       "roles": ["doctor"],
       "permissions": ["can_view_financials"]
     }
     ```
   - Roles-to-permissions mapping is defined in a central place (e.g., Firestore `roles` collection or config file):
     ```json
     {
       "admin": ["can_manage_users", "can_view_financials", "can_edit_patient"],
       "doctor": ["can_view_patient", "can_edit_patient"],
       "staff": ["can_view_patient"]
     }
     ```
3. **Access Checks**
   - To determine if a user can perform an action:
     - ✅ Check if the required permission is in the user's `permissions` array.
     - ✅ Or, check if any of the user's roles grant the required permission via the roles-to-permissions mapping.
   - **Example Dart code:**
     ```dart
     bool hasPermission(UserModel user, String permission, Map<String, List<String>> roleMap) {
       if (user.permissions.contains(permission)) return true;
       for (final role in user.roles) {
         if (roleMap[role]?.contains(permission) ?? false) return true;
       }
       return false;
     }
     ```
4. **Admin UI (Optional)**
   - Admins can assign roles and direct permissions to users via a management interface.

---


## Example Use Cases & Scenarios

| 👤 User   | 🏷️ Roles         | 🛡️ Permissions                | 🟢 Effective Permissions                        |
|----------|------------------|-------------------------------|-------------------------------------------------|
| Alice    | ["admin"]        | []                            | All admin permissions                           |
| Bob      | ["doctor"]       | ["can_view_financials"]       | Doctor permissions + can_view_financials        |
| Carol    | ["staff"]        | ["can_edit_patient"]          | Staff permissions + can_edit_patient            |
| Dave     | []               | ["can_view_patient"]          | Only can_view_patient                           |

### Example Scenarios
- 👩‍⚕️ **Doctor**: Can view and edit patients, but not manage users or financials unless given extra permission.
- 🧑‍💼 **Admin**: Can manage users, view financials, and edit patients.
- 👨‍💻 **Staff**: Can view patients, but can be granted extra permissions as needed.
- 🛠️ **Custom**: A user with no role but with `can_view_patient` permission can only view patients.

---


## Benefits
- 🚀 **Scalable:** Easy to manage for large teams.
- 🔄 **Flexible:** Supports both group-based and custom access.
- 🔒 **Secure:** Fine-grained control over every feature and action.

---


## Summary
- Use both `roles` and `permissions` arrays in user documents.
- Define a central mapping of roles to permissions.
- Always check both roles and permissions for access control.

> This strategy ensures your app is ready for both simple and complex access control needs. 💡
