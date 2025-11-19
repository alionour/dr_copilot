# Enhanced Notification Sender - Implementation Plan

## Overview
This plan outlines the enhancement of the existing Debug Notification Sender page to support advanced targeting capabilities including roles, clinics, specific users, and bulk operations with best practices.

## Current State Analysis

### Existing Implementation ✅
- **Location**: `lib/src/features/notifications/presentation/pages/debug_notification_sender_page.dart`
- **Current Features**:
  - Send to single user by userId
  - Send to all users
  - Quick templates
  - Notification type selection
  - Recent user IDs dropdown
  - Debug mode only access

### Available User Attributes (from UserModel)
- `uid` - Unique user identifier
- `roles` - List of AppRole (admin, doctor, staff, financial, readonly)
- `clinicIds` - List of clinic IDs user belongs to
- `primaryClinicId` - User's primary clinic
- `ownerId` - Owner/creator of the user account
- `email`, `displayName`, `phoneNumber` - Contact information

### Available Notification Types
- appointment
- message  
- reminder
- system
- payment
- report
- alert

## Enhancement Plan

### 1. Enhanced Notification Model (Optional Extension)

**File**: `lib/src/features/notifications/domain/models/notification_model.dart`

**Add Optional Fields** (without breaking existing):
```dart
final List<String>? targetUserIds;      // Specific user IDs
final List<AppRole>? targetRoles;       // Target specific roles
final List<String>? targetClinicIds;    // Target specific clinics
final String? senderUserId;             // Who sent the notification
final NotificationPriority? priority;   // High, medium, low
final DateTime? expiresAt;              // When notification expires
final bool? requiresAction;             // If user action is required
```

**Add New Enum**:
```dart
enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}
```

### 2. Enhanced Targeting Options

#### 2.1 Recipient Selection Modes
Create a new enum for targeting modes:
```dart
enum RecipientMode {
  singleUser,           // Send to one specific user
  multipleUsers,        // Send to selected users
  allUsers,            // Send to all users
  byRole,              // Target users with specific role(s)
  byClinic,            // Target users in specific clinic(s)
  byRoleAndClinic,     // Combination of role + clinic
  customQuery,         // Advanced custom Firestore query
}
```

#### 2.2 Role-Based Targeting
**Use Cases**:
- Send system updates to all admins
- Send appointment reminders to all doctors
- Send financial reports to financial role users
- Send announcements to staff members
- Send read-only notifications to readonly users

**Implementation**:
```dart
Future<void> _sendToRole(AppRole role) async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('roles', arrayContains: AppRole.admin.roleToString(role))
      .get();
  
  // Create notifications for filtered users
}
```

#### 2.3 Clinic-Based Targeting
**Use Cases**:
- Send clinic-specific announcements
- Send updates to all users in a specific clinic
- Multi-clinic support for notifications

**Implementation**:
```dart
Future<void> _sendToClinic(String clinicId) async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('clinicIds', arrayContains: clinicId)
      .get();
  
  // Create notifications for clinic users
}
```

#### 2.4 Combined Targeting (Role + Clinic)
**Use Cases**:
- Send to all doctors in Clinic A
- Send to all admins in specific clinics
- Target staff in multiple clinics

**Implementation**:
```dart
Future<void> _sendToRoleInClinic(AppRole role, String clinicId) async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('roles', arrayContains: AppRole.admin.roleToString(role))
      .where('clinicIds', arrayContains: clinicId)
      .get();
  
  // Create notifications for filtered users
}
```

#### 2.5 Multiple User Selection
**Use Cases**:
- Send to specific list of users
- Cherry-pick recipients
- Import user list from CSV/file

**Implementation**:
- Multi-select user interface
- Search and filter users
- Import user IDs from clipboard/file

### 3. User Interface Enhancements

#### 3.1 New UI Components

**Recipient Selection Card**:
```
┌─────────────────────────────────────────┐
│ Recipient Selection                      │
├─────────────────────────────────────────┤
│ ○ Single User                           │
│ ○ Multiple Users                        │
│ ○ All Users                            │
│ ○ By Role                               │
│ ○ By Clinic                            │
│ ○ By Role + Clinic                     │
│ ○ Custom Query (Advanced)              │
└─────────────────────────────────────────┘
```

**Role Selection (when "By Role" selected)**:
```
┌─────────────────────────────────────────┐
│ Select Roles                            │
├─────────────────────────────────────────┤
│ ☑ Admin                    (12 users)   │
│ ☑ Doctor                   (45 users)   │
│ ☐ Staff                    (23 users)   │
│ ☐ Financial                (8 users)    │
│ ☐ Read Only                (5 users)    │
│                                         │
│ Total Recipients: 57 users              │
└─────────────────────────────────────────┘
```

