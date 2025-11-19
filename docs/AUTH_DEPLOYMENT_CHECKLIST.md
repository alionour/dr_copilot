# Authentication System Deployment Checklist

## Overview
This checklist ensures the improved role-based authentication system is properly deployed and configured.

## Pre-Deployment Checklist

### ✅ Code Changes Completed
- [x] Updated UserModel with helper methods (isSuperAdmin, isOwner, etc.)
- [x] Added superAdmin role to AppRole enum
- [x] Updated Firestore security rules
- [x] Verified notification targeting logic
- [x] Generated JSON serialization code
- [x] Created documentation

### 📋 Files Modified
- `lib/src/features/auth/domain/models/user_model.dart` - Added role helper methods
- `lib/src/features/auth/domain/models/role_enum.dart` - Added superAdmin role
- `firestore.rules` - Enhanced security rules with role-based access
- Various documentation files in `docs/`

## Deployment Steps

### Step 1: Deploy Firestore Rules

**Manual Deployment via Firebase Console:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Dr. Copilot project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the contents of `firestore.rules` from your project
5. Paste into the Rules editor
6. Click **Publish**
7. Wait for deployment confirmation

**Alternative: CLI Deployment (if Firebase CLI is working):**
```bash
firebase deploy --only firestore:rules
```

**Verify Deployment:**
- Check the "Rules" tab shows the updated rules
- Look for the `isSuperAdmin()` function
- Verify the update timestamp

### Step 2: Create Super Admin Account(s)

Follow the guide in `SETUP_SUPER_ADMIN.md`:

1. **Identify Programmer Account(s)**
   - Email: ________________
   - Purpose: System administration

2. **Add Super Admin Role via Firebase Console**
   - Navigate to Firestore Database
   - Go to `users` collection
   - Find user document by email
   - Edit the `roles` field
   - Add `"superAdmin"` to the array
   - Save changes

3. **Verify Super Admin Access**
   - Sign in with super admin account
   - Check debug mode features
   - Test notification sending

### Step 3: Test Authentication Flow

#### New User Sign-Up Test
- [ ] Sign up with new email (Google or Email/Password)
- [ ] Verify new clinic is created
- [ ] Confirm user has 'admin' role
- [ ] Check `ownerId` matches user uid
- [ ] Verify `clinicIds` contains new clinic

#### Existing User Sign-In Test
- [ ] Sign in with existing account
- [ ] Verify roles are loaded correctly
- [ ] Check clinic membership
- [ ] Confirm FCM token is updated

#### Staff Invitation Test
- [ ] Create invitation as clinic owner
- [ ] New user signs up with invited email
- [ ] Verify invitation is accepted
- [ ] Check user has correct roles
- [ ] Confirm clinic membership

### Step 4: Test Role-Based Features

#### Super Admin Features
- [ ] Access debug notification sender
- [ ] Send notification to all users
- [ ] View all clinics data
- [ ] Access system-wide reports

#### Clinic Owner Features
- [ ] Send notifications to clinic members
- [ ] Invite staff members
- [ ] Manage clinic settings
- [ ] View clinic-specific data

#### Staff Member Features
- [ ] Access assigned clinic data
- [ ] Cannot access other clinics
- [ ] Cannot send notifications
- [ ] Role-appropriate UI elements

### Step 5: Verify Security Rules

#### Test User Collection Access
```javascript
// As authenticated user - should succeed
firestore.collection('users').doc(currentUserId).get()

// As authenticated user - should fail
firestore.collection('users').doc(otherUserId).get()

// As super admin - should succeed
firestore.collection('users').doc(anyUserId).get()
```

#### Test Clinic Collection Access
```javascript
// As clinic owner - should succeed
firestore.collection('clinics').doc(ownedClinicId).get()

// As clinic member - should succeed
firestore.collection('clinics').doc(memberClinicId).get()

// As non-member - should fail
firestore.collection('clinics').doc(otherClinicId).get()
```

