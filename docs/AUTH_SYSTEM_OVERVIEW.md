# Authentication System Overview

## System Architecture

### User Roles
The application supports the following roles:

1. **superAdmin** - System-wide administrator (programmer/app maintainer)
   - Can send notifications to all users
   - Full system access
   - Manually assigned in Firestore

2. **admin** - Clinic owner
   - Can create and manage their clinics
   - Can invite staff members
   - Can send notifications to users in their clinics
   - Automatically assigned when user creates their first clinic

3. **doctor** - Medical professional
   - Can view and manage appointments
   - Assigned via invitation or clinic owner

4. **staff** - Clinic staff member
   - Limited access based on permissions
   - Assigned via invitation or clinic owner

5. **financial** - Financial manager
   - Access to financial records
   - Assigned via invitation or clinic owner

6. **readonly** - Read-only access
   - Can view but not modify data
   - Default role for invited users

### Database Schema

#### Users Collection (`users/{userId}`)
```javascript
{
  uid: string,
  email: string,
  displayName: string,
  roles: string[],              // e.g., ['admin', 'doctor']
  permissions: string[],         // e.g., ['read_patients', 'write_patients']
  ownerId: string,              // ID of the clinic owner (for staff)
  clinicIds: string[],          // Array of clinic IDs user belongs to
  primaryClinicId: string,      // Main clinic ID
  createdAt: Timestamp,
  photoURL: string,
  phoneNumber: string
}
```

#### Clinics Collection (`clinics/{clinicId}`)
```javascript
{
  id: string,
  ownerId: string,              // User ID of the clinic owner
  name: string,
  adminEmail: string,
  createdAt: Timestamp,
  settings: {
    // Clinic-specific settings
  }
}
```

#### User Invitations Collection (`user_invitations/{invitationId}`)
```javascript
{
  email: string,
  clinicId: string,
  roles: string[],
  permissions: string[],
  invitedBy: string,            // User ID of inviter
  status: string,               // 'pending', 'accepted', 'rejected'
  createdAt: Timestamp,
  acceptedAt: Timestamp
}
```

## Authentication Flow

### 1. New User Sign-Up (Google or Email/Password)

```
User Signs Up
     ↓
Firebase Authentication Creates Account
     ↓
Check if user document exists in Firestore
     ↓
     ├─→ User Exists
     │   └─→ Load existing user data (roles, clinicIds, etc.)
     │
     └─→ User Does NOT Exist
         ↓
         Check for pending invitations (by email)
         ↓
         ├─→ Invitations Found
         │   ├─→ Accept all invitations
         │   ├─→ Aggregate roles, permissions, clinicIds
         │   └─→ Create user document with aggregated data
         │
         └─→ No Invitations
             ├─→ Create new clinic
             ├─→ Assign 'admin' role
             ├─→ Set ownerId = uid
             ├─→ Set clinicIds = [newClinicId]
             └─→ Create user document
```

### 2. Existing User Sign-In

```
User Signs In
     ↓
Firebase Authentication Validates Credentials
     ↓
Fetch user document from Firestore
     ↓
Load UserModel with:
     - roles
     - permissions
     - clinicIds
     - ownerId
     ↓
Initialize FCM (Firebase Cloud Messaging)
     ↓
User Authenticated and Ready
```

### 3. Staff Invitation Flow

```
Clinic Owner Invites Staff
     ↓
Create invitation document in 'user_invitations'
     - email
     - clinicId
     - roles
     - permissions
     - invitedBy
     ↓
Staff receives invitation email (manual or automated)
     ↓
Staff signs up with invited email
     ↓
System finds pending invitation
     ↓
Accept invitation:
     - Create user document
     - Add roles and permissions from invitation
     - Add clinic to clinicIds
     - Set ownerId to inviter's ID
     ↓
Staff has access to clinic
```

## Role-Based Access Control (RBAC)

### UserModel Helper Methods

