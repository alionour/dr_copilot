import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/notifications/data/remote/abstract_notification_api.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:flutter/foundation.dart';

class NotificationFirebaseApi implements AbstractNotificationApi {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'notifications';
  static const String _usersCollectionName = 'users';

  NotificationFirebaseApi({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection(_collectionName);
  CollectionReference get _usersCollection => _firestore.collection(_usersCollectionName);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to fetch unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _collection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  @override
  Future<NotificationModel> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _collection.add(notification.toJson());
      final doc = await docRef.get();
      return NotificationModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            return snapshot.docs
                .map((doc) => NotificationModel.fromJson({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }))
                .toList();
          } catch (e) {
            // Log error but don't crash
            debugPrint('Error mapping notifications: $e');
            return <NotificationModel>[];
          }
        })
        .handleError((error) {
          debugPrint('Error in notifications stream: $error');
          return <NotificationModel>[];
        });
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<int> sendBulkNotification(NotificationTemplate template) async {
    try {
      final targetUserIds = await getTargetUserIds(template.target);
      
      if (targetUserIds.isEmpty) {
        return 0;
      }

      final batch = _firestore.batch();
      int count = 0;

      for (final userId in targetUserIds) {
        final docRef = _collection.doc();
        final notification = NotificationModel(
          id: docRef.id,
          userId: userId,
          title: template.title,
          message: template.message,
          type: template.type,
          createdAt: DateTime.now(),
          actionUrl: template.actionUrl,
          metadata: template.metadata,
          sender: template.sender,
          target: template.target,
        );

        batch.set(docRef, notification.toJson());
        count++;

        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      return count;
    } catch (e) {
      throw Exception('Failed to send bulk notification: $e');
    }
  }

  @override
  Future<List<String>> getTargetUserIds(NotificationTarget target) async {
    try {
      Query<Object?> query = _usersCollection;

      switch (target.type) {
        case NotificationTargetType.allClinicOwners:
          query = query.where('roles', arrayContains: AppRole.admin.roleToString(AppRole.admin));
          break;

        case NotificationTargetType.allDoctors:
          query = query.where('roles', arrayContains: AppRole.doctor.roleToString(AppRole.doctor));
          break;

        case NotificationTargetType.allStaff:
          query = query.where('roles', arrayContains: AppRole.staff.roleToString(AppRole.staff));
          break;

        case NotificationTargetType.specificRoles:
          if (target.targetRoles == null || target.targetRoles!.isEmpty) {
            return [];
          }
          query = query.where('roles', arrayContainsAny: 
            target.targetRoles!.map((role) => AppRole.admin.roleToString(role)).toList());
          break;

        case NotificationTargetType.ownerClinics:
          if (target.ownerId == null) {
            return [];
          }
          query = query.where('ownerId', isEqualTo: target.ownerId);
          break;

        case NotificationTargetType.specificClinic:
          if (target.clinicIds == null || target.clinicIds!.isEmpty) {
            return [];
          }
          query = query.where('clinicIds', arrayContainsAny: target.clinicIds);
          break;
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get target user IDs: $e');
    }
  }
}
