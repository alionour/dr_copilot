# Dr AI - Complete Authentication & Invitation System Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [Authentication Flow](#authentication-flow)
5. [Invitation System](#invitation-system)
6. [Role-Based Access Control](#role-based-access-control)
7. [API Reference](#api-reference)
8. [Frontend Implementation](#frontend-implementation)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

Dr AI uses a **token-based invitation system** with **Google Sign-In authentication** and **role-based access control** to manage multi-clinic healthcare operations.

### Key Features

- ✅ **Google Sign-In Only** - Simplified, secure authentication
- ✅ **Token-Based Invitations** - Secure, expiring invitation links
- ✅ **Multi-Clinic Support** - Users can belong to multiple clinics
- ✅ **Role-Based Access** - Owner, Doctor, Staff roles with different permissions
- ✅ **Email Notifications** - AWS SES for invitation emails
- ✅ **Web + Desktop** - Unified authentication across platforms

### Technology Stack

**Backend**:
- AWS Lambda (Serverless)
- Node.js + Express
- Firebase Admin SDK
- AWS SES (Email)

**Frontend**:
- Flutter (Desktop & Web)
- Firebase Auth
- Cloud Firestore

**Infrastructure**:
- Firebase Hosting (Web app)
- AWS API Gateway
- Doppler (Secrets management)

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Dr AI System                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ Desktop App  │         │   Web App    │                 │
│  │  (Flutter)   │         │  (Flutter)   │                 │
│  └──────┬───────┘         └──────┬───────┘                 │
│         │                        │                          │
│         └────────┬───────────────┘                          │
│                  │                                           │
│         ┌────────▼─────────┐                                │
│         │  Firebase Auth   │                                │
│         │  (Google OAuth)  │                                │
│         └────────┬─────────┘                                │
│                  │                                           │
│         ┌────────▼─────────┐                                │
│         │   Firestore DB   │                                │
│         │  - users/        │                                │
│         │  - clinics/      │                                │
│         │  - invitations/  │                                │
│         └──────────────────┘                                │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Backend (AWS Lambda)                     │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Express.js API                                 │  │  │
│  │  │  - POST /invitations/create                     │  │  │
│  │  │  - GET  /invitations/verify                     │  │  │
│  │  │  - POST /invitations/accept                     │  │  │
│  │  │  - GET  /accept-invitation (HTML page)          │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  AWS SES (Email Service)                        │  │  │
│  │  │  - Send invitation emails                       │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Component Interaction

```
Desktop App (Admin)
    │
    ├─→ Creates Invitation
    │   └─→ Backend API: POST /invitations/create
    │       ├─→ Generates token
    │       ├─→ Stores in Firestore
    │       └─→ Sends email via AWS SES
    │
Email Link
    │
    └─→ User clicks link
        └─→ Opens: https://backend-url/accept-invitation?token=xxx
            │
            ├─→ Backend serves HTML page
            │   └─→ Verifies token: GET /invitations/verify
            │
            ├─→ User signs in with Google
            │   └─→ Firebase Auth popup
            │
            └─→ Accept invitation: POST /invitations/accept
                ├─→ Updates invitation status
                ├─→ Adds user to clinic members
                └─→ Updates user's clinic list
```

---

## Database Schema

### Firestore Collections

#### 1. `users/{userId}`

**Purpose**: Store global user information

**Schema**:
```typescript
{
  uid: string;                    // Firebase Auth UID (Primary Key)
  displayName: string;            // User's full name
  email: string;                  // User's email
  emailVerified: boolean;
  photoURL: string;               // Profile picture URL
  
  // Multi-Clinic Support
  clinicIds: string[];            // ["clinic_123", "clinic_456"]
  primaryClinicId: string;        // Default clinic
  
  // Owner Identification
  ownerId: string;                // If user is owner, this equals uid
  
  // Metadata
  phoneNumber?: string;
  providerData: any[];
  metadata: any;
}
```

**Example**:
```json
{
  "uid": "abc123xyz",
  "displayName": "Dr. John Smith",
  "email": "john.smith@example.com",
  "emailVerified": true,
  "photoURL": "https://lh3.googleusercontent.com/...",
  "clinicIds": ["clinic_456"],
  "primaryClinicId": "clinic_456",
  "ownerId": "",
  "phoneNumber": "+1234567890"
}
```

**Note**: `roles` and `permissions` are NO LONGER stored here. They are strictly in `clinics/{id}/members/{uid}` (Single Source of Truth).
```

**Created When**:
- User signs in for the first time (via Google)
- Automatically by Firebase Auth

**Updated When**:
- User accepts invitation (adds clinicId)
- Admin changes user roles/permissions

---

#### 2. `clinics/{clinicId}`

**Purpose**: Store clinic information

**Schema**:
```typescript
{
  id: string;                     // Clinic ID (Primary Key)
  name: string;                   // Clinic name
  location: string;               // Physical address
  ownerId: string;                // References users/{userId}
  adminEmail: string;             // Owner's email
  createdAt: Timestamp;           // When clinic was created
}
```

**Example**:
```json
{
  "id": "clinic_456",
  "name": "Smith Medical Center",
  "location": "123 Main St, City, State 12345",
  "ownerId": "owner_uid_123",
  "adminEmail": "admin@smithmedical.com",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Created When**:
- Owner creates a new clinic

**Relationships**:
- `ownerId` → `users/{userId}.uid`

---

#### 3. `clinics/{clinicId}/members/{userId}`

**Purpose**: Store clinic-specific member information

**Schema**:
```typescript
{
  userId: string;                 // References users/{userId} (Primary Key)
  email: string;                  // Member's email
  name: string;                   // Member's name
  role: "doctor" | "staff";       // Role in THIS clinic
  addedAt: Timestamp;             // When added to clinic
  addedVia: "invitation" | "manual";  // How they joined
}
```

**Example**:
```json
{
  "userId": "abc123xyz",
  "email": "john.smith@example.com",
  "name": "Dr. John Smith",
  "role": "doctor",
  "addedAt": "2024-01-20T14:30:00Z",
  "addedVia": "invitation"
}
```

**Created When**:
- User accepts invitation
- Admin manually adds member

**Relationships**:
- `userId` → `users/{userId}.uid`
- Parent: `clinics/{clinicId}`

**Important**: Same user can have different roles in different clinics!

---

#### 4. `invitations/{token}`

**Purpose**: Store invitation tokens and metadata

**Schema**:
```typescript
{
  token: string;                  // Unique invitation token (Primary Key)
  recipientEmail: string;         // Who is invited
  recipientName: string;          // Invitee's name
  clinicId: string;               // Which clinic
  clinicName: string;             // Clinic name (for display)
  role: "doctor" | "staff";       // Assigned role
  status: "pending" | "accepted"; // Invitation status
  createdAt: Timestamp;           // When created
  expiresAt: Timestamp;           // When expires (7 days)
  acceptedAt: Timestamp | null;   // When accepted
  acceptedBy: string | null;      // User ID who accepted
}
```

**Example**:
```json
{
  "token": "a3b87a5f4ba62ea1a84d97c97ef9a73a79356657d598ac038587a9eb484b71bf",
  "recipientEmail": "doctor@example.com",
  "recipientName": "Dr. Jane Doe",
  "clinicId": "clinic_456",
  "clinicName": "Smith Medical Center",
  "role": "doctor",
  "status": "pending",
  "createdAt": "2024-01-20T10:00:00Z",
  "expiresAt": "2024-01-27T10:00:00Z",
  "acceptedAt": null,
  "acceptedBy": null
}
```

**Created When**:
- Admin creates invitation

**Updated When**:
- User accepts invitation (status → "accepted", acceptedAt, acceptedBy)

**Lifecycle**:
1. Created: `status = "pending"`
2. Accepted: `status = "accepted"`, `acceptedAt` set, `acceptedBy` set
3. Expired: `expiresAt < now()` (checked on verification)

---

### Schema Relationships

```
users/{userId}
    │
    ├─→ clinicIds: ["clinic_A", "clinic_B"]
    │   │
    │   └─→ clinics/clinic_A
    │       └─→ members/{userId}
    │           └─→ role: "doctor"
    │
    └─→ clinics/clinic_B
        └─→ members/{userId}
            └─→ role: "staff"
```

### Data Flow Example

**Scenario**: Dr. Smith accepts invitation to join clinic

```
1. Invitation Created:
   invitations/token123
   {
     recipientEmail: "smith@example.com",
     clinicId: "clinic_456",
     role: "doctor",
     status: "pending"
   }

2. User Signs In (First Time):
   users/abc123
   {
     uid: "abc123",
     email: "smith@example.com",
     clinicIds: [],
     roles: []
   }

3. User Accepts Invitation:
   
   a) Update invitation:
      invitations/token123
      {
        status: "accepted",
        acceptedBy: "abc123",
        acceptedAt: Timestamp.now()
      }
   
   b) Add to clinic members:
      clinics/clinic_456/members/abc123
      {
        userId: "abc123",
        role: "doctor",
        addedVia: "invitation"
      }
   
   c) Update user:
      users/abc123
      {
        clinicIds: ["clinic_456"],
        primaryClinicId: "clinic_456",
        roles: ["doctor"]
      }
```

---

## Authentication Flow

### Google Sign-In Flow

#### Desktop App

```
1. User opens app
   │
2. Sees login page with "Sign in with Google" button
   │
3. Clicks button
   │
4. Google OAuth window opens
   ├─→ User selects Google account
   ├─→ Grants permissions
   └─→ Window closes
   │
5. Firebase Auth receives token
   │
6. App gets user credentials
   ├─→ uid
   ├─→ email
   ├─→ displayName
   └─→ photoURL
   │
7. Check if user exists in Firestore
   │
   ├─→ YES: Load user data
   │   ├─→ Get clinicIds
   │   ├─→ Get roles
   │   └─→ Navigate to home
   │
   └─→ NO: Create user document
       ├─→ Store basic info
       └─→ Navigate to onboarding
```

#### Web App (Invitation Acceptance)

```
1. User clicks invitation link
   │
2. Opens: https://backend-url/accept-invitation?token=xxx
   │
3. Backend serves HTML page
   │
4. Page verifies token
   ├─→ GET /invitations/verify?token=xxx
   └─→ Displays invitation details
   │
5. User clicks "Sign in with Google"
   │
6. Firebase Auth popup opens
   ├─→ User selects account
   ├─→ Grants permissions
   └─→ Popup closes
   │
7. JavaScript gets user info
   ├─→ user.uid
   └─→ user.email
   │
8. Accept invitation
   └─→ POST /invitations/accept
       {
         token: "xxx",
         userId: "user_uid"
       }
   │
9. Backend processes
   ├─→ Updates invitation status
   ├─→ Adds to clinic members
   └─→ Updates user document
   │
10. Success message displayed
    └─→ "You can now open the desktop app"
```

### Session Management

**Firebase Auth** handles session management automatically:

- **Desktop**: Session persists until user signs out
- **Web**: Session persists in browser storage
- **Token Refresh**: Automatic (handled by Firebase SDK)
- **Expiration**: Configurable (default: 1 hour, auto-refresh)

---

## Invitation System

### Creating an Invitation

#### Desktop App Flow

```dart
// 1. User fills invitation form
final invitation = InvitationModel(
  id: Firestore.instance.collection('invitations').doc().id,
  email: 'doctor@example.com',
  clinicId: currentClinicId,
  invitedBy: currentUserId,
  role: 'doctor',
  status: InvitationStatus.pending,
);

// 2. Call backend API
final response = await BackendService.sendInvitation(
  recipientEmail: invitation.email,
  recipientName: 'Dr. Smith',
  clinicId: invitation.clinicId,
  clinicName: 'My Clinic',
  role: 'doctor',
);

// 3. Backend generates token and sends email
```

#### Backend Processing

```javascript
// POST /invitations/create
router.post('/create', async (req, res) => {
  const { recipientEmail, recipientName, clinicId, clinicName, role } = req.body;
  
  // 1. Generate secure token
  const token = crypto.randomBytes(32).toString('hex');
  
  // 2. Store in Firestore
  await db.collection('invitations').doc(token).set({
    token,
    recipientEmail,
    recipientName,
    clinicId,
    clinicName,
    role,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    acceptedAt: null,
    acceptedBy: null
  });
  
  // 3. Send email via AWS SES
  const invitationLink = `${APP_URL}/accept-invitation?token=${token}`;
  await sendInvitationEmail(recipientEmail, invitationLink, clinicName, role);
  
  res.json({ success: true, token });
});
```

### Email Template

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; }
    .button { background-color: #4A90E2; color: white; padding: 12px 24px; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <h2>You're Invited!</h2>
    <p>Hello Dr. Smith,</p>
    <p>You have been invited to join <strong>Smith Medical Center</strong> as a <strong>doctor</strong>.</p>
    <a href="https://backend-url/accept-invitation?token=xxx" class="button">
      Accept Invitation & Sign Up
    </a>
    <p>This invitation expires in 7 days.</p>
  </div>
</body>
</html>
```

### Accepting an Invitation

#### Web Page Flow

```javascript
// 1. Verify token on page load
async function verifyInvitation() {
  const token = new URLSearchParams(window.location.search).get('token');
  
  const response = await fetch(`${BACKEND_URL}/invitations/verify?token=${token}`);
  const data = await response.json();
  
  if (data.valid) {
    displayInvitation(data.invitation);
  } else {
    showError(data.error);
  }
}

// 2. User signs in with Google
document.getElementById('google-signin').addEventListener('click', async () => {
  const provider = new firebase.auth.GoogleAuthProvider();
  const result = await auth.signInWithPopup(provider);
  const user = result.user;
  
  // 3. Accept invitation
  const response = await fetch(`${BACKEND_URL}/invitations/accept`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: token,
      userId: user.uid
    })
  });
  
  if (response.ok) {
    showSuccess('Invitation accepted!');
  }
});
```

#### Backend Processing

```javascript
// POST /invitations/accept
router.post('/accept', async (req, res) => {
  const { token, userId } = req.body;
  
  await db.runTransaction(async (transaction) => {
    const invitationRef = db.collection('invitations').doc(token);
    const invitationDoc = await transaction.get(invitationRef);
    
    if (!invitationDoc.exists) {
      throw new Error('Invalid invitation token');
    }
    
    const data = invitationDoc.data();
    
    // Check if already accepted
    if (data.status === 'accepted') {
      throw new Error('Invitation already accepted');
    }
    
    // Check expiration
    if (data.expiresAt.toDate() < new Date()) {
      throw new Error('Invitation has expired');
    }
    
    // 1. Update invitation status
    transaction.update(invitationRef, {
      status: 'accepted',
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedBy: userId
    });
    
    // 2. Add user to clinic members
    const clinicMemberRef = db.collection('clinics')
      .doc(data.clinicId)
      .collection('members')
      .doc(userId);
    
    transaction.set(clinicMemberRef, {
      userId,
      email: data.recipientEmail,
      name: data.recipientName,
      role: data.role,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
      addedVia: 'invitation'
    });
    
    // 3. Update user's clinics array
    const userRef = db.collection('users').doc(userId);
    transaction.set(userRef, {
      clinics: admin.firestore.FieldValue.arrayUnion({
        clinicId: data.clinicId,
        clinicName: data.clinicName,
        role: data.role,
        joinedAt: new Date()
      })
    }, { merge: true });
  });
  
  res.json({ success: true });
});
```

---

## Role-Based Access Control

### Role Hierarchy

```
superAdmin (System-wide admin)
    │
    ├─→ admin (Clinic owner)
    │   ├─→ Full clinic management
    │   ├─→ Invite users
    │   ├─→ Manage settings
    │   └─→ View all data
    │
    ├─→ doctor
    │   ├─→ Manage patients
    │   ├─→ Create appointments
    │   ├─→ Write prescriptions
    │   └─→ View clinic data
    │
    ├─→ staff
    │   ├─→ Schedule appointments
    │   ├─→ Check-in patients
    │   └─→ Limited data access
    │
    ├─→ financial
    │   ├─→ Billing
    │   ├─→ Payments
    │   └─→ Financial reports
    │
    └─→ readonly
        └─→ View-only access
```

### Permission System

```dart

```dart
enum AppPermission {
  // --- PATIENTS ---
  viewAllPatients, viewOwnPatients, createPatient, updatePatient, deletePatient,

  // --- SESSIONS & EVALUATIONS ---
  viewAllSessions, viewOwnSessions, createSession, updateSession, deleteSession,
  viewAllEvaluations, viewOwnEvaluations, createEvaluation, updateEvaluation, deleteEvaluation,

  // --- FINANCIALS ---
  viewFinancials, viewReports, viewCharts,
  addFinancialEntry, editFinancialEntry, deleteFinancialEntry,

  // --- CALENDAR ---
  viewCalendar, addCalendarEvent, editCalendarEvent, deleteCalendarEvent,

  // --- MEDICAL RECORDS ---
  viewMedicalFiles, addMedicalFile, editMedicalFile, deleteMedicalFile,
  viewMedications, addMedication, editMedication, deleteMedication,

  // --- CLINIC MANAGEMENT ---
  manageStaff, manageUsers, assignRoles, assignPermissions, manageSettings,
  manageTeams, createTeam, archiveTeam,

  // --- DOCTORS & INVITATIONS ---
  viewDoctors, manageDoctors,
  viewInvitations, sendInvitation, revokeInvitation,

  // --- SUBSCRIPTION & SETTINGS ---
  viewSubscription, manageSubscription,
  viewSettings, editSettings,

  // --- TOOLS ---
  useCopilot, viewRecycleBin, restoreRecycleBinItem, permanentDeleteRecycleBinItem,
  viewNotifications, manageNotifications, sendNotificationMessage,

  // --- SUPPORT ---
  viewHelp, accessSupport
}
```
```

### Checking Permissions

```dart
// In Flutter app
class PermissionChecker {
  static bool canCreatePatient(UserModel user) {
    return user.hasPermission(AppPermission.createPatient) ||
           user.hasAnyRole([AppRole.doctor, AppRole.admin]);
  }
  
  static bool canInviteUsers(UserModel user) {
    return user.hasPermission(AppPermission.inviteUsers) ||
           user.isOwner;
  }
  
  static bool canViewFinancials(UserModel user) {
    return user.hasAnyRole([AppRole.financial, AppRole.admin]);
  }
}

// Usage
if (PermissionChecker.canCreatePatient(currentUser)) {
  // Show create patient button
}
```

### Role Assignment

**Owner** (Automatic):
```dart
// When creating clinic
users/{userId}
{
  roles: [AppRole.admin],
  ownerId: userId,  // Same as uid
  clinicIds: [clinicId]
}
```

**Doctor/Staff** (Via Invitation):
```dart
// When accepting invitation
users/{userId}
{
  roles: [AppRole.doctor],  // From invitation
  clinicIds: [clinicId]
}

clinics/{clinicId}/members/{userId}
{
  role: "doctor"  // From invitation
}
```

---

## API Reference

### Base URL

```
Production: https://hg4orotvf0.execute-api.us-east-1.amazonaws.com
```

### Endpoints

#### 1. Create Invitation

**Endpoint**: `POST /invitations/create`

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "recipientEmail": "doctor@example.com",
  "recipientName": "Dr. John Smith",
  "clinicId": "clinic_456",
  "clinicName": "Smith Medical Center",
  "role": "doctor"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "token": "a3b87a5f4ba62ea1a84d97c97ef9a73a79356657d598ac038587a9eb484b71bf",
  "message": "Invitation sent successfully"
}
```

**Error Responses**:
```json
// 400 Bad Request
{
  "error": "Missing required fields: recipientEmail, clinicId"
}

// 500 Internal Server Error
{
  "error": "Failed to send invitation email"
}
```

---

#### 2. Verify Invitation

**Endpoint**: `GET /invitations/verify`

**Query Parameters**:
```
token: string (required)
```

**Example**:
```
GET /invitations/verify?token=a3b87a5f4ba62ea1a84d97c97ef9a73a79356657d598ac038587a9eb484b71bf
```

**Response** (200 OK):
```json
{
  "valid": true,
  "invitation": {
    "recipientEmail": "doctor@example.com",
    "recipientName": "Dr. John Smith",
    "clinicName": "Smith Medical Center",
    "clinicId": "clinic_456",
    "role": "doctor",
    "expiresAt": "2024-01-27T10:00:00Z"
  }
}
```

**Error Responses**:
```json
// Invalid token
{
  "valid": false,
  "error": "Invalid invitation token"
}

// Expired
{
  "valid": false,
  "error": "Invitation has expired"
}

// Already accepted
{
  "valid": false,
  "error": "Invitation already accepted"
}
```

---

#### 3. Accept Invitation

**Endpoint**: `POST /invitations/accept`

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "token": "a3b87a5f4ba62ea1a84d97c97ef9a73a79356657d598ac038587a9eb484b71bf",
  "userId": "abc123xyz"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Invitation accepted successfully"
}
```

**Error Responses**:
```json
// 400 Bad Request
{
  "error": "Invalid invitation token"
}

{
  "error": "Invitation has expired"
}

{
  "error": "Invitation already accepted"
}

// 500 Internal Server Error
{
  "error": "Failed to accept invitation"
}
```

---

#### 4. Get Invitation Page

**Endpoint**: `GET /accept-invitation`

**Query Parameters**:
```
token: string (required)
```

**Example**:
```
GET /accept-invitation?token=a3b87a5f4ba62ea1a84d97c97ef9a73a79356657d598ac038587a9eb484b71bf
```

**Response**: HTML page with:
- Invitation details
- Google Sign-In button
- Firebase Auth integration
- Automatic token verification
- Accept invitation flow

---

## Frontend Implementation

### Flutter Desktop App

#### Login Page

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Sign in with Google'),
          onPressed: () {
            context.read<AuthBloc>().add(SignInWithGoogle());
          },
        ),
      ),
    );
  }
}
```

#### Auth Bloc

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInHelper _googleSignIn;
  
  AuthBloc(this._googleSignIn) : super(AuthInitial()) {
    on<SignInWithGoogle>(_onSignInWithGoogle);
  }
  
  Future<void> _onSignInWithGoogle(
    SignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _googleSignIn.signIn();
      
      if (user != null) {
        // Load user data from Firestore
        final userData = await _loadUserData(user.uid);
        emit(AuthSignedIn(userData));
      } else {
        emit(AuthError('Sign in cancelled'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

#### Create Invitation

```dart
Future<void> createInvitation() async {
  final response = await BackendService.sendInvitation(
    recipientEmail: emailController.text,
    recipientName: nameController.text,
    clinicId: currentClinicId,
    clinicName: currentClinicName,
    role: selectedRole,
  );
  
  if (response['success']) {
    showSuccessDialog('Invitation sent!');
  } else {
    showErrorDialog(response['error']);
  }
}
```

### Web App (Invitation Acceptance)

#### HTML Structure

```html
<div class="container">
  <h1>Dr AI</h1>
  
  <div id="loading">
    <div class="spinner"></div>
    <p>Verifying invitation...</p>
  </div>
  
  <div id="content" style="display: none;">
    <div class="invitation-card">
      <h2>You're Invited!</h2>
      <p>Clinic: <span id="clinic-name"></span></p>
      <p>Role: <span id="role"></span></p>
      <p>Email: <span id="email"></span></p>
    </div>
    
    <button id="google-signin">
      Sign in with Google
    </button>
  </div>
</div>
```

#### JavaScript Logic

```javascript
// Verify invitation on load
async function verifyInvitation() {
  const token = new URLSearchParams(window.location.search).get('token');
  
  const response = await fetch(`${BACKEND_URL}/invitations/verify?token=${token}`);
  const data = await response.json();
  
  if (data.valid) {
    document.getElementById('loading').style.display = 'none';
    document.getElementById('content').style.display = 'block';
    
    document.getElementById('clinic-name').textContent = data.invitation.clinicName;
    document.getElementById('role').textContent = data.invitation.role;
    document.getElementById('email').textContent = data.invitation.recipientEmail;
  } else {
    showError(data.error);
  }
}

// Google Sign-In
document.getElementById('google-signin').addEventListener('click', async () => {
  const provider = new firebase.auth.GoogleAuthProvider();
  const result = await auth.signInWithPopup(provider);
  const user = result.user;
  
  // Accept invitation
  const response = await fetch(`${BACKEND_URL}/invitations/accept`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: token,
      userId: user.uid
    })
  });
  
  if (response.ok) {
    showSuccess('Invitation accepted! You can now open the desktop app.');
  }
});

// Initialize
verifyInvitation();
```

---

## Security Considerations

### Token Security

**Generation**:
```javascript
// Use cryptographically secure random bytes
const token = crypto.randomBytes(32).toString('hex');
// Result: 64-character hexadecimal string
```

**Storage**:
- ✅ Stored in Firestore (server-side)
- ✅ Never exposed in client-side code
- ✅ Only transmitted via HTTPS

**Expiration**:
- ✅ 7-day expiration
- ✅ Checked on every verification
- ✅ Cannot be reused after acceptance

### Email Security

**AWS SES Configuration**:
- ✅ SPF records configured
- ✅ DKIM signing enabled
- ✅ DMARC policy set
- ✅ Sandbox mode for testing
- ✅ Production mode for live emails

**Email Content**:
- ✅ No sensitive data in email body
- ✅ Token only in URL (HTTPS)
- ✅ Clear expiration notice
- ✅ Unsubscribe option

### Authentication Security

**Firebase Auth**:
- ✅ Google OAuth 2.0
- ✅ Automatic token refresh
- ✅ Secure session management
- ✅ Multi-factor authentication support

**API Security**:
- ✅ HTTPS only
- ✅ CORS configured
- ✅ Rate limiting (via API Gateway)
- ✅ Input validation

### Database Security

**Firestore Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Clinic members can read clinic data
    match /clinics/{clinicId} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow write: if get(/databases/$(database)/documents/clinics/$(clinicId)).data.ownerId == request.auth.uid;
    }
    
    // Only backend can write invitations
    match /invitations/{token} {
      allow read: if true;  // Anyone with token can read
      allow write: if false;  // Only backend via Admin SDK
    }
  }
}
```

---

## Troubleshooting

### Common Issues

#### 1. Email Goes to Spam

**Symptoms**:
- Invitation emails not received
- Found in spam folder

**Causes**:
- AWS SES in sandbox mode
- No SPF/DKIM/DMARC records
- Sending from Gmail via AWS SES

**Solutions**:
1. **Immediate**:
   - Mark as "Not Spam"
   - Add sender to contacts
   
2. **Short-term**:
   - Request AWS SES production access
   - Verify recipient email in SES (if in sandbox)
   
3. **Long-term**:
   - Use custom domain
   - Configure DNS records (SPF, DKIM, DMARC)
   - Update `APP_URL` to custom domain

**See**: `EMAIL_DELIVERABILITY.md` for details

---

#### 2. Google Sign-In Fails on Web

**Symptoms**:
- Error: "This domain is not authorized for OAuth operations"

**Cause**:
- Backend domain not added to Firebase authorized domains

**Solution**:
1. Go to Firebase Console
2. Authentication → Settings → Authorized domains
3. Add: `hg4orotvf0.execute-api.us-east-1.amazonaws.com`
4. Save

---

#### 3. Invitation Token Invalid

**Symptoms**:
- "Invalid invitation token" error
- Token not found in database

**Causes**:
- Token expired (> 7 days)
- Token already accepted
- Token never created (email send failed)

**Solutions**:
1. Check invitation status in Firestore
2. Verify token in URL matches database
3. Create new invitation if expired
4. Check backend logs for errors

**Debug**:
```javascript
// Check invitation in Firestore
const invitationDoc = await db.collection('invitations').doc(token).get();
console.log('Invitation:', invitationDoc.data());
```

---

#### 4. User Not Added to Clinic

**Symptoms**:
- Invitation accepted successfully
- User can't access clinic in desktop app

**Causes**:
- Transaction failed during acceptance
- User document not updated
- Clinic member document not created

**Solutions**:
1. Check Firestore:
   - `users/{userId}.clinicIds` contains clinic ID
   - `clinics/{clinicId}/members/{userId}` exists
   
2. Manually add if missing:
```javascript
// Add to clinic members
await db.collection('clinics')
  .doc(clinicId)
  .collection('members')
  .doc(userId)
  .set({
    userId,
    email: userEmail,
    role: 'doctor',
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    addedVia: 'manual'
  });

// Update user
await db.collection('users')
  .doc(userId)
  .update({
    clinicIds: admin.firestore.FieldValue.arrayUnion(clinicId)
  });
```

---

#### 5. Desktop App Shows Wrong Role

**Symptoms**:
- User has wrong permissions
- Can't access expected features

**Causes**:
- Role not synced between user and clinic member
- Multiple clinics with different roles
- Cache not cleared

**Solutions**:
1. Check both locations:
```dart
// User roles
final userDoc = await firestore.collection('users').doc(userId).get();
print('User roles: ${userDoc.data()['roles']}');

// Clinic member role
final memberDoc = await firestore
  .collection('clinics/$clinicId/members')
  .doc(userId)
  .get();
print('Member role: ${memberDoc.data()['role']}');
```

2. Sync roles if mismatched
3. Clear app cache and re-login

---

### Debug Mode

Enable detailed logging:

**Backend**:
```javascript
// In routes/invitations.js
console.log('--- Debug Info ---');
console.log('Token:', token);
console.log('User ID:', userId);
console.log('Invitation data:', invitationData);
```

**Flutter**:
```dart
// In auth_bloc.dart
print('--- Auth Debug ---');
print('User UID: ${user.uid}');
print('User email: ${user.email}');
print('Clinic IDs: ${userData.clinicIds}');
print('Roles: ${userData.roles}');
```

---

## Appendix

### Environment Variables

**Backend** (Doppler):
```bash
FIREBASE_SERVICE_ACCOUNT='{...}'  # Firebase Admin SDK credentials
SES_FROM_EMAIL='nourrehabcenter@gmail.com'  # Sender email
APP_URL='https://hg4orotvf0.execute-api.us-east-1.amazonaws.com'  # Backend URL
```

**Flutter** (Compile-time):
```bash
WEB_CLIENT_ID='253522261255-cb415bhb6n4ni58mqslcqhq7547gqmbb.apps.googleusercontent.com'
WEB_CLIENT_SECRET='...'
WEB_REDIRECT_PORT='...'
```

### Useful Commands

**Deploy Backend**:
```bash
cd backend
doppler run -- npx serverless deploy
```

**Build Flutter Web**:
```bash
flutter build web --release \
  --dart-define=WEB_CLIENT_ID=253522261255-cb415bhb6n4ni58mqslcqhq7547gqmbb.apps.googleusercontent.com
```

**Deploy to Firebase Hosting**:
```bash
firebase deploy --only hosting
```

**Check Firestore Data**:
```bash
# Using Firebase CLI
firebase firestore:get users/USER_ID
firebase firestore:get clinics/CLINIC_ID/members/USER_ID
```

---

## Support

For issues or questions:
1. Check this documentation
2. Review `EMAIL_DELIVERABILITY.md`
3. Check `database_schema.md`
4. Review backend logs in AWS CloudWatch
5. Check Firebase Console for auth errors

---

**Last Updated**: 2024-01-21  
**Version**: 1.0.0  
**Author**: Dr AI Development Team