**Clinic Selection (when "By Clinic" selected)**:
```
┌─────────────────────────────────────────┐
│ Select Clinics                          │
├─────────────────────────────────────────┤
│ ☑ Main Clinic              (78 users)   │
│ ☐ Downtown Branch          (34 users)   │
│ ☐ Suburb Office            (23 users)   │
│                                         │
│ Total Recipients: 78 users              │
└─────────────────────────────────────────┘
```

**Priority Selection**:
```
┌─────────────────────────────────────────┐
│ Notification Priority                   │
├─────────────────────────────────────────┤
│ ○ Low      - No urgency                 │
│ ● Medium   - Standard notification      │
│ ○ High     - Important, requires notice │
│ ○ Urgent   - Critical, immediate action │
└─────────────────────────────────────────┘
```

#### 3.2 User Preview & Confirmation
Before sending, show:
- Number of recipients
- List of recipient names/emails (first 10, then "and X more...")
- Estimated send time
- Preview of notification appearance

#### 3.3 Enhanced Templates
Add more contextual templates:
```dart
// Role-specific templates
Map<AppRole, List<NotificationTemplate>> roleTemplates = {
  AppRole.doctor: [
    NotificationTemplate(
      title: 'New Patient Assignment',
      body: 'A new patient has been assigned to your care',
      type: NotificationType.appointment,
    ),
    NotificationTemplate(
      title: 'Lab Results Available',
      body: 'Lab results for Patient X are ready for review',
      type: NotificationType.report,
    ),
  ],
  AppRole.admin: [
    NotificationTemplate(
      title: 'System Maintenance',
      body: 'Scheduled maintenance tonight at 11 PM',
      type: NotificationType.system,
    ),
  ],
  // ... more templates
};
```

### 4. Advanced Features

#### 4.1 Scheduling (Future Enhancement)
- Schedule notification for future delivery
- Recurring notifications
- Time-zone aware scheduling

#### 4.2 Batch Operations
- Import recipients from CSV
- Bulk send with personalized variables
- Send rate limiting to avoid Firestore quota issues

#### 4.3 Analytics Dashboard
- Delivery status tracking
- Read receipts
- Engagement metrics
- Failed deliveries log

#### 4.4 Preview & Testing
- Send test notification to self
- Preview notification appearance
- A/B testing support (send different versions)

### 5. Implementation Steps

#### Phase 1: Core Enhancements (Priority: HIGH)
1. **Update Notification Model** ✅ ALREADY EXISTS
   - Add targeting fields (optional)
   - Add priority enum
   - Update serialization

2. **Create Recipient Selection Widget**
   - File: `lib/src/features/notifications/presentation/widgets/recipient_selector_widget.dart`
   - Implement RecipientMode enum
   - Build UI for different selection modes

3. **Create Role Selector Widget**
   - File: `lib/src/features/notifications/presentation/widgets/role_selector_widget.dart`
   - Multi-select roles
   - Show user count per role

4. **Create Clinic Selector Widget**
   - File: `lib/src/features/notifications/presentation/widgets/clinic_selector_widget.dart`
   - Multi-select clinics
   - Show user count per clinic
   - Load clinics from Firestore

5. **Update Debug Sender Page**
   - Integrate new widgets
   - Add recipient mode selection
   - Implement filtering logic
   - Add recipient preview

#### Phase 2: User Experience (Priority: MEDIUM)
6. **Add User Search & Filter**
   - Search users by name, email
   - Filter by role, clinic
   - Multi-select interface

7. **Create Preview Component**
   - Show notification preview
   - Display recipient count
   - Confirm before send dialog

8. **Add Quick Filters**
   - "All Doctors"
   - "All Staff"
   - "My Clinic Only"
   - "All Admins"

#### Phase 3: Advanced Features (Priority: LOW)
9. **Add Scheduling Support**
   - Schedule for later
   - Recurring notifications

10. **Add Import/Export**
    - Import user IDs from CSV
    - Export notification logs

11. **Add Analytics**
    - Track delivery status
    - Show read receipts
    - Engagement metrics

### 6. Data Structure Recommendations

#### 6.1 Firestore Collections

