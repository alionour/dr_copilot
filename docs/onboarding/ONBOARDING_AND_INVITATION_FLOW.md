# Dr Copilot Onboarding & Invitation Flow

This document explains the onboarding and invitation flow for user roles and permissions in the Dr Copilot app, including Google sign-in, admin/subuser logic, and Firestore integration.

---

## Overview
- **First user**: Becomes the clinic owner (admin).
- **Subsequent users**: Must be invited by the admin (clinic owner) before joining as staff/doctor.
- **All user roles and permissions** are managed via Firestore and enforced at sign-in.

---

## Step-by-Step Flow

### 1. Google Sign-In (or Email/Password)
- User authenticates with Google or email/password.
- After authentication, the app checks Firestore for the user's document in the `users` collection.

### 2. First User (Admin/Owner)
- If **no user document exists** for this user **and** the `users` collection is empty:
  - The user is allowed to join as the **admin** (clinic owner).
  - A new user document is created with the `admin` role and empty permissions.

### 3. Subuser (Staff/Doctor) Onboarding
- If **no user document exists** for this user **and** the `users` collection is **not empty**:
  - The app checks the `user_invitations` collection for a **pending invitation** matching the user's email.
  - If a matching invitation is found:
    - The user is allowed to join.
    - The user document is created with the roles and permissions from the invitation.
    - The invitation is marked as accepted.
  - If **no invitation is found**:
    - The user is denied access and signed out.
    - An error message is shown: "You must be invited by the clinic owner to join this clinic."

### 4. Existing User Login
- If a user document **already exists** for this user:
  - The app fetches the user's roles and permissions from Firestore.
  - The user is signed in with their assigned access.

---

## Firestore Collections
- `users`: Stores user documents with roles and permissions.
- `user_invitations`: Stores invitation documents with email, roles, permissions, status (`pending`/`accepted`), and metadata.

### Example `user_invitations` Document
```json
{
  "email": "doctor@example.com",
  "roles": ["doctor"],
  "permissions": ["can_view_patient", "can_add_session"],
  "status": "pending", // or "accepted"
  "invitedBy": "admin_uid",
  "createdAt": "<timestamp>"
}
```

---

## Admin Invitation Flow
1. **Admin** uses the UI to invite a new user by entering their email and selecting a role (and optionally permissions).
2. The app creates a document in `user_invitations` with the provided details and `status: "pending"`.
3. The invited user must sign in with the **same email**.
4. On sign-in, the app matches the invitation, creates the user document, and marks the invitation as `accepted`.

---

## Error Handling
- If a user tries to join without an invitation (and is not the first user), access is denied and they are signed out.
- If an invitation is already accepted, the user can log in as normal.

---

## Best Practices
- Only the first user can become admin.
- All other users must be invited by the admin.
- Always check Firestore for user and invitation documents during onboarding.
- Store roles and permissions as arrays of strings in Firestore, mapped to enums in code.

---

## See Also
- [`docs/ROLES_PERMISSIONS_STRATEGY.md`](../ROLES_PERMISSIONS_STRATEGY.md) for details on roles/permissions mapping.
- `auth_firebase_api.dart` for implementation details.
