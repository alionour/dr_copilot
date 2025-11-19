# Dr. Copilot Notification System - Comprehensive Plan

## Overview
Two-tier notification system supporting:
1. **System-level notifications**: From programmer/app to users
2. **Clinic-level notifications**: From clinic owners to their staff

## User Roles (from role_enum.dart)
- `admin` - Clinic owner/administrator
- `doctor` - Medical doctors
- `staff` - Non-medical staff
- `financial` - Financial staff
- `readonly` - Read-only access

## Notification Architecture

### 1. Data Model

#### Notification Document Structure
```dart
class NotificationModel {
  String id;                    // Unique notification ID
  NotificationType type;        // system or clinic
  String title;                 // Notification title
  String message;               // Notification message
  DateTime createdAt;           // Creation timestamp
  DateTime? scheduledFor;       // Optional: for scheduled notifications
  String senderId;              // UID of sender (programmer or admin)
  String senderName;            // Display name of sender
  
  // Targeting fields
  TargetAudience targetAudience; // Who receives this
  List<String>? specificUserIds; // Specific users (optional)
  List<AppRole>? targetRoles;    // Target by roles
  List<String>? targetClinicIds; // Target specific clinics
  String? ownerClinicId;         // For clinic-level notifications
  
  // Status & metadata
  NotificationStatus status;     // draft, sent, scheduled
  NotificationPriority priority; // low, normal, high, urgent
  bool isRead;                   // For individual user receipts
  Map<String, dynamic>? actionData; // Optional action data (deeplink, etc.)
  String? imageUrl;              // Optional image
  String? actionUrl;             // Optional action URL
}
```

#### Enums
```dart
enum NotificationType {
  system,    // From programmer/app to users
  clinic     // From clinic admin to their staff
}

enum TargetAudience {
  allUsers,           // Everyone
  allAdmins,          // All clinic owners
  allDoctors,         // All doctors
  allStaff,           // All staff
  allFinancial,       // All financial staff
  specificRoles,      // Users with specific roles
  specificUsers,      // Specific user IDs
  specificClinics,    // Users in specific clinics
  myClinicUsers,      // All users in sender's clinics
  myClinicDoctors,    // Doctors in sender's clinics
  myClinicStaff,      // Staff in sender's clinics
}

enum NotificationStatus {
  draft,
  scheduled,
  sent,
  failed
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent
}
```

### 2. Firestore Collections Structure

```
/notifications (collection)
  /{notificationId} (document)
    - id
    - type
    - title
    - message
    - createdAt
    - scheduledFor
    - senderId
    - senderName
    - targetAudience
    - specificUserIds
    - targetRoles
    - targetClinicIds
    - ownerClinicId
    - status
    - priority
    - imageUrl
    - actionUrl
    - actionData

/user_notifications (collection)
  /{userId} (document)
    /notifications (subcollection)
      /{notificationId} (document)
        - notificationRef (reference to /notifications/{notificationId})
        - isRead
        - readAt
        - receivedAt
        - deleted
```

### 3. Access Control & Security Rules

#### System Notifications (type: system)
- **Who can send**: Only users with special permission (e.g., `isDeveloper: true` flag)
- **Who receives**: Based on targetAudience and targeting fields
- **Access**: All targeted users can read

#### Clinic Notifications (type: clinic)
- **Who can send**: 
  - Users with `admin` role
  - Only to users in clinics they own (where user.ownerId == sender.uid or user.clinicIds includes sender's clinics)
- **Who receives**: Based on targetAudience within sender's clinics
- **Access**: Users can only read their own notifications

#### Firestore Security Rules
```javascript
match /notifications/{notificationId} {
  // System notifications: only developers can create
  allow create: if request.auth != null 
    && request.resource.data.type == 'system'
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isDeveloper == true;
  
  // Clinic notifications: admins can create for their clinics
  allow create: if request.auth != null
    && request.resource.data.type == 'clinic'
    && 'admin' in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles
    && request.resource.data.senderId == request.auth.uid;
  
  // Read: anyone can read notifications (filtering done in app)
  allow read: if request.auth != null;
  
  // Update/Delete: only sender can modify
  allow update, delete: if request.auth != null 
    && resource.data.senderId == request.auth.uid;
}

match /user_notifications/{userId}/notifications/{notificationId} {
  // Users can only read their own notifications
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // System can write (via backend/cloud function)
  allow write: if request.auth != null;
  
  // Users can update read status of their notifications
  allow update: if request.auth != null 
    && request.auth.uid == userId
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead', 'readAt', 'deleted']);
}
```

### 4. User Flow & Permissions

#### Developer/Programmer Flow (System Notifications)
1. Access debug notification page (only visible if `user.isDeveloper == true`)
2. Create notification with:
   - Title & message
   - Target audience selection (all admins, all doctors, specific roles, etc.)
   - Priority level
   - Optional: schedule for later
   - Optional: image, action URL
3. Save as draft or send immediately
4. AWS Lambda processes and creates user_notifications entries

#### Clinic Owner Flow (Clinic Notifications)
1. Access notifications management in admin panel
2. Create notification with:
   - Title & message
   - Target selection:
     - All my clinics OR specific clinic(s) I own
     - All users OR specific roles (doctors, staff, financial)
     - Specific users (dropdown filtered by my clinics)
   - Priority level
3. Send immediately or schedule
4. AWS Lambda processes for users in selected clinics

#### User Flow (Receiving Notifications)
1. User opens notifications tab
2. BLoC watches `/user_notifications/{userId}/notifications`
3. Displays list with:
   - Unread badge/indicator
   - Title, message, time
   - Priority indicator (color/icon)
   - Action button if applicable
4. Tap to mark as read
5. Optional: tap action to navigate (deeplink)

### 5. Implementation Components

#### 5.1 Domain Layer
```
lib/src/features/notifications/
├── domain/
│   ├── models/
│   │   ├── notification_model.dart
│   │   ├── notification_enums.dart
│   │   └── user_notification_receipt.dart
│   └── repositories/
│       └── notifications_repository.dart
```

#### 5.2 Data Layer
```
lib/src/features/notifications/
├── data/
│   ├── datasources/
│   │   ├── notifications_remote_datasource.dart
│   │   └── user_notifications_datasource.dart
│   └── repositories/
│       └── notifications_repository_impl.dart
```

#### 5.3 Presentation Layer
```
lib/src/features/notifications/
├── presentation/
│   ├── bloc/
│   │   ├── notifications_bloc.dart
│   │   ├── notifications_event.dart
│   │   ├── notifications_state.dart
│   │   ├── create_notification_bloc.dart  // NEW
│   │   ├── create_notification_event.dart
│   │   └── create_notification_state.dart
│   ├── pages/
│   │   ├── notifications_list_page.dart
│   │   ├── notification_detail_page.dart
│   │   ├── create_notification_page.dart  // NEW (dev only)
│   │   └── admin_notifications_page.dart  // NEW (clinic admin)
│   └── widgets/
│       ├── notification_card.dart
│       ├── target_audience_selector.dart  // NEW
│       ├── clinic_selector.dart           // NEW
│       └── user_selector.dart             // NEW
```

#### 5.4 Backend (AWS Lambda)
```
notification-backend/
├── src/
│   ├── handlers/
│   │   ├── processNotification.js
│   │   └── scheduleNotification.js
│   ├── services/
│   │   ├── targetingService.js
│   │   └── firebaseService.js
│   └── utils/
│       └── userQuerying.js
```

### 6. Backend Processing Logic

#### AWS Lambda Function: processNotification
```javascript
exports.handler = async (event) => {
  const notification = event.notification;
  
  // 1. Validate sender permissions
  if (notification.type === 'system') {
    // Check isDeveloper flag
  } else if (notification.type === 'clinic') {
    // Check admin role and clinic ownership
  }
  
  // 2. Resolve target users
  const targetUserIds = await resolveTargetUsers(notification);
  
  // 3. Create user_notifications entries
  await createUserNotifications(targetUserIds, notification);
  
  // 4. Send push notifications (optional, future)
  // await sendPushNotifications(targetUserIds, notification);
  
  return { success: true, recipientCount: targetUserIds.length };
};

async function resolveTargetUsers(notification) {
  const { targetAudience, targetRoles, targetClinicIds, 
          specificUserIds, ownerClinicId, senderId } = notification;
  
  let query = firestore.collection('users');
  
  switch (targetAudience) {
    case 'allUsers':
      // All users
      break;
    case 'allAdmins':
      query = query.where('roles', 'array-contains', 'admin');
      break;
    case 'allDoctors':
      query = query.where('roles', 'array-contains', 'doctor');
      break;
    case 'allStaff':
      query = query.where('roles', 'array-contains', 'staff');
      break;
    case 'allFinancial':
      query = query.where('roles', 'array-contains', 'financial');
      break;
    case 'specificRoles':
      // Multiple role filtering (need to handle in app or use array-contains-any)
      query = query.where('roles', 'array-contains-any', targetRoles);
      break;
    case 'specificUsers':
      return specificUserIds;
    case 'specificClinics':
      query = query.where('clinicIds', 'array-contains-any', targetClinicIds);
      break;
    case 'myClinicUsers':
      // Get all users where clinicIds contains any clinic owned by sender
      const senderClinics = await getSenderClinics(senderId);
      query = query.where('clinicIds', 'array-contains-any', senderClinics);
      break;
    case 'myClinicDoctors':
      const senderClinics2 = await getSenderClinics(senderId);
      query = query
        .where('clinicIds', 'array-contains-any', senderClinics2)
        .where('roles', 'array-contains', 'doctor');
      break;
    case 'myClinicStaff':
      const senderClinics3 = await getSenderClinics(senderId);
      query = query
        .where('clinicIds', 'array-contains-any', senderClinics3)
        .where('roles', 'array-contains', 'staff');
      break;
  }
  
  const snapshot = await query.get();
  return snapshot.docs.map(doc => doc.id);
}
```

### 7. Implementation Phases

#### Phase 1: Core Infrastructure (Week 1)
- [ ] Create notification domain models and enums
- [ ] Implement NotificationsRepository interface
- [ ] Create Firestore data sources
- [ ] Set up Firestore security rules
- [ ] Create basic notifications list page (read-only)

#### Phase 2: User Notifications (Week 1-2)
- [ ] Implement user_notifications watching in BLoC
- [ ] Create notification card widget
- [ ] Implement mark as read functionality
- [ ] Add unread count badge
- [ ] Handle notification detail view

#### Phase 3: Developer Notification Creation (Week 2)
- [ ] Add `isDeveloper` flag to UserModel
- [ ] Create debug notification creation page
- [ ] Implement target audience selector widget
- [ ] Create CreateNotificationBloc
- [ ] Add validation and preview

#### Phase 4: AWS Lambda Backend (Week 2-3)
- [ ] Set up AWS Lambda function
- [ ] Implement targeting/resolution logic
- [ ] Create user_notifications batch writer
- [ ] Add error handling and retry logic
- [ ] Set up CloudWatch logging

#### Phase 5: Clinic Admin Notifications (Week 3)
- [ ] Create admin notifications page
- [ ] Implement clinic selector (for multi-clinic admins)
- [ ] Add user selector (filtered by clinics)
- [ ] Integrate with backend Lambda
- [ ] Add permissions check

#### Phase 6: Advanced Features (Week 4)
- [ ] Scheduled notifications
- [ ] Notification images
- [ ] Action URLs and deep linking
- [ ] Priority indicators
- [ ] Search and filter notifications
- [ ] Delete notifications

#### Phase 7: Testing & Polish (Week 4-5)
- [ ] Unit tests for models and repositories
- [ ] Integration tests for notification flow
- [ ] Test multi-clinic scenarios
- [ ] Test all target audience options
- [ ] Performance testing with large user base
- [ ] UI/UX polish

### 8. Database Indexes (Firestore)

```javascript
// Collection: notifications
- Composite index: type + status + createdAt (DESC)
- Composite index: senderId + createdAt (DESC)
- Composite index: type + senderId + status

// Collection: user_notifications/{userId}/notifications
- Single field: receivedAt (DESC)
- Single field: isRead
- Composite index: isRead + receivedAt (DESC)
```

### 9. Best Practices & Considerations

#### Performance
- Use pagination for notification lists (20-50 per page)
- Index user_notifications by receivedAt desc
- Cache unread count in user document
- Limit notification history (e.g., 90 days)

#### Security
- Never expose developer flag to clients
- Validate clinic ownership server-side
- Rate limit notification creation
- Sanitize user input in messages

#### User Experience
- Show most recent notifications first
- Group by date (Today, Yesterday, This Week, etc.)
- Clear visual indication of unread
- Pull-to-refresh support
- Empty state for no notifications

#### Scalability
- Batch write user_notifications (500 at a time)
- Use AWS SQS for large broadcasts
- Implement pagination in Lambda
- Monitor Lambda execution times

#### Future Enhancements
- Push notifications (FCM)
- Email notifications
- In-app notification center
- Notification preferences/settings
- Rich media (images, videos)
- Interactive notifications (approve/reject actions)
- Notification templates
- Analytics dashboard

### 10. Testing Strategy

#### Developer Testing
1. Create system notification targeting all admins
2. Verify only clinic owners receive it
3. Create notification for specific roles
4. Test scheduled notifications

#### Clinic Admin Testing
1. Multi-clinic owner sends to all clinics
2. Single-clinic owner sends to their clinic
3. Target specific users in owned clinics
4. Attempt to send to unowned clinic (should fail)

#### Edge Cases
- User with no roles
- User in multiple clinics
- User removed from clinic after notification sent
- Notification sent to deleted user
- Empty target audience

### 11. Monitoring & Logging

#### Metrics to Track
- Notifications created per day
- Average recipients per notification
- Notification read rate
- Lambda execution time
- Failed deliveries
- User engagement with actions

#### Logging
- Lambda: Log all targeting resolutions
- App: Log notification opens
- Backend: Log permission failures
- Analytics: Track notification effectiveness

## Conclusion

This comprehensive plan provides a scalable, secure, and flexible notification system that supports both system-wide announcements and clinic-specific communications. The two-tier approach ensures proper access control while maintaining ease of use for both developers and clinic administrators.

## Implementation Status (Updated)

✅ **Completed:**
- ✅ Notification data models with sender and target support
- ✅ NotificationTemplate for bulk operations
- ✅ Bulk notification sending capability with batch processing
- ✅ User targeting by roles, clinics, and ownership
- ✅ Debug UI (CreateNotificationPage) for creating and sending notifications
- ✅ SendBulkNotificationUseCase implementation
- ✅ Updated NotificationsBloc with bulk notification support
- ✅ Dependency injection setup
- ✅ JSON serialization code generation

⏳ **Next Steps:**
1. Add debug page to navigation (developer menu or settings)
2. Update Firestore security rules
3. Create Firestore indexes for user queries
4. Test notification targeting and delivery
5. Add push notification integration (FCM - optional)
6. Add error tracking and retry mechanism