#### Test Notification Creation
```javascript
// As super admin - should succeed
firestore.collection('notifications').add({...})

// As clinic owner - should succeed
firestore.collection('notifications').add({...})

// As staff member - should fail
firestore.collection('notifications').add({...})
```

### Step 6: Update App Version

1. **Update pubspec.yaml Version**
   ```yaml
   version: 1.x.x+build
   ```

2. **Create Git Tag**
   ```bash
   git tag -a v1.x.x -m "Improved role-based authentication"
   git push origin v1.x.x
   ```

3. **Build and Deploy**
   ```bash
   # For Android
   flutter build apk --release
   
   # For iOS
   flutter build ios --release
   
   # For Web
   flutter build web --release
   ```

## Post-Deployment Verification

### Immediate Checks (Day 1)

- [ ] Monitor error logs in Firebase Console
- [ ] Check authentication success rate
- [ ] Verify no security rule violations
- [ ] Test notification delivery
- [ ] Confirm role assignments working

### Short-term Monitoring (Week 1)

- [ ] Track user sign-ups and logins
- [ ] Monitor Firestore read/write patterns
- [ ] Check for permission errors
- [ ] Verify FCM token updates
- [ ] Review notification sending patterns

### Data Migration (if needed)

If you have existing users without proper roles:

```javascript
// Migration script
async function migrateUsers() {
  const usersSnapshot = await db.collection('users').get();
  
  const batch = db.batch();
  let count = 0;
  
  usersSnapshot.forEach(doc => {
    const data = doc.data();
    
    // Add roles if missing
    if (!data.roles || data.roles.length === 0) {
      const roles = [];
      
      // Determine role based on data
      if (data.ownerId === doc.id) {
        roles.push('admin');
      } else {
        roles.push('readonly');
      }
      
      batch.update(doc.ref, { roles });
      count++;
    }
    
    // Commit every 500 updates
    if (count % 500 === 0) {
      await batch.commit();
    }
  });
  
  if (count % 500 !== 0) {
    await batch.commit();
  }
  
  console.log(`Migrated ${count} users`);
}
```

## Rollback Plan

If issues occur, rollback steps:

### Emergency Rollback

1. **Revert Firestore Rules**
   - Go to Firebase Console → Firestore → Rules
   - Click on "Rules History"
   - Select previous version
   - Click "Restore"

2. **Remove Super Admin Roles**
   - Edit user documents
   - Remove 'superAdmin' from roles array

3. **Revert Code Changes**
   ```bash
   git revert <commit-hash>
   git push origin dev
   ```

### Partial Rollback

If only some features have issues:

1. Keep new role helper methods
2. Revert Firestore rules to previous version
3. Disable new notification features temporarily

## Troubleshooting

### Common Issues

#### Issue: Super Admin Can't Access Features
**Solution:**
- Verify role is saved correctly in Firestore
- Check spelling: `"superAdmin"` (camelCase)
- Sign out and sign in again
- Clear app cache/data

#### Issue: Staff Members Can't Access Clinic
**Solution:**
- Verify `clinicIds` array includes clinic ID
- Check invitation was accepted
- Confirm roles are assigned
- Verify Firestore rules are deployed

#### Issue: Permission Denied Errors
**Solution:**
- Check Firestore rules are published
- Verify user has required roles
- Test rules in Firebase Console simulator
- Check rule functions are defined correctly

#### Issue: Notifications Not Sending
**Solution:**
- Verify sender has appropriate role
- Check target users exist
- Confirm FCM tokens are registered
- Review notification creation logs

## Support Resources

- **Auth System Overview**: `docs/AUTH_SYSTEM_OVERVIEW.md`
- **Setup Super Admin**: `docs/SETUP_SUPER_ADMIN.md`
- **Firebase Console**: https://console.firebase.google.com
- **Firestore Rules Reference**: https://firebase.google.com/docs/firestore/security/get-started

## Sign-off

Deployment completed by: _______________

Date: _______________

Verification completed by: _______________

Date: _______________

Issues encountered: 
_______________________________________________
_______________________________________________
_______________________________________________

Resolution:
_______________________________________________
_______________________________________________
_______________________________________________