**notifications** (existing):
```json
{
  "id": "auto-generated",
  "userId": "specific-user-id",
  "title": "Notification Title",
  "message": "Notification body",
  "type": "appointment",
  "isRead": false,
  "createdAt": "timestamp",
  "priority": "medium",
  "senderUserId": "admin-user-id",
  "actionUrl": "/appointments/123",
  "metadata": {
    "clinicId": "clinic-abc",
    "appointmentId": "appt-123"
  }
}
```

**notification_logs** (new - for tracking):
```json
{
  "id": "auto-generated",
  "batchId": "batch-uuid",
  "senderUserId": "admin-user-id",
  "recipientMode": "byRole",
  "targetRoles": ["doctor", "staff"],
  "targetClinics": ["clinic-abc"],
  "totalRecipients": 45,
  "successCount": 44,
  "failedCount": 1,
  "sentAt": "timestamp",
  "notificationData": {
    "title": "...",
    "message": "...",
    "type": "system"
  }
}
```

#### 6.2 Indexing Requirements
For efficient queries, create Firestore indexes:
```
Collection: users
Indexes:
- roles (array), clinicIds (array)
- primaryClinicId, roles (array)
- ownerId, roles (array)

Collection: notifications  
Indexes:
- userId, createdAt (desc)
- userId, isRead, createdAt (desc)
- type, createdAt (desc)
```

### 7. Security Considerations

#### 7.1 Access Control
**Who can send notifications?**
- Only users with `admin` role
- Only in debug mode for development
- Check permissions before showing sender page

**Implementation**:
```dart
// In navigation or route guard
bool canAccessNotificationSender(UserModel user) {
  return user.roles.contains(AppRole.admin) && kDebugMode;
}
```

#### 7.2 Firestore Security Rules
```javascript
match /notifications/{notificationId} {
  // Only allow admins to create notifications
  allow create: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid))
       .data.roles.hasAny(['admin']);
  
  // Users can only read their own notifications
  allow read: if request.auth != null 
    && resource.data.userId == request.auth.uid;
  
  // Users can only update their own notifications (mark as read)
  allow update: if request.auth != null 
    && resource.data.userId == request.auth.uid
    && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['isRead']);
}
```

#### 7.3 Rate Limiting
Prevent abuse by implementing rate limits:
- Max 100 notifications per minute per user
- Max 1000 notifications per batch
- Throttle bulk sends (add delay between batches)

### 8. Best Practices

#### 8.1 Performance Optimization
1. **Batch Writes**: Use Firestore batch writes (max 500 per batch)
2. **Pagination**: For large recipient lists, paginate queries
3. **Background Processing**: For very large sends, consider using AWS Lambda/Cloud Functions
4. **Caching**: Cache clinic and user lists

#### 8.2 Error Handling
1. **Graceful Degradation**: If one notification fails, continue with others
2. **Retry Logic**: Implement exponential backoff for failed sends
3. **Error Logging**: Log all failures for debugging
4. **User Feedback**: Show progress during bulk sends

#### 8.3 User Experience
1. **Progress Indicators**: Show sending progress for bulk operations
2. **Confirmation Dialogs**: Always confirm before bulk sends
3. **Undo Support**: Consider implementing undo within grace period
4. **Success Feedback**: Show success message with count sent

#### 8.4 Testing Strategy
1. **Unit Tests**: Test recipient filtering logic
2. **Integration Tests**: Test Firestore queries
3. **Manual Testing**: 
   - Send to self first
   - Test with small groups before production
   - Verify notifications appear correctly

### 9. Example Implementation Code

