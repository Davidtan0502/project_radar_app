import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static StreamSubscription<QuerySnapshot>? _incidentsSubscription;
  static final Set<String> _processedUpdates = {};
  static final Map<String, VoidCallback> _navigationHandlers = {};

  // Notification channels
  static const String _incidentChannelId = 'incident_updates_channel';
  static const String _incidentChannelName = 'Incident Updates';
  static const String _incidentChannelDesc = 'Notifications for incident status updates';

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Notification permissions: ${settings.authorizationStatus}");

    // Get device token
    String? token = await _firebaseMessaging.getToken();
    print("Device Token: $token");

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create notification channels
    await _createNotificationChannels();

    // Setup message handlers
    _setupMessageHandlers();

    // Start listening to incidents collection updates
    _startListeningToIncidents();

    // Configure foreground notification presentation
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel incidentChannel = AndroidNotificationChannel(
      _incidentChannelId,
      _incidentChannelName,
      description: _incidentChannelDesc,
      importance: Importance.high,
      showBadge: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incidentChannel);
  }

  static void _setupMessageHandlers() {
    // Handle when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // Handle when app is in background and opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _startListeningToIncidents() {
    _incidentsSubscription = FirebaseFirestore.instance
        .collection('incidents')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleIncidentUpdate(change.doc);
        }
      }
    }, onError: (error) {
      print("Error listening to incidents: $error");
    });
  }

  static void _handleIncidentUpdate(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final String incidentId = doc.id;
      final String? previousStatus = data['previousStatus'];
      final String? currentStatus = data['status'];
      final String? adminNote = data['latestAdminNote'];
      final String? incidentType = data['incidentType'];
      final String? userId = data['userId'];

      // Create unique identifier for this update to prevent duplicates
      final updateId = '$incidentId-${currentStatus}-${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Unique per minute
      
      if (_processedUpdates.contains(updateId)) return;
      _processedUpdates.add(updateId);

      // Clean up old processed updates (keep only last 100)
      if (_processedUpdates.length > 100) {
        _processedUpdates.clear();
      }

      // Only notify if status changed and it's not the initial submission
      if (previousStatus != currentStatus && currentStatus != null && previousStatus != null) {
        _sendStatusUpdateNotification(
          incidentId: incidentId,
          incidentType: incidentType ?? 'Incident',
          oldStatus: previousStatus,
          newStatus: currentStatus,
          adminNote: adminNote,
          userId: userId,
        );
      }

      // Notify about new admin notes (within last 10 minutes)
      if (adminNote != null && adminNote.isNotEmpty) {
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null && 
            DateTime.now().difference(lastUpdated.toDate()).inMinutes < 10) {
          _sendAdminNoteNotification(
            incidentId: incidentId,
            incidentType: incidentType ?? 'Incident',
            adminNote: adminNote,
            userId: userId,
          );
        }
      }
    } catch (e) {
      print("Error handling incident update: $e");
    }
  }

  static void _sendStatusUpdateNotification({
    required String incidentId,
    required String incidentType,
    required String? oldStatus,
    required String newStatus,
    required String? adminNote,
    required String? userId,
  }) {
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    String title = 'Incident Status Updated';
    String body = _getStatusUpdateMessage(incidentType, newStatus, adminNote);

    _showLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      data: {
        'incidentId': incidentId,
        'type': 'status_update',
        'newStatus': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Update user's unread notifications count
    if (userId != null) {
      _updateUnreadCount(userId, incidentId);
    }
  }

  static void _sendAdminNoteNotification({
    required String incidentId,
    required String incidentType,
    required String adminNote,
    required String? userId,
  }) {
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1;

    _showLocalNotification(
      id: notificationId,
      title: 'Update on Your $incidentType Report',
      body: 'Admin: ${_truncateText(adminNote, 100)}',
      data: {
        'incidentId': incidentId,
        'type': 'admin_note',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Update user's unread notifications count
    if (userId != null) {
      _updateUnreadCount(userId, incidentId);
    }
  }

  static String _getStatusUpdateMessage(String incidentType, String newStatus, String? adminNote) {
    String message = '';
    
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

    if (adminNote != null && adminNote.isNotEmpty) {
      message += '\nNote: ${_truncateText(adminNote, 80)}';
    }

    return message;
  }

  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Future<void> _updateUnreadCount(String userId, String incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'unread_incidents_$userId';
      
      final List<String> unreadIncidents = prefs.getStringList(key) ?? [];
      
      // Add new incident if not already present
      if (!unreadIncidents.contains(incidentId)) {
        unreadIncidents.add(incidentId);
        await prefs.setStringList(key, unreadIncidents);
      }
    } catch (e) {
      print("Error updating unread count: $e");
    }
  }

  static Future<int> getUnreadCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'unread_incidents_$userId';
      final List<String> unreadIncidents = prefs.getStringList(key) ?? [];
      return unreadIncidents.length;
    } catch (e) {
      print("Error getting unread count: $e");
      return 0;
    }
  }

  static Future<void> markAsRead(String userId, String incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'unread_incidents_$userId';
      
      final List<String> unreadIncidents = prefs.getStringList(key) ?? [];
      unreadIncidents.remove(incidentId);
      
      await prefs.setStringList(key, unreadIncidents);
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'unread_incidents_$userId';
      await prefs.remove(key);
    } catch (e) {
      print("Error marking all as read: $e");
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
            _incidentChannelId,
            _incidentChannelName,
            channelDescription: _incidentChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            autoCancel: true,
            colorized: true,
            color: const Color(0xFF3F73A3),
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(data),
      );
    } catch (e) {
      print("Error showing local notification: $e");
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    _handleBackgroundMessage(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print("Handling background message: ${message.messageId}");
    _showNotification(message);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print("Handling foreground message: ${message.messageId}");
    _showNotification(message);
  }

  static void _showNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      final data = message.data;
      
      if (notification != null) {
        _showLocalNotification(
          id: message.hashCode,
          title: notification.title ?? 'Incident Update',
          body: notification.body ?? 'Your incident report has been updated',
          data: data,
        );
      } else if (data.isNotEmpty) {
        // Handle data-only messages
        _showLocalNotification(
          id: message.hashCode,
          title: data['title'] ?? 'Incident Update',
          body: data['body'] ?? 'Your incident report has been updated',
          data: data,
        );
      }
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  static void _handleMessage(RemoteMessage? message) {
    if (message != null) {
      print("Message opened: ${message.messageId}");
      _handleNotificationData(message.data);
    }
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = json.decode(payload) as Map<String, dynamic>;
        _handleNotificationData(data);
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    final incidentId = data['incidentId']?.toString();
    final type = data['type']?.toString();
    
    if (incidentId != null) {
      // Trigger navigation handler if registered
      if (_navigationHandlers.containsKey(incidentId)) {
        _navigationHandlers[incidentId]!();
      } else {
        // Default navigation behavior
        _navigateToIncidentDetails(incidentId, type ?? 'unknown');
      }
    }
  }

  // Navigation management
  static void registerNavigationHandler(String incidentId, VoidCallback handler) {
    _navigationHandlers[incidentId] = handler;
  }

  static void unregisterNavigationHandler(String incidentId) {
    _navigationHandlers.remove(incidentId);
  }

  static void _navigateToIncidentDetails(String incidentId, String type) {
    print('Navigate to incident: $incidentId, type: $type');
    // This would typically be handled by your app's navigation system
    // You can use a global navigator key, event bus, or similar pattern
  }

  // Topic management
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print("Subscribed to topic: $topic");
    } catch (e) {
      print("Error subscribing to topic: $e");
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print("Unsubscribed from topic: $topic");
    } catch (e) {
      print("Error unsubscribing from topic: $e");
    }
  }

  // Token management
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  static Stream<String> get onTokenRefresh {
    return _firebaseMessaging.onTokenRefresh;
  }

  // Cleanup
  static void dispose() {
    _incidentsSubscription?.cancel();
    _processedUpdates.clear();
    _navigationHandlers.clear();
  }

  // Utility methods for testing
  static Future<void> sendTestNotification() async {
    _showLocalNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from the app',
      data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );
  }
}