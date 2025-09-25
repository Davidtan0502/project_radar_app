import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler required by firebase_messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.handleBackgroundMessage(message);
}

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase services
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State management
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final Set<String> _processedUpdateKeys = {};
  String? _currentUserId;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Keep per-user listener subscription
  StreamSubscription<QuerySnapshot>? _incidentSubscription;

  // Configuration
  static const String _androidChannelId = 'incident_updates_channel';
  static const String _androidChannelName = 'Incident Updates';
  static const String _fcmTokensCollection = 'fcm_tokens';
  static const String _usersCollection = 'users';

  // Duplicate prevention
  final Map<String, DateTime> _serverNotificationTimestamps = {};

  /// Initialize the notification service
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channels
      await _createNotificationChannels();

      // Set up message handlers
      _setupMessageHandlers();

      // Handle token refresh
      _setupTokenRefreshHandler();

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Log token for testing
      await _logTokenForTesting();

      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Set the current user and manage their FCM tokens
  Future<void> setCurrentUser(String? userId) async {
    if (userId == _currentUserId) return;

    // Remove old user's token and stop their listener
    if (_currentUserId != null) {
      await _removeTokenFromFirestore(_currentUserId!);
      _stopIncidentListener();
    }

    _currentUserId = userId;

    if (userId != null) {
      // Save new user's token
      await _saveTokenToFirestore(userId);
      // Load unread count
      await _loadUnreadCount(userId);
      // Start listener for this user's incidents (UI updates only)
      _startIncidentListenerForUser(userId);
    } else {
      unreadCount.value = 0;
    }
  }

  // MARK: - Private Methods

  Future<void> _requestPermissions() async {
    try {
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      debugPrint('Notification permissions: ${settings.authorizationStatus}');

      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: 'Notifications for incident status updates',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _setupMessageHandlers() {
    // Handle initial message when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // Handle message when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle message when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _setupTokenRefreshHandler() {
    _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      if (_currentUserId != null) {
        await _saveTokenToFirestore(_currentUserId!, token: newToken);
      }
    });
  }

  void _startIncidentListenerForUser(String userId) {
    _stopIncidentListener();

    try {
      _incidentSubscription = _firestore
          .collection('incidents')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            _handleIncidentUpdate(change.doc);
          }
        }
      }, onError: (e) => debugPrint('Incident listener error: $e'));
    } catch (e) {
      debugPrint('Error starting incident listener for user $userId: $e');
    }
  }

  void _stopIncidentListener() {
    _incidentSubscription?.cancel();
    _incidentSubscription = null;
  }

  // MARK: - FCM Token Management

  Future<void> _saveTokenToFirestore(String userId, {String? token}) async {
    try {
      final String? resolvedToken = token ?? await _firebaseMessaging.getToken();
      if (resolvedToken == null || resolvedToken.isEmpty) return;

      // Store token in users collection
      await _firestore.collection(_usersCollection).doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([resolvedToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Store in separate tokens collection
      await _firestore.collection(_fcmTokensCollection).doc(resolvedToken).set({
        'userId': userId,
        'token': resolvedToken,
        'platform': Platform.operatingSystem,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _removeTokenFromFirestore(String userId) async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token == null) return;

      // Remove from users collection
      try {
        await _firestore.collection(_usersCollection).doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } catch (e) {
        debugPrint('Could not remove token from users/$userId: $e');
      }

      // Remove from tokens collection
      try {
        await _firestore.collection(_fcmTokensCollection).doc(token).delete();
      } catch (e) {
        debugPrint('Could not delete fcm_tokens/$token: $e');
      }

      debugPrint('FCM token removed for user: $userId');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  Future<void> _logTokenForTesting() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  // MARK: - Message Handling

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      final instance = NotificationService();
      await instance._showNotificationFromRemote(message);
    } catch (e) {
      debugPrint('Background handler error: $e');
    }
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    debugPrint('Message opened: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');
    
    // Check if this is from server (Cloud Function)
    final isFromServer = message.data['source'] == 'server';
    
    if (isFromServer) {
      // Server notification - track it to avoid duplicates
      final incidentId = message.data['incidentId'];
      if (incidentId != null) {
        _serverNotificationTimestamps[incidentId] = DateTime.now();
      }
    }
    
    _showNotificationFromRemote(message);
  }

  void _handleIncidentUpdate(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final incidentId = doc.id;
      final previousStatus = data['previousStatus']?.toString();
      final currentStatus = data['status']?.toString();
      final adminNote = data['latestAdminNote']?.toString();
      final userId = data['userId']?.toString();
      final updateKey = '$incidentId|${currentStatus ?? "null"}';

      // Avoid processing duplicates
      if (_processedUpdateKeys.contains(updateKey)) return;
      _processedUpdateKeys.add(updateKey);
      
      // Clean up old keys
      if (_processedUpdateKeys.length > 200) {
        _processedUpdateKeys.remove(_processedUpdateKeys.first);
      }

      // Check if server already sent a notification for this incident
      final serverNotificationTime = _serverNotificationTimestamps[incidentId];
      final now = DateTime.now();
      
      // If server sent a notification in the last 5 seconds, skip local notification
      if (serverNotificationTime != null && 
          now.difference(serverNotificationTime).inSeconds < 5) {
        debugPrint('Skipping local notification - server notification already received for incident $incidentId');
        return;
      }

      // Handle status changes
      if (previousStatus != currentStatus && currentStatus != null) {
        _sendStatusUpdateNotification(
          incidentId: incidentId,
          incidentType: data['incidentType']?.toString() ?? 'Incident',
          oldStatus: previousStatus ?? 'Unknown',
          newStatus: currentStatus,
          adminNote: adminNote,
          userId: userId,
        );
      }

      // Handle recent admin notes
      if (adminNote != null && adminNote.isNotEmpty) {
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null &&
            DateTime.now().difference(lastUpdated.toDate()).inMinutes < 10) {
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

  // MARK: - Notification Display

  Future<void> _showNotificationFromRemote(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'] ?? 'Incident Update';
      final body = notification?.body ?? data['body'] ?? 'Your incident report has been updated';

      await _showLocalNotification(
        id: message.hashCode,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      debugPrint('Error showing notification from remote: $e');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Notifications for incident status updates',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: json.encode(data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // MARK: - Unread Count Management

  Future<void> _loadUnreadCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> unread = prefs.getStringList('unread_incidents_$userId') ?? [];
      unreadCount.value = unread.length;
    } catch (e) {
      debugPrint('Error loading unread count: $e');
      unreadCount.value = 0;
    }
  }

  Future<void> markAsRead(String incidentId) async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unread_incidents_$_currentUserId';
      final List<String> unread = prefs.getStringList(key) ?? [];
      unread.remove(incidentId);
      await prefs.setStringList(key, unread);
      unreadCount.value = unread.length;
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('unread_incidents_$_currentUserId');
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // MARK: - Notification Tap Handling

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      _handleNotificationData(data);
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final incidentId = data['incidentId']?.toString();
    if (incidentId == null) return;

    // Mark as read when notification is tapped
    if (_currentUserId != null) {
      markAsRead(incidentId);
    }

    // Navigate to ReportTrackerScreen
    _navigateToReportTracker(incidentId);
  }

  void _navigateToReportTracker(String incidentId) {
    _navigatorKey?.currentState?.pushNamed(
      '/reportTracker',
      arguments: {'highlightIncidentId': incidentId},
    );
  }

  // MARK: - Helper Methods

  void _sendStatusUpdateNotification({
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

  void _sendAdminNoteNotification({
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

  Future<void> _updateUnreadCount(String userId, String incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unread_incidents_$userId';
      final List<String> unread = prefs.getStringList(key) ?? [];
      if (!unread.contains(incidentId)) {
        unread.add(incidentId);
        await prefs.setStringList(key, unread);
      }
      if (_currentUserId == userId) {
        unreadCount.value = unread.length;
      }
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  String _getStatusUpdateMessage(String incidentType, String newStatus, String? adminNote) {
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
    if (adminNote != null && adminNote.isNotEmpty) {
      message += '\nNote: ${_truncateText(adminNote, 80)}';
    }
    return message;
  }

  String _truncateText(String text, int maxLength) {
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
  }

  // MARK: - Public API

  Future<String?> getFCMToken() => _firebaseMessaging.getToken();
  
  Future<void> subscribeToTopic(String topic) => _firebaseMessaging.subscribeToTopic(topic);
  
  Future<void> unsubscribeFromTopic(String topic) => _firebaseMessaging.unsubscribeFromTopic(topic);

  /// Cleanup on account delete
  Future<void> cleanupOnAccountDelete({required String userId}) async {
    try {
      // Remove tokens from Firestore
      List<String> tokens = [];
      try {
        final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
        final data = userDoc.data();
        if (data != null && data['fcmTokens'] is List) {
          tokens = (data['fcmTokens'] as List).whereType<String>().toList();
        }
      } catch (e) {
        debugPrint('Failed to read stored tokens for $userId: $e');
      }

      if (tokens.isNotEmpty) {
        try {
          final batch = _firestore.batch();
          final userRef = _firestore.collection(_usersCollection).doc(userId);

          for (final token in tokens) {
            if (token.trim().isEmpty) continue;
            final tokenRef = _firestore.collection(_fcmTokensCollection).doc(token);
            batch.delete(tokenRef);
            batch.update(userRef, {
              'fcmTokens': FieldValue.arrayRemove([token])
            });
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Failed to batch remove token docs for $userId: $e');
        }
      }

      // Remove current device token
      try {
        await _removeTokenFromFirestore(userId);
      } catch (e) {
        debugPrint('Best-effort _removeTokenFromFirestore failed: $e');
      }

      // Clear local state
      _stopIncidentListener();
      _processedUpdateKeys.clear();
      _serverNotificationTimestamps.clear();
      _currentUserId = null;
      unreadCount.value = 0;

      // Clear local preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('unread_incidents_$userId');
      } catch (e) {
        debugPrint('Failed to clear local unread prefs for $userId: $e');
      }

      debugPrint('NotificationService: cleanupOnAccountDelete completed for $userId');
    } catch (e, st) {
      debugPrint('NotificationService: cleanupOnAccountDelete error: $e\n$st');
    }
  }

  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from your app',
      data: {'type': 'test', 'testTime': DateTime.now().toString()},
    );
  }

  void dispose() {
    _processedUpdateKeys.clear();
    _serverNotificationTimestamps.clear();
    unreadCount.dispose();
    _stopIncidentListener();
  }
}