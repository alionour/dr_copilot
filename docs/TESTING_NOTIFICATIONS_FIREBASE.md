# Testing Notifications with Firebase

## Quick Testing Guide

### Method 1: Firebase Console (Easiest)

#### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **dr_copilot**
3. Click on **Firestore Database** in the left menu

#### Step 2: Create Test Notification
1. Click **"Start collection"** (if first time) or navigate to existing collections
2. Collection ID: `notifications`
3. Click **"Add document"**

**Document Fields:**
```
Field Name          | Type      | Value
--------------------|-----------|---------------------------
userId              | string    | [Your user ID]
title               | string    | Test Notification
message             | string    | This is a test message
type                | string    | system
isRead              | boolean   | false
createdAt           | timestamp | [Current timestamp]
actionUrl           | string    | /home (optional)
metadata            | map       | {} (optional)
```

4. Click **"Save"**

#### Step 3: View in App
1. Open your app
2. Navigate to Notifications page
3. The notification should appear immediately (real-time)

---

### Method 2: Using Flutter Code (Programmatic)

Create a test button in your app to generate notifications.

#### Create Test Helper Class

**File:** `lib/src/features/notifications/test_notification_helper.dart`

```dart
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';
import 'package:get_it/get_it.dart';

class TestNotificationHelper {
  static final _repo = GetIt.instance<AbstractNotificationsRepository>();

  /// Create a test notification
  static Future<void> createTestNotification(String userId) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: 'Test Notification',
      message: 'This is a test notification created at ${DateTime.now()}',
      type: NotificationType.system,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Create multiple test notifications
  static Future<void> createMultipleTestNotifications(String userId, int count) async {
    for (int i = 0; i < count; i++) {
      await createTestNotification(userId);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Create notifications of all types
  static Future<void> createAllTypesNotifications(String userId) async {
    final types = [
      NotificationType.appointment,
      NotificationType.message,
      NotificationType.reminder,
      NotificationType.system,
      NotificationType.payment,
      NotificationType.report,
      NotificationType.alert,
    ];

    for (var type in types) {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: '${type.name.toUpperCase()} Notification',
        message: 'This is a test ${type.name} notification',
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        actionUrl: _getActionUrlForType(type),
      );

      await _repo.createNotification(notification);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  static String _getActionUrlForType(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return '/sessions';
      case NotificationType.message:
        return '/chat';
      case NotificationType.payment:
        return '/financials';
      case NotificationType.report:
        return '/clinical_reports';
      default:
        return '/home';
    }
  }
}
```

#### Add Test Button to App

**Option A: Add to Notifications Page**

Add this to `notifications_page.dart` in the actions:

```dart
// In AppBar actions, add:
if (kDebugMode) // Only show in debug mode
  IconButton(
    icon: const Icon(Icons.bug_report),
    tooltip: 'Create Test Notifications',
    onPressed: () async {
      if (_userId != null) {
        await TestNotificationHelper.createAllTypesNotifications(_userId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notifications created!')),
        );
      }
    },
  ),
```

**Option B: Add to Settings Page**

Add a debug menu option:

```dart
// In settings_page.dart
if (kDebugMode)
  ListTile(
    leading: const Icon(Icons.bug_report),
    title: const Text('Test Notifications'),
    subtitle: const Text('Create test notifications'),
    onTap: () async {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSignedIn && authState.userId != null) {
        await TestNotificationHelper.createAllTypesNotifications(authState.userId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notifications created!')),
        );
      }
    },
  ),
```

---

### Method 3: Using Firebase Cloud Functions

Create a Cloud Function to generate test notifications.

#### Create Cloud Function

**File:** `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const createTestNotification = functions.https.onCall(
  async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const type = data.type || 'system';
    const title = data.title || 'Test Notification';
    const message = data.message || 'This is a test notification';

    try {
      const notification = {
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        actionUrl: data.actionUrl || null,
        metadata: data.metadata || {},
      };

      const docRef = await admin
        .firestore()
        .collection('notifications')
        .add(notification);

      return {
        success: true,
        notificationId: docRef.id,
        message: 'Test notification created successfully',
      };
    } catch (error) {
      throw new functions.https.HttpsError(
        'internal',
        'Error creating notification',
        error
      );
    }
  }
);
```

#### Call from Flutter

