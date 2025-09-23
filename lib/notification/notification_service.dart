import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler required by firebase_messaging.
/// Runs in a background isolate; must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel incidentChannel = AndroidNotificationChannel(
      'incident_updates_channel',
      'Incident Updates',
      description: 'Notifications for incident status updates',
      importance: Importance.high,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incidentChannel);

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Incident Update';
    final body = notification?.body ?? data['body'] ?? 'Your incident report has been updated';

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          incidentChannel.id,
          incidentChannel.name,
          channelDescription: incidentChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      ),
      payload: json.encode(data),
    );
  } catch (e) {
    debugPrint('Background handler error: $e');
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Exposed notifier for UI (notification badge)
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // Small cache to avoid duplicate duplicate notifications on rapid updates
  static final Set<String> _processedUpdateKeys = {};

  // Current signed in user id (app should call setCurrentUser after sign in)
  static String? _currentUserId;

  // navigator key for navigation on notification tap
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static Future<void> setCurrentUser(String uid) async {
    _currentUserId = uid;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> unread = prefs.getStringList('unread_incidents_$uid') ?? [];
      unreadCount.value = unread.length;
    } catch (e) {
      debugPrint('Error loading unread count: $e');
      unreadCount.value = 0;
    }
  }

  static Future<void> initialize() async {
    // Request permission
    final settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint("Notification permissions: ${settings.authorizationStatus}");

    // Show notifications when app is in foreground (iOS)
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // initialize local notifications
    await _initializeLocalNotifications();

    // create notification channel(s) for Android
    await _createNotificationChannels();

    // register handlers
    _setupMessageHandlers();

    // optional: Firestore listener for incident updates (keeps parity with server-side)
    _startListeningToIncidents();

    // register background handler (must be top-level)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // log token
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM token: $token');
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  static Future<void> _createNotificationChannels() async {
    const incidentChannel = AndroidNotificationChannel(
      'incident_updates_channel',
      'Incident Updates',
      description: 'Notifications for incident status updates',
      importance: Importance.high,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incidentChannel);
  }

  static void _setupMessageHandlers() {
    // App opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleMessage(message);
    });

    // App in background & user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static void _startListeningToIncidents() {
    try {
      FirebaseFirestore.instance.collection('incidents').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            _handleIncidentUpdate(change.doc);
          }
        }
      }, onError: (e) => debugPrint('Incident listener error: $e'));
    } catch (e) {
      debugPrint('Start listening error: $e');
    }
  }

  static void _handleIncidentUpdate(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final incidentId = doc.id;
      final previousStatus = data['previousStatus']?.toString();
      final currentStatus = data['status']?.toString();
      final adminNote = data['latestAdminNote']?.toString();
      final userId = data['userId']?.toString();
      final updateKey = '$incidentId|${currentStatus ?? "null"}';

      // avoid duplicates
      if (_processedUpdateKeys.contains(updateKey)) return;
      _processedUpdateKeys.add(updateKey);
      if (_processedUpdateKeys.length > 200) _processedUpdateKeys.remove(_processedUpdateKeys.first);

      // status changed
      if (previousStatus != null && currentStatus != null && previousStatus != currentStatus) {
        _sendStatusUpdateNotification(
          incidentId: incidentId,
          incidentType: data['incidentType']?.toString() ?? 'Incident',
          oldStatus: previousStatus,
          newStatus: currentStatus,
          adminNote: adminNote,
          userId: userId,
        );
      }

      // recent admin note (within ~10 minutes)
      if (adminNote != null && adminNote.isNotEmpty) {
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null && DateTime.now().difference(lastUpdated.toDate()).inMinutes < 10) {
          _sendAdminNoteNotification(
            incidentId: incidentId,
            incidentType: data['incidentType']?.toString() ?? 'Incident',
            adminNote: adminNote,
            userId: userId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling incident update: $e');
    }
  }

  static void _sendStatusUpdateNotification({
    required String incidentId,
    required String incidentType,
    required String oldStatus,
    required String newStatus,
    required String? adminNote,
    required String? userId,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final title = 'Incident Status Updated';
    final body = _getStatusUpdateMessage(incidentType, newStatus, adminNote);

    _showLocalNotification(
      id: id,
      title: title,
      body: body,
      data: {
        'incidentId': incidentId,
        'type': 'status_update',
        'newStatus': newStatus,
      },
    );

    if (userId != null) _updateUnreadCount(userId, incidentId);
  }

  static void _sendAdminNoteNotification({
    required String incidentId,
    required String incidentType,
    required String adminNote,
    required String? userId,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1;
    _showLocalNotification(
      id: id,
      title: 'Update on Your $incidentType Report',
      body: 'Admin: ${_truncateText(adminNote, 100)}',
      data: {'incidentId': incidentId, 'type': 'admin_note'},
    );

    if (userId != null) _updateUnreadCount(userId, incidentId);
  }

  static String _getStatusUpdateMessage(String incidentType, String newStatus, String? adminNote) {
    String message;
    switch (newStatus.toLowerCase()) {
      case 'verified':
        message = 'Your $incidentType report has been verified and is being addressed';
        break;
      case 'in progress':
        message = 'Authorities are now responding to your $incidentType report';
        break;
      case 'resolved':
        message = 'Your $incidentType report has been successfully resolved';
        break;
      case 'rejected':
        message = 'Your $incidentType report requires additional information';
        break;
      case 'under review':
        message = 'Your $incidentType report is under review';
        break;
      default:
        message = 'Status updated: $newStatus';
    }
    if (adminNote != null && adminNote.isNotEmpty) message += '\nNote: ${_truncateText(adminNote, 80)}';
    return message;
  }

  static String _truncateText(String text, int maxLength) => text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';

  static Future<void> _updateUnreadCount(String userId, String incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unread_incidents_$userId';
      final unread = prefs.getStringList(key) ?? [];
      if (!unread.contains(incidentId)) {
        unread.add(incidentId);
        await prefs.setStringList(key, unread);
      }
      if (_currentUserId == userId) unreadCount.value = unread.length;
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  static Future<int> getUnreadCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList('unread_incidents_$userId') ?? []).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  static Future<void> markAsRead(String userId, String incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unread_incidents_$userId';
      final unread = prefs.getStringList(key) ?? [];
      unread.remove(incidentId);
      await prefs.setStringList(key, unread);
      if (_currentUserId == userId) unreadCount.value = unread.length;
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unread_incidents_$userId';
      await prefs.remove(key);
      if (_currentUserId == userId) unreadCount.value = 0;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  static void _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    try {
      _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'incident_updates_channel',
            'Incident Updates',
            channelDescription: 'Notifications for incident status updates',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: json.encode(data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    debugPrint('Message opened: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');
    _showNotificationFromRemote(message);
  }

  static void _showNotificationFromRemote(RemoteMessage message) {
    try {
      final notification = message.notification;
      final data = message.data;
      if (notification != null) {
        _showLocalNotification(id: message.hashCode, title: notification.title ?? 'Incident Update', body: notification.body ?? '', data: data);
      } else if (data.isNotEmpty) {
        _showLocalNotification(id: message.hashCode, title: data['title'] ?? 'Incident Update', body: data['body'] ?? '', data: data);
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      _handleNotificationData(data);
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    final incidentId = data['incidentId']?.toString();
    final type = data['type']?.toString() ?? 'unknown';
    if (incidentId == null) return;

    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed('/incident', arguments: {'incidentId': incidentId, 'type': type});
    } else {
      debugPrint('No navigator key set. Received notification for $incidentId');
    }
  }

  // Utility helpers
  static Future<void> subscribeToTopic(String topic) => _firebaseMessaging.subscribeToTopic(topic);
  static Future<void> unsubscribeFromTopic(String topic) => _firebaseMessaging.unsubscribeFromTopic(topic);
  static Future<String?> getToken() => _firebaseMessaging.getToken();
  static Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  static void dispose() {
    _processedUpdateKeys.clear();
  }

  // For manual testing
  static Future<void> sendTestNotification() async {
    _showLocalNotification(id: 9999, title: 'Test Notification', body: 'This is a test notification', data: {'type': 'test'});
  }
}
