# Onboarding & Multi-Clinic Flow in Dr Copilot

This document describes the onboarding logic for Google sign-in, user creation, and how to extend the system for multi-clinic support.

---

## Onboarding Flow (Current Implementation)

1. **User signs in with Google.**
2. **Check if user doc exists in `users`:**
   - **If exists:** Fetch roles, permissions, and `ownerId`. User is already onboarded and linked to a clinic/owner.
   - **If not exists:**
     - **Check for invitation by email in `user_invitations`:**
       - If found: Create user doc as subuser (roles/permissions/ownerId from invitation), mark invitation accepted.
       - If not found: Create user doc as owner/admin (self-owned clinic).
3. **All user docs have an `ownerId` field** (admin’s UID for subusers, own UID for owners).

### Why This Works
- **Security:** Only invited users can join as subusers. No invitation = no subuser access.
- **Idempotency:** Repeated sign-ins do not create duplicate users.
- **Traceability:** `ownerId` links subusers to their clinic/owner.
- **Scalability:** Query all users for a clinic with `where('ownerId', isEqualTo: adminUid)`.

---

## Multi-Clinic Support: Design & Best Practices

### 1. **Schema Change: Add `clinicId` Field**
- Instead of (or in addition to) `ownerId`, add a `clinicId` field to each user document.
- Each clinic gets a unique `clinicId` (could be the admin's UID, or a generated string).
- All users (admin and subusers) for a clinic have the same `clinicId`.

**Example user doc:**
```json
{
  "uid": "user123",
  "roles": ["doctor"],
  "permissions": ["can_view_patient"],
  "clinicId": "clinic_abc123",
  "ownerId": "admin_uid"
}
```

### 2. **Clinic Collection (Optional)**
- Create a top-level `clinics` collection:
  - Each doc: `{ clinicId, name, ownerId, createdAt, ... }`
- Link users to clinics via `clinicId`.

### 3. **Invitation Flow for Multi-Clinic**
- Invitations should include a `clinicId` field.
- When a user accepts an invitation, their user doc is created with the correct `clinicId` and `ownerId`.
- A user can be a member of multiple clinics (if you allow it) by having multiple user docs (one per clinic, or a subcollection/array of memberships).

### 4. **Onboarding Logic (Multi-Clinic)**
- On sign-in, check if a user doc exists for the given `clinicId` and `uid` (or email):
  - If exists: Fetch roles/permissions/clinicId.
  - If not: Check for invitation for that clinic/email.
    - If found: Create user doc for that clinic.
    - If not: Allow to create a new clinic (become owner/admin of a new clinic).

### 5. **Querying Users by Clinic**
- To get all users for a clinic:
  ```dart
  FirebaseFirestore.instance.collection('users').where('clinicId', isEqualTo: clinicId)
  ```
- To get all clinics for a user (if multi-membership):
  ```dart
  FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: userId)
  ```

### 6. **UI/UX Considerations**
- Allow users to select or create a clinic on sign-in if they are not already a member.
- Show a list of clinics a user belongs to (if multi-membership is supported).
- Admins can manage invitations and users per clinic.

---

## Best Practices for Multi-Clinic SaaS
- **Single Source of Truth:** Use a top-level `users` and `clinics` collection.
- **Explicit Linking:** Always link users to clinics via `clinicId`.
- **Invitation Security:** Only allow joining a clinic via invitation, unless creating a new clinic.
- **Flexible Membership:** Support multiple clinics per user if needed, using either multiple user docs or a `memberships` array.
- **Easy Querying:** Design your schema for efficient queries by `clinicId` and `uid`.

---

## Example Firestore Structure
```
clinics/
  clinic_abc123/
    { name, ownerId, createdAt, ... }
users/
  user_uid_1/  // { uid, clinicId, ownerId, roles, ... }
  user_uid_2/  // { uid, clinicId, ownerId, roles, ... }
user_invitations/
  invite_id_1/ // { email, clinicId, invitedBy, roles, ... }
```

---

## Migration Path
- If you want to migrate from single-clinic to multi-clinic:
  1. Add a `clinicId` field to all user and invitation docs.
  2. Create a `clinics` collection and migrate existing owners/admins as clinic owners.
  3. Update onboarding and invitation logic to use `clinicId`.

---

## References
- See `ONBOARDING_AND_INVITATION_FLOW.md` for the full onboarding flow.
- See `ROLES_PERMISSIONS_STRATEGY.md` for roles/permissions mapping.