```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('createTestNotification').call({
  'type': 'appointment',
  'title': 'Test Appointment',
  'message': 'You have a test appointment',
});
```

---

### Method 4: Using Postman/REST API

If you have Firebase REST API enabled:

#### Endpoint
```
POST https://firestore.googleapis.com/v1/projects/YOUR_PROJECT_ID/databases/(default)/documents/notifications
```

#### Headers
```
Content-Type: application/json
Authorization: Bearer YOUR_FIREBASE_TOKEN
```

#### Body
```json
{
  "fields": {
    "userId": {
      "stringValue": "your_user_id"
    },
    "title": {
      "stringValue": "Test Notification"
    },
    "message": {
      "stringValue": "This is a test message"
    },
    "type": {
      "stringValue": "system"
    },
    "isRead": {
      "booleanValue": false
    },
    "createdAt": {
      "timestampValue": "2024-01-15T10:00:00Z"
    }
  }
}
```

---

## Complete Testing Checklist

### 1. Basic Functionality
- [ ] Create notification in Firebase Console
- [ ] Notification appears in app immediately
- [ ] Notification displays correct icon/color based on type
- [ ] Notification shows correct time (e.g., "2 minutes ago")
- [ ] Unread count updates in header

### 2. Mark as Read
- [ ] Tap notification - marks as read automatically
- [ ] Use menu option "Mark as Read" - marks single notification
- [ ] Use header button "Mark All as Read" - marks all notifications
- [ ] Visual style changes when marked as read
- [ ] Unread count decreases

### 3. Delete Operations
- [ ] Delete single notification via menu
- [ ] Delete all notifications via header menu
- [ ] Confirmation dialogs appear
- [ ] Notifications are removed from UI
- [ ] Notifications are deleted from Firebase

### 4. Real-time Updates
- [ ] Create notification in Firebase Console while app is open
- [ ] Notification appears without refresh
- [ ] Mark as read in another device/browser
- [ ] Status updates in app
- [ ] Delete in Firebase Console
- [ ] Notification disappears from app

### 5. Navigation
- [ ] Tap notification with actionUrl
- [ ] App navigates to correct page
- [ ] Notification is marked as read after tap

### 6. Empty States
- [ ] Delete all notifications
- [ ] Empty state UI appears
- [ ] Message and icon display correctly

### 7. Error Handling
- [ ] Turn off internet
- [ ] Try to load notifications
- [ ] Error state appears
- [ ] Retry button works
- [ ] Reconnect and notifications load

### 8. Pull to Refresh
- [ ] Pull down on notification list
- [ ] Loading indicator appears
- [ ] Notifications refresh

### 9. Different Types
Test all 7 notification types:
- [ ] Appointment (Blue, Calendar icon)
- [ ] Message (Green, Chat icon)
- [ ] Reminder (Orange, Alarm icon)
- [ ] System (Grey, Info icon)
- [ ] Payment (Purple, Payment icon)
- [ ] Report (Teal, Document icon)
- [ ] Alert (Red, Warning icon)

### 10. Localization
- [ ] Test in English - all text displays correctly
- [ ] Switch to Arabic - all text displays correctly
- [ ] Time formatting works in both languages

---

## Getting Your User ID

### Method 1: From Firebase Console
1. Go to **Authentication** tab
2. Find your user
3. Copy the **User UID**

### Method 2: From Code
Add this temporarily to any page:

```dart
import 'package:firebase_auth/firebase_auth.dart';

// In your widget
final userId = FirebaseAuth.instance.currentUser?.uid;
print('User ID: $userId');
```

### Method 3: From App UI
Add to NavigationSide footer:

```dart
// Show userId in debug mode
if (kDebugMode)
  Text('User: ${state.userId}'),
```

---

## Sample Test Notifications

### 1. Appointment Notification
```json
{
  "userId": "YOUR_USER_ID",
  "title": "Upcoming Appointment",
  "message": "You have an appointment with Dr. Smith tomorrow at 10:00 AM",
  "type": "appointment",
  "isRead": false,
  "createdAt": [Current Timestamp],
  "actionUrl": "/sessions",
  "metadata": {
    "doctorName": "Dr. Smith",
    "appointmentDate": "2024-01-16T10:00:00Z"
  }
}
```

