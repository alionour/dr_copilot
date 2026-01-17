# Setting Up Super Admin Accounts

## Overview
Super admin accounts have system-wide privileges and can send notifications to all users, manage all clinics, and access all data. This guide explains how to create and manage super admin accounts.

## Prerequisites
- Access to Firebase Console
- Firestore database access
- User must be already registered in the app

## Steps to Create Super Admin

### Method 1: Firebase Console (Recommended)

1. **Sign in to Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your Dr. Copilot project

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in left sidebar
   - Select the `users` collection

3. **Find the User Document**
   - Find the user you want to make super admin
   - The document ID is the user's UID

4. **Add Super Admin Role**
   - Click on the user document
   - Edit the `roles` field
   - Add `"superAdmin"` to the array
   
   Example before:
   ```json
   {
     "roles": ["admin"]
   }
   ```
   
   Example after:
   ```json
   {
     "roles": ["admin", "superAdmin"]
   }
   ```

5. **Save Changes**
   - Click "Update"
   - The user now has super admin privileges

### Method 2: Using Firebase Admin SDK (For Automated Setup)

If you're setting up multiple super admins or want automation:

1. Create a Node.js script:

```javascript
// setup-super-admin.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addSuperAdmin(userEmail) {
  try {
    // Find user by email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', userEmail)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.log('User not found');
      return;
    }

    const userDoc = usersSnapshot.docs[0];
    const currentRoles = userDoc.data().roles || [];
    
    // Add superAdmin if not already present
    if (!currentRoles.includes('superAdmin')) {
      await userDoc.ref.update({
        roles: [...currentRoles, 'superAdmin']
      });
      console.log(`Super admin role added to ${userEmail}`);
    } else {
      console.log(`${userEmail} is already a super admin`);
    }
  } catch (error) {
    console.error('Error adding super admin:', error);
  }
}

// Usage
const email = 'your-email@example.com';
addSuperAdmin(email).then(() => {
  console.log('Done');
  process.exit(0);
});
```

2. Run the script:
```bash
npm install firebase-admin
node setup-super-admin.js
```

### Method 3: Firestore REST API

Using curl or any HTTP client:

```bash
# Get user document
USER_ID="your-user-id"
PROJECT_ID="your-project-id"

curl -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${USER_ID}?updateMask.fieldPaths=roles" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "roles": {
        "arrayValue": {
          "values": [
            {"stringValue": "admin"},
            {"stringValue": "superAdmin"}
          ]
        }
      }
    }
  }'
```

## Verification

After adding the super admin role, verify it works:

1. **Sign in to the app** with the super admin account

2. **Check Debug Mode Access**
   - In debug mode, you should see the debug notification sender
   - Navigate to the notifications page

3. **Test Notification Sending**
   - Try sending a notification to all users
   - Check if the notification was created successfully

4. **Verify in Code**
   ```dart
   final currentUser = await authUseCase.getCurrentUser();
   print('Is Super Admin: ${currentUser?.isSuperAdmin}');
   print('Is Main Admin: ${currentUser?.isMainAdmin}');
   ```

## Security Considerations

### ⚠️ Important Security Notes

1. **Limit Super Admin Accounts**
   - Only create 1-2 super admin accounts
   - Super admins have unrestricted access

2. **Use Secure Accounts**
   - Enable 2FA on super admin accounts
   - Use strong passwords
   - Never share super admin credentials

3. **Audit Super Admin Actions**
   - Monitor Firestore activity logs
   - Track notification sending patterns
   - Review data access regularly

4. **Separate Development and Production**
   - Use different super admins for dev/prod
   - Never test with production super admin account

## Managing Super Admin Privileges

### Revoking Super Admin Access

To remove super admin privileges:

1. Go to Firebase Console
2. Navigate to the user document
3. Edit the `roles` field
4. Remove `"superAdmin"` from the array
5. Save changes

### Checking Current Super Admins

Query Firestore to find all super admins:

```javascript
const superAdmins = await db.collection('users')
  .where('roles', 'array-contains', 'superAdmin')
  .get();

superAdmins.forEach(doc => {
  console.log('Super Admin:', doc.data().email);
});
```

## Troubleshooting

### Super Admin Can't Access Features

**Problem**: User has superAdmin role but can't access features

**Solutions**:
1. Check if user is properly signed in
2. Verify the role is spelled correctly: `"superAdmin"` (camelCase)
3. Make sure app has latest user data (sign out and sign in again)
4. Check Firestore rules are deployed
5. Verify UserModel is loading roles correctly

### Role Not Showing in App

**Problem**: Added superAdmin role but app doesn't recognize it

**Solutions**:
1. Sign out and sign in again to refresh user data
2. Check if `UserModel.isSuperAdmin` getter is working
3. Verify role enum includes `superAdmin`
4. Check if roles are being parsed correctly from Firestore

### Permission Denied Errors

**Problem**: Super admin gets permission denied errors

**Solutions**:
1. Deploy latest Firestore rules
2. Check if rules include `isSuperAdmin()` function
3. Verify user document has the role correctly saved
4. Check Firestore rules in Firebase Console

## Best Practices

### For Initial Setup
1. Create your first super admin account immediately after deployment
2. Test super admin features before creating more accounts
3. Document which email is the primary super admin

### For Ongoing Management
1. Review super admin list quarterly
2. Remove super admin access when no longer needed
3. Keep a backup super admin account
4. Use environment-specific super admins

### For Development
1. Create a test super admin for development
2. Never use production super admin in development
3. Test role-based access with multiple accounts
4. Verify Firestore rules changes don't break super admin access

## Example Super Admin Setup Script

Complete script for initial setup:

```javascript
// initial-setup.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupInitialSuperAdmin() {
  const SUPER_ADMIN_EMAIL = 'your-email@example.com';
  
  try {
    // Find user
    const usersSnapshot = await db.collection('users')
      .where('email', '==', SUPER_ADMIN_EMAIL)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.error('❌ User not found. Please sign up first.');
      return;
    }

    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();
    const currentRoles = userData.roles || [];
    
    // Add superAdmin role
    if (!currentRoles.includes('superAdmin')) {
      await userDoc.ref.update({
        roles: admin.firestore.FieldValue.arrayUnion('superAdmin')
      });
      console.log('✅ Super admin role added successfully');
    } else {
      console.log('ℹ️  User is already a super admin');
    }
    
    // Display user info
    console.log('\n📋 Super Admin Details:');
    console.log('Email:', userData.email);
    console.log('Name:', userData.displayName);
    console.log('Roles:', userData.roles);
    console.log('User ID:', userDoc.id);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

setupInitialSuperAdmin().then(() => {
  console.log('\n✨ Setup complete');
  process.exit(0);
});
```

Run it:
```bash
npm install firebase-admin
node initial-setup.js
```

## Support

If you encounter issues:
1. Check the AUTH_SYSTEM_OVERVIEW.md documentation
2. Verify Firestore rules are deployed
3. Check Firebase Console logs
4. Review authentication flow in the app