#### 9.1 Recipient Filter Helper
```dart
class RecipientFilter {
  static Future<List<String>> getUserIdsByMode({
    required RecipientMode mode,
    String? singleUserId,
    List<String>? multipleUserIds,
    List<AppRole>? roles,
    List<String>? clinicIds,
  }) async {
    switch (mode) {
      case RecipientMode.singleUser:
        return [singleUserId!];
      
      case RecipientMode.multipleUsers:
        return multipleUserIds!;
      
      case RecipientMode.allUsers:
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        return snapshot.docs.map((doc) => doc.id).toList();
      
      case RecipientMode.byRole:
        return await _getUsersByRoles(roles!);
      
      case RecipientMode.byClinic:
        return await _getUsersByClinic(clinicIds!);
      
      case RecipientMode.byRoleAndClinic:
        return await _getUsersByRoleAndClinic(roles!, clinicIds!);
      
      default:
        return [];
    }
  }
  
  static Future<List<String>> _getUsersByRoles(List<AppRole> roles) async {
    final userIds = <String>{};
    
    for (final role in roles) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('roles', arrayContains: AppRole.admin.roleToString(role))
          .get();
      
      userIds.addAll(snapshot.docs.map((doc) => doc.id));
    }
    
    return userIds.toList();
  }
  
  static Future<List<String>> _getUsersByClinic(List<String> clinicIds) async {
    final userIds = <String>{};
    
    for (final clinicId in clinicIds) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('clinicIds', arrayContains: clinicId)
          .get();
      
      userIds.addAll(snapshot.docs.map((doc) => doc.id));
    }
    
    return userIds.toList();
  }
  
  static Future<List<String>> _getUsersByRoleAndClinic(
    List<AppRole> roles,
    List<String> clinicIds,
  ) async {
    final userIds = <String>{};
    
    // Firestore doesn't support multiple array-contains in same query
    // So we need to do this client-side or use multiple queries
    for (final role in roles) {
      for (final clinicId in clinicIds) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('roles', arrayContains: AppRole.admin.roleToString(role))
            .where('clinicIds', arrayContains: clinicId)
            .get();
        
        userIds.addAll(snapshot.docs.map((doc) => doc.id));
      }
    }
    
    return userIds.toList();
  }
  
  static Future<int> getRecipientCount({
    required RecipientMode mode,
    String? singleUserId,
    List<String>? multipleUserIds,
    List<AppRole>? roles,
    List<String>? clinicIds,
  }) async {
    final userIds = await getUserIdsByMode(
      mode: mode,
      singleUserId: singleUserId,
      multipleUserIds: multipleUserIds,
      roles: roles,
      clinicIds: clinicIds,
    );
    return userIds.length;
  }
}
```

#### 9.2 Batch Notification Sender
```dart
class BatchNotificationSender {
  static const int _batchSize = 500; // Firestore limit
  
  static Future<Map<String, int>> sendToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];
    
    // Split into batches
    for (int i = 0; i < userIds.length; i += _batchSize) {
      final batchUserIds = userIds.skip(i).take(_batchSize).toList();
      
      try {
        final batch = FirebaseFirestore.instance.batch();
        final now = DateTime.now();
        
        for (final userId in batchUserIds) {
          final notification = NotificationModel(
            id: '',
            userId: userId,
            title: title,
            message: message,
            type: type,
            isRead: false,
            createdAt: now,
            actionUrl: actionUrl,
            metadata: metadata,
          );
          
          final docRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc();
          
          batch.set(docRef, notification.toJson());
        }
        
        await batch.commit();
        successCount += batchUserIds.length;
        
        // Add small delay between batches to avoid rate limits
        if (i + _batchSize < userIds.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        failedCount += batchUserIds.length;
        errors.add('Batch ${i ~/ _batchSize}: $e');
        debugPrint('Error sending batch: $e');
      }
    }
    
    return {
      'success': successCount,
      'failed': failedCount,
      'total': userIds.length,
    };
  }
}
```

### 10. Testing Checklist

- [ ] Send to single user (self)
- [ ] Send to multiple specific users
- [ ] Send to all users (small test set)
- [ ] Send to users with specific role
- [ ] Send to users in specific clinic
- [ ] Send to role + clinic combination
- [ ] Test with 100+ recipients
- [ ] Test with 1000+ recipients
- [ ] Verify notifications appear in recipient lists
- [ ] Verify filtering works correctly
- [ ] Test error handling (invalid user IDs)
- [ ] Test with expired/deleted users
- [ ] Verify security rules work correctly
- [ ] Test on different devices
- [ ] Test notification icons display correctly

### 11. Localization Keys Needed

Add to translation files:
```json
{
  "recipientMode": "Recipient Mode",
  "singleUser": "Single User",
  "multipleUsers": "Multiple Users",
  "allUsers": "All Users",
  "byRole": "By Role",
  "byClinic": "By Clinic",
  "byRoleAndClinic": "By Role and Clinic",
  "selectRoles": "Select Roles",
  "selectClinics": "Select Clinics",
  "totalRecipients": "Total Recipients",
  "users": "users",
  "notificationPriority": "Notification Priority",
  "low": "Low",
  "medium": "Medium",
  "high": "High",
  "urgent": "Urgent",
  "recipientPreview": "Recipient Preview",
  "confirmSendTo": "Confirm send to {count} users?",
  "sendingNotifications": "Sending notifications...",
  "notificationsSentSuccess": "{count} notifications sent successfully",
  "someNotificationsFailed": "{success} sent, {failed} failed",
  "loadingRecipients": "Loading recipients...",
  "noRecipientsSelected": "Please select at least one recipient",
  "admin": "Admin",
  "doctor": "Doctor",
  "staff": "Staff",
  "financial": "Financial",
  "readonly": "Read Only"
}
```

