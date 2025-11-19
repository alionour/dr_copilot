# Authentication System Improvement Plan

## Current Issues
1. Owner and staff detection relies on manual JSON configuration
2. No clear distinction between main admin users and clinic-specific users
3. Staff members are not properly authenticated in the system
4. Notification targeting doesn't work well with current auth flow

## Approved Solution

### Phase 1: Database Schema Enhancement
Add user role and clinic association fields to Firestore users collection:

```
users/{userId}
  - email: string
  - name: string
  - role: string (enum: 'super_admin', 'clinic_owner', 'doctor', 'staff', 'patient')
  - clinicIds: array<string> (clinics the user belongs to or owns)
  - isMainAdmin: boolean (true for super_admin and clinic_owner)
  - createdAt: timestamp
  - updatedAt: timestamp
```

### Phase 2: Update Auth Models
- Update UserModel to include new fields
- Add role enum
- Update serialization/deserialization

### Phase 3: Update Login Flow
- After Firebase Authentication, fetch user document
- Store complete user profile including role and clinicIds
- Update app state management to use role-based access

### Phase 4: Registration Enhancement
- Clinic owner registration creates user with 'clinic_owner' role
- Staff registration requires clinic ID and sets 'staff' role
- Default users get 'patient' role

### Phase 5: Update Authorization Checks
- Replace JSON config checks with role-based checks
- Add helper methods: isOwner(), isStaff(), isDoctor(), isSuperAdmin()
- Update UI visibility based on roles

### Phase 6: Notification System Integration
- Update notification targeting to use user roles
- Super admin can send to all users
- Clinic owners can send to users in their clinics
- Proper filtering based on role and clinic association

## Implementation Order
1. Update Firestore schema and rules
2. Update UserModel and related code
3. Update login/registration flows
4. Update authorization checks throughout app
5. Update notification targeting
6. Test all flows

## Benefits
- Clear role-based access control
- Proper multi-tenancy support
- Scalable notification system
- No manual configuration needed
- Better security and data isolation
