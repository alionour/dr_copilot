# Firebase Cloud Functions for Push Notifications

## Overview
This guide shows how to set up Cloud Functions to automatically send push notifications when a notification is created in Firestore.

## Prerequisites
- Node.js installed (v18 or later)
- Firebase CLI installed: `npm install -g firebase-tools`
- Firebase project with Blaze plan (pay-as-you-go)

## Setup Steps

### 1. Initialize Firebase Functions

```bash
# In your project root
firebase login
firebase init functions

# Choose:
# - TypeScript or JavaScript (TypeScript recommended)
# - ESLint: Yes
# - Install dependencies: Yes
```

### 2. Create Cloud Function

**File:** `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

/**
 * Sends a push notification when a new notification document is created
 */
export const sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const notification = snap.data();
      const notificationId = context.params.notificationId;

      console.log(`Processing notification: ${notificationId}`);

      // Get user's FCM token
      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(notification.userId)
        .get();

      if (!userDoc.exists) {
        console.log(`User not found: ${notification.userId}`);
        return null;
      }

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user: ${notification.userId}`);
        return null;
      }

      // Prepare notification payload
      const payload: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: notification.title || 'New Notification',
          body: notification.message || '',
        },
        data: {
          notificationId: notificationId,
          type: notification.type || 'system',
          actionUrl: notification.actionUrl || '/notifications',
          userId: notification.userId,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(payload);
      console.log(`Successfully sent notification: ${response}`);

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Callable function to manually test sending notifications
 */
export const sendTestNotification = functions.https.onCall(
  async (data, context) => {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const title = data.title || 'Test Notification';
    const message = data.message || 'This is a test notification';
    const type = data.type || 'system';

    try {
      // Create notification in Firestore
      const notificationRef = await admin
        .firestore()
        .collection('notifications')
        .add({
          userId: userId,
          title: title,
          message: message,
          type: type,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          actionUrl: data.actionUrl || '/notifications',
          metadata: data.metadata || {},
        });

      return {
        success: true,
        notificationId: notificationRef.id,
        message: 'Test notification created and sent successfully',
      };
    } catch (error) {
      console.error('Error creating test notification:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Error creating notification'
      );
    }
  }
);

/**
 * Updates unread count for a user
 */
export const updateUnreadCount = functions.firestore
  .document('notifications/{notificationId}')
  .onWrite(async (change, context) => {
    try {
      const userId = change.after.exists
        ? change.after.data()?.userId
        : change.before.data()?.userId;

      if (!userId) return null;

      // Count unread notifications
      const unreadSnapshot = await admin
        .firestore()
        .collection('notifications')
        .where('userId', '==', userId)
        .where('isRead', '==', false)
        .get();

      const unreadCount = unreadSnapshot.size;

      // Update user's unread count
      await admin
        .firestore()
        .collection('users')
        .doc(userId)
        .set(
          {
            unreadNotificationsCount: unreadCount,
          },
          { merge: true }
        );

      console.log(`Updated unread count for ${userId}: ${unreadCount}`);
      return unreadCount;
    } catch (error) {
      console.error('Error updating unread count:', error);
      return null;
    }
  });

/**
 * Clean up old notifications (older than 30 days)
 */
export const cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const oldNotifications = await admin
        .firestore()
        .collection('notifications')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .where('isRead', '==', true)
        .get();

      console.log(`Found ${oldNotifications.size} old notifications to delete`);

      const batch = admin.firestore().batch();
      oldNotifications.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${oldNotifications.size} old notifications`);

      return oldNotifications.size;
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
      return null;
    }
  });
```

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendNotificationOnCreate
```

### 4. Test the Function

#### Option 1: Create Notification in Firestore Console
1. Go to Firestore
2. Add a document to `notifications` collection
3. Check Cloud Functions logs: `firebase functions:log`

#### Option 2: Use Callable Function from Flutter

```dart
import 'package:cloud_functions/cloud_functions.dart';

// Send test notification
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('sendTestNotification').call({
  'title': 'Test Push Notification',
  'message': 'This is a test from Flutter',
  'type': 'system',
});

print(result.data);
```

### 5. Monitor Functions

```bash
# View logs
firebase functions:log

# View logs with filtering
firebase functions:log --only sendNotificationOnCreate
```

## Firestore Security Rules

Update your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Notifications
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      
      // Anyone authenticated can create (for testing)
      // In production, restrict this to admin/cloud functions
      allow create: if request.auth != null;
      
      // Users can update/delete their own notifications
      allow update, delete: if request.auth != null && 
                               resource.data.userId == request.auth.uid;
    }
    
    // Users collection (for FCM tokens)
    match /users/{userId} {
      // Users can only read/write their own data
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
```

## Environment Configuration

### Set up Firebase Admin SDK

```bash
# Generate service account key
# Go to: Firebase Console → Project Settings → Service Accounts
# Click "Generate New Private Key"
# Save as: functions/service-account-key.json

# Add to .gitignore
echo "functions/service-account-key.json" >> .gitignore
```

### Configure Environment Variables

```bash
firebase functions:config:set notification.channel_id="high_importance_channel"
firebase functions:config:set notification.default_sound="default"
```

## Testing Checklist

- [ ] Function deploys successfully
- [ ] Creating notification in Firestore triggers function
- [ ] Push notification appears on device
- [ ] Notification data is correct
- [ ] Tapping notification opens app
- [ ] Notification is marked as read when tapped
- [ ] Unread count updates correctly
- [ ] Old notifications are cleaned up

## Troubleshooting

### Function Not Triggering

```bash
# Check function exists
firebase functions:list

# Check logs for errors
firebase functions:log --only sendNotificationOnCreate
```

### No FCM Token

```dart
// In Flutter, check if token is saved
final userId = FirebaseAuth.instance.currentUser?.uid;
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
print('FCM Token: ${userDoc.data()?['fcmToken']}');
```

### Permission Errors

```bash
# Check Firebase project permissions
firebase projects:list

# Re-authenticate if needed
firebase login --reauth
```

## Cost Estimation

Firebase Cloud Functions pricing (Blaze plan):

- **Invocations:** $0.40 per million invocations
- **Compute time:** 
  - $0.0000025/GB-second
  - $0.0000100/GHz-second
- **Free tier:** 2 million invocations/month

**Estimated costs for notifications:**
- 1,000 notifications/day = ~$0.01/month
- 10,000 notifications/day = ~$0.12/month
- 100,000 notifications/day = ~$1.20/month

## Alternative: Send from Flutter

If you don't want to use Cloud Functions, you can send directly from Flutter:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendNotificationToUser(
  String recipientUserId,
  String title,
  String message,
) async {
  // Get recipient's FCM token
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(recipientUserId)
      .get();
  
  final fcmToken = userDoc.data()?['fcmToken'];
  
  if (fcmToken != null) {
    // Create notification in Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': recipientUserId,
      'title': title,
      'message': message,
      'type': 'system',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Note: You'll need a backend service to actually send the FCM message
    // as Flutter cannot send FCM messages directly (requires admin SDK)
  }
}
```

## Next Steps

1. **Deploy the Cloud Function**
2. **Test with Firebase Console**
3. **Test from Flutter app**
4. **Monitor logs and performance**
5. **Set up alerts for errors**

## Resources

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [FCM Admin SDK](https://firebase.google.com/docs/cloud-messaging/admin)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