### 12. File Structure

```
lib/src/features/notifications/
├── domain/
│   ├── models/
│   │   ├── notification_model.dart ✅ EXISTS
│   │   ├── notification_priority.dart (NEW)
│   │   └── recipient_mode.dart (NEW)
│   ├── repositories/
│   │   └── abstract_notifications_repository.dart ✅ EXISTS
│   └── usecases/
│       ├── notifications_usecase.dart ✅ EXISTS
│       └── bulk_notification_usecase.dart (NEW)
├── data/
│   ├── remote/
│   │   ├── abstract_notification_api.dart ✅ EXISTS
│   │   └── notification_firebase_api.dart ✅ EXISTS
│   └── repositories/
│       └── notifications_repo_impl.dart ✅ EXISTS
├── presentation/
│   ├── bloc/
│   │   ├── notifications_bloc.dart ✅ EXISTS
│   │   ├── notifications_event.dart ✅ EXISTS
│   │   ├── notifications_state.dart ✅ EXISTS
│   │   ├── notification_sender_bloc.dart (NEW)
│   │   ├── notification_sender_event.dart (NEW)
│   │   └── notification_sender_state.dart (NEW)
│   ├── pages/
│   │   ├── notifications_page.dart ✅ EXISTS
│   │   └── debug_notification_sender_page.dart ✅ EXISTS (TO ENHANCE)
│   └── widgets/
│       ├── notification_list_item.dart ✅ EXISTS
│       ├── recipient_selector_widget.dart (NEW)
│       ├── role_selector_widget.dart (NEW)
│       ├── clinic_selector_widget.dart (NEW)
│       ├── notification_preview_widget.dart (NEW)
│       └── user_search_widget.dart (NEW)
└── notifications_injections.dart ✅ EXISTS
```

### 13. Recommended Implementation Order

1. **Quick Win** (30 minutes):
   - Add role-based filtering to existing page
   - Add "Send to All Admins" button
   - Add "Send to All Doctors" button

2. **Phase 1** (2-3 hours):
   - Create RecipientMode enum
   - Add recipient mode selector to UI
   - Implement role-based targeting
   - Add recipient count preview

3. **Phase 2** (3-4 hours):
   - Create clinic selector widget
   - Implement clinic-based targeting
   - Add combined role + clinic targeting
   - Add user preview before send

4. **Phase 3** (4-5 hours):
   - Add multiple user selection
   - Create user search interface
   - Add batch sending with progress
   - Implement error handling

5. **Polish** (2-3 hours):
   - Add more templates
   - Improve UI/UX
   - Add analytics
   - Write tests

### 14. Alternative Approaches

#### Option A: Simple Enhancement (Recommended for MVP)
Just add role and clinic filtering to existing page without major refactoring.

**Pros**: Quick, minimal code changes, immediate value
**Cons**: Less flexible, harder to extend later

#### Option B: Full Refactor (Recommended for Production)
Create separate Bloc, use cases, and widgets for notification sender.

**Pros**: Clean architecture, testable, maintainable, scalable
**Cons**: More time investment upfront

#### Option C: Hybrid (Best Balance)
Enhance existing page with new widgets, add minimal business logic.

**Pros**: Balance of speed and quality, incremental improvement
**Cons**: May need refactoring later

**RECOMMENDATION**: Start with **Option C (Hybrid)** for quick value, then refactor to Option B when needed.

---

## Summary

This plan provides a comprehensive roadmap for enhancing the notification sender with:
- ✅ Role-based targeting (admins, doctors, staff, etc.)
- ✅ Clinic-based targeting
- ✅ Combined targeting (role + clinic)
- ✅ Multiple user selection
- ✅ Batch sending with error handling
- ✅ User preview before sending
- ✅ Better templates and UX
- ✅ Security and best practices
- ✅ Performance optimization
- ✅ Testing strategy

The implementation can be done incrementally, starting with quick wins (role-based filtering) and progressively adding more advanced features.

**Estimated Total Time**: 12-15 hours for full implementation
**Quick Win Time**: 30-60 minutes for basic role filtering

**Next Steps**:
1. Review and approve plan
2. Decide on implementation approach (A, B, or C)
3. Start with Phase 1 (Core Enhancements)
4. Test thoroughly with small groups first
5. Iterate based on feedback
