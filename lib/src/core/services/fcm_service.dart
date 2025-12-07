import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  StreamSubscription<QuerySnapshot>? _firestoreNotificationSubscription;
  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  /// Initialize FCM service
  Future<void> initialize(String userId) async {
    debugPrint('[FCM] Initializing FCM Service for user: $userId');

    // Initialize local notifications first (needed for both FCM and Firestore listeners)
    await _initializeLocalNotifications();

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)) {
      debugPrint(
        '[FCM] Running on Desktop: Using Firestore Listener for Notifications',
      );
      // On Desktop, we rely on Firestore listeners since FCM is not natively supported
      _monitorFirestoreNotifications(userId);
      return;
    }

    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get and save FCM token
        await _getFCMToken(userId);

        // Listen for token refresh
        _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveFCMToken(userId, newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Handle notification tap when app was terminated
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('[FCM] App opened from terminated state');
          _handleNotificationTap(initialMessage);
        }

        debugPrint('[FCM] Initialization completed successfully');
      } else {
        debugPrint('[FCM] Notification permission denied');
      }
    } catch (e) {
      debugPrint('[FCM] Error initializing: $e');
    }
  }

  /// Monitor Firestore notifications for Desktop platforms (or fallback)
  void _monitorFirestoreNotifications(String userId) {
    _firestoreNotificationSubscription?.cancel();

    // Listen for new notifications created after now
    // Note: This requires the 'createdAt' field to be a Timestamp
    final now = Timestamp.now();

    _firestoreNotificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: now)
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                _showLocalNotificationFromFirestore(data, change.doc.id);
              }
            }
          },
          onError: (error) {
            debugPrint('[FCM] Firestore notification listener error: $error');
          },
        );

    debugPrint(
      '[FCM] Firestore notification listener started for user: $userId',
    );
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // Linux/Windows settings if needed explicitly, but usually default is fine or handled via specific plugins if additional packages are used.
    // basic flutter_local_notifications setup works for basic usage.

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken(String userId) async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('[FCM] Token obtained: $_fcmToken');
        await _saveFCMToken(userId, _fcmToken!);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FCM] Token saved to Firestore');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message received');
    debugPrint('[FCM] Title: ${message.notification?.title}');
    debugPrint('[FCM] Body: ${message.notification?.body}');
    debugPrint('[FCM] Data: ${message.data}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Show local notification from Firestore data
  Future<void> _showLocalNotificationFromFirestore(
    Map<String, dynamic> data,
    String id,
  ) async {
    // Check if push notifications are enabled in settings
    final pushEnabledStr = await _secureStorage.read(key: 'pushNotifications');
    final pushEnabled = pushEnabledStr == null
        ? true
        : pushEnabledStr == 'true';

    if (!pushEnabled) {
      return;
    }

    final title = data['title'] as String? ?? 'New Notification';
    final body = data['message'] as String? ?? data['body'] as String? ?? '';

    // Use hashcode of ID for unique notification ID, ensuring it fits int range
    final notificationId = id.hashCode;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data['actionUrl'] ?? data['id'],
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Check if push notifications are enabled in settings
    final pushEnabledStr = await _secureStorage.read(key: 'pushNotifications');
    // Default to true if not set
    final pushEnabled = pushEnabledStr == null
        ? true
        : pushEnabledStr == 'true';

    if (!pushEnabled) {
      debugPrint('[FCM] Push notifications disabled in settings. Suppressing.');
      return;
    }

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['notificationId'] ?? message.data['actionUrl'],
      );
    }
  }

  /// Handle notification tap (background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped');
    debugPrint('[FCM] Data: ${message.data}');

    final notificationId = message.data['notificationId'];
    final actionUrl = message.data['actionUrl'];

    if (notificationId != null) {
      // Mark notification as read in Firestore
      _markNotificationAsRead(notificationId);
    }

    if (actionUrl != null) {
      // Navigate to the action URL
      // This will be handled by the app's navigation system
      debugPrint('[FCM] Should navigate to: $actionUrl');
      // TODO: Implement navigation using GoRouter
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped');
    debugPrint('[FCM] Payload: ${response.payload}');

    if (response.payload != null) {
      // Handle navigation
      // TODO: Implement navigation using GoRouter
    }
  }

  /// Mark notification as read in Firestore
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      debugPrint('[FCM] Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('[FCM] Error marking notification as read: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)) {
      return; // Not supported on desktop via FCM
    }
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)) {
      return; // Not supported on desktop via FCM
    }
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    _firestoreNotificationSubscription?.cancel();
    _tokenSubscription?.cancel();

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)) {
      return; // FCM deleteToken not supported/needed on desktop
    }
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] Token deleted');
    } catch (e) {
      debugPrint('[FCM] Error deleting token: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenSubscription?.cancel();
    _firestoreNotificationSubscription?.cancel();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received');
  debugPrint('[FCM] Title: ${message.notification?.title}');
  debugPrint('[FCM] Body: ${message.notification?.body}');
  debugPrint('[FCM] Data: ${message.data}');
}