### 2. Payment Notification
```json
{
  "userId": "YOUR_USER_ID",
  "title": "Payment Received",
  "message": "Payment of $150 has been received for Invoice #1234",
  "type": "payment",
  "isRead": false,
  "createdAt": [Current Timestamp],
  "actionUrl": "/financials",
  "metadata": {
    "amount": 150,
    "invoiceId": "1234"
  }
}
```

### 3. Alert Notification
```json
{
  "userId": "YOUR_USER_ID",
  "title": "Urgent: Lab Results",
  "message": "New lab results available for review",
  "type": "alert",
  "isRead": false,
  "createdAt": [Current Timestamp],
  "actionUrl": "/clinical_reports"
}
```

---

## Troubleshooting

### Notifications Not Appearing?

1. **Check User ID:**
   ```dart
   print('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
   ```
   Make sure the `userId` in notification matches

2. **Check Firebase Rules:**
   ```javascript
   // firestore.rules
   match /notifications/{notificationId} {
     allow read: if request.auth != null && 
                    resource.data.userId == request.auth.uid;
     allow create: if request.auth != null;
     allow update: if request.auth != null && 
                      resource.data.userId == request.auth.uid;
     allow delete: if request.auth != null && 
                      resource.data.userId == request.auth.uid;
   }
   ```

3. **Check Console for Errors:**
   ```dart
   flutter run --debug
   ```
   Look for Firebase or stream errors

4. **Check Internet Connection:**
   - Firebase requires internet for real-time updates
   - Check if app is online

5. **Check Firestore Indexes:**
   - Go to Firebase Console → Firestore → Indexes
   - Create indexes:
     - `userId` (Ascending) + `createdAt` (Descending)
     - `userId` (Ascending) + `isRead` (Ascending)

### Real-time Updates Not Working?

1. **Check Listener:**
   ```dart
   // Should see this in logs
   [NotificationsBloc] Watching notifications for user: xyz
   ```

2. **Check Stream:**
   ```dart
   // In Firebase API
   .snapshots() // Make sure this is being used
   ```

3. **Restart App:**
   - Sometimes stream needs to be re-established

---

## Production Testing Tips

### Before Going Live:

1. **Test with Multiple Users:**
   - Create 2-3 test accounts
   - Send notifications to each
   - Verify isolation (users only see their notifications)

2. **Test Performance:**
   - Create 100+ notifications
   - Check scrolling performance
   - Check load time

3. **Test Offline Behavior:**
   - Turn off internet
   - Try operations
   - Turn on internet
   - Verify sync

4. **Test Notification Limits:**
   - What happens with 1000+ notifications?
   - Consider pagination

5. **Test Edge Cases:**
   - Very long titles/messages
   - Missing fields
   - Invalid types
   - Future dates
   - Very old dates

---

## Automated Testing Script

Create a quick test script:

```dart
// lib/test_notifications_script.dart
import 'package:dr_copilot/src/features/notifications/test_notification_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> runNotificationTests() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    print('❌ No user logged in');
    return;
  }

  print('🧪 Starting notification tests...');
  print('User ID: $userId');

  // Test 1: Create single notification
  print('\n📝 Test 1: Creating single notification...');
  await TestNotificationHelper.createTestNotification(userId);
  print('✅ Single notification created');

  await Future.delayed(const Duration(seconds: 2));

  // Test 2: Create multiple notifications
  print('\n📝 Test 2: Creating 5 notifications...');
  await TestNotificationHelper.createMultipleTestNotifications(userId, 5);
  print('✅ 5 notifications created');

  await Future.delayed(const Duration(seconds: 2));

  // Test 3: Create all types
  print('\n📝 Test 3: Creating all notification types...');
  await TestNotificationHelper.createAllTypesNotifications(userId);
  print('✅ All types created');

  print('\n✅ All tests completed!');
  print('Check the Notifications page to see results.');
}
```

Run it from a button or on app start (debug mode only).

---

## Summary

**Recommended Testing Approach:**

1. **Start Simple:** Use Firebase Console to create 1-2 notifications
2. **Test Features:** Mark as read, delete, refresh
3. **Add Test Button:** Use the Flutter helper class
4. **Test All Types:** Create notifications for all 7 types
5. **Test Real-time:** Keep app open while creating in console
6. **Test Edge Cases:** Long text, offline, etc.

The easiest way is **Method 1 (Firebase Console)** - no code needed!