```dart
// Role checking
bool get isSuperAdmin      // Check if user is super admin
bool get isAdmin          // Check if user is clinic owner
bool get isOwner          // Check if user owns clinic (isAdmin && ownerId == uid)
bool get isDoctor         // Check if user is doctor
bool get isStaff          // Check if user is staff
bool get isFinancial      // Check if user is financial
bool get isReadonly       // Check if user is readonly
bool get isMainAdmin      // Check if user is super admin or owner

// Clinic membership
bool belongsToClinic(String clinicId)

// Advanced checks
bool hasAnyRole(List<AppRole> roles)
bool hasAllRoles(List<AppRole> roles)
bool hasPermission(AppPermission permission)
bool hasAnyPermission(List<AppPermission> permissions)
```

### Usage Examples

```dart
// Check if user can send notifications
if (currentUser.isMainAdmin) {
  // Show notification sending UI
}

// Check if user belongs to specific clinic
if (currentUser.belongsToClinic(clinicId)) {
  // Show clinic data
}

// Check multiple roles
if (currentUser.hasAnyRole([AppRole.admin, AppRole.doctor])) {
  // Show medical features
}
```

## Notification System Integration

### Notification Targeting

The notification system uses the role-based architecture:

1. **Super Admin** can send to:
   - All clinic owners
   - All doctors
   - All staff
   - Specific roles
   - All users

2. **Clinic Owner** can send to:
   - All users in their owned clinics
   - Specific clinic
   - Specific roles within their clinics

### Notification Target Types

```dart
enum NotificationTargetType {
  allClinicOwners,    // All users with 'admin' role
  allDoctors,         // All users with 'doctor' role
  allStaff,           // All users with 'staff' role
  specificRoles,      // Users with specific roles
  ownerClinics,       // All users in clinics owned by sender
  specificClinic,     // Users in specific clinic
}
```

## Security Rules

Firestore security rules enforce role-based access:

```javascript
// Users can read their own data
// Admins can read users in their clinics
// Super admins can read all users

// Clinics can be read by:
// - Super admins
// - Clinic owners
// - Users belonging to the clinic

// Notifications can be created by:
// - Super admins
// - Clinic owners
```

## Migration from Old System

### Step 1: Identify Super Admins
Manually add `superAdmin` role to programmer accounts in Firestore:

```javascript
// In Firestore Console, update users/{programmerId}
{
  roles: ['superAdmin']
}
```

### Step 2: Existing Users
All existing users should already have proper roles. Verify:
- Check `roles` field contains appropriate values
- Check `clinicIds` contains clinic memberships
- Check `ownerId` for staff members

### Step 3: Update Application Code
✅ UserModel with helper methods (completed)
✅ Role enum with superAdmin (completed)
✅ Firestore security rules (completed)
✅ Notification targeting (already implemented)

## Best Practices

### For Programmers (Super Admins)
1. Use debug notification sender page in debug mode only
2. Don't create super admin accounts for regular users
3. Super admin access should be limited to 1-2 accounts

### For Clinic Owners
1. Create clinic on first sign-up
2. Invite staff members via email
3. Assign appropriate roles to staff
4. Use notification system to communicate with staff

### For Development
1. Test with multiple role combinations
2. Verify Firestore rules in Firebase Console
3. Use role helper methods instead of direct role checks
4. Always check clinic membership for data access

## Pros and Cons

### Pros
✅ **Clear Role Hierarchy** - Well-defined roles with specific permissions
✅ **Multi-tenancy Support** - Users can belong to multiple clinics
✅ **Scalable** - No manual JSON configuration needed
✅ **Secure** - Firestore rules enforce access control
✅ **Flexible** - Easy to add new roles and permissions
✅ **Audit Trail** - Invitation system tracks who invited whom

### Cons
❌ **Initial Complexity** - More complex than simple authentication
❌ **Database Reads** - Security rules require extra reads to check roles
❌ **Migration Effort** - Existing systems need data migration
❌ **Role Management** - Requires UI for role assignment (partially implemented)

## Future Enhancements

1. **Role Management UI** - Allow admins to assign roles via UI
2. **Permission Builder** - Visual permission assignment tool
3. **Audit Logs** - Track role changes and permission grants
4. **Temporary Permissions** - Time-limited access grants
5. **Role Templates** - Predefined role combinations for common scenarios
