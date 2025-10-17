import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // State management
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final Set<String> _processedUpdateKeys = {};
  String? _currentUserId;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Supabase Realtime subscription
  StreamSubscription<List<Map<String, dynamic>>>? _incidentSubscription;
  RealtimeChannel? _presenceChannel;

  // Configuration
  static const String _androidChannelId = 'incident_updates_channel';
  static const String _androidChannelName = 'Incident Updates';
  static const String _pushSubscriptionsTable = 'push_subscriptions'; // Supabase table for push subscriptions

  /// Initialize the notification service
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;

    try {
      // Request permissions (for local notifications)
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channels
      await _createNotificationChannels();

      // Set up Supabase Realtime listeners
      _setupRealtimeListeners();

      debugPrint('Supabase Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Set the current user and manage their notification subscriptions
  Future<void> setCurrentUser(String? userId) async {
    if (userId == _currentUserId) return;

    // Remove old user's subscription and stop their listener
    if (_currentUserId != null) {
      await _removeUserFromPresence(_currentUserId!);
      _stopIncidentListener();
    }

    _currentUserId = userId;

    if (userId != null) {
      // Register new user for push notifications
      await _registerForPushNotifications(userId);
      // Load unread count
      await _loadUnreadCount(userId);
      // Start listener for this user's incidents using Supabase Realtime
      _startIncidentListenerForUser(userId);
      // Join presence channel
      await _joinPresenceChannel(userId);
    } else {
      unreadCount.value = 0;
    }
  }

  // MARK: - Private Methods

  Future<void> _requestPermissions() async {
    try {
      // For local notifications, we'll use the local_notifications package
      // You might want to use permission_handler package for more granular control
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      
      if (Platform.isAndroid) {
        // Android permissions are typically handled in manifest
        // You can add additional permission handling here if needed
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

  void _setupRealtimeListeners() {
    // Listen for broadcast messages (for push notifications from server)
    _supabase.channel('broadcast')
        .onBroadcast(
          event: 'notification', 
          callback: (payload) {
            _handleBroadcastNotification(payload);
          }
        )
        .subscribe();
  }

  Future<void> _registerForPushNotifications(String userId) async {
    try {
      // In a real implementation, you would:
      // 1. Get device token from FCM/APNS
      // 2. Store it in Supabase push_subscriptions table
      // 3. Set up service worker for web push if needed
      
      // For now, we'll just store the user's notification preferences
      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'push_notifications_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Push notifications registered for user: $userId');
    } catch (e) {
      debugPrint('Error registering for push notifications: $e');
    }
  }

  void _startIncidentListenerForUser(String userId) {
    _stopIncidentListener();

    try {
      // Use Supabase Realtime to listen for incident updates for this user
      _incidentSubscription = _supabase
          .from('incidents')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((List<Map<String, dynamic>> incidents) {
        for (final incident in incidents) {
          _handleIncidentUpdate(incident);
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

  Future<void> _joinPresenceChannel(String userId) async {
    _presenceChannel?.unsubscribe();
    
    _presenceChannel = _supabase.channel('notifications:$userId')
      ..onPresenceSync((payload) {
        debugPrint('User $userId joined notification channel');
      })
      ..subscribe();
  }

  Future<void> _removeUserFromPresence(String userId) async {
    try {
      await _presenceChannel?.unsubscribe();
      _presenceChannel = null;
    } catch (e) {
      debugPrint('Error removing user from presence: $e');
    }
  }

  // MARK: - Message Handling

  void _handleBroadcastNotification(Map<String, dynamic> payload) {
    try {
      debugPrint('Received broadcast notification: $payload');
      
      final notificationType = payload['type']?.toString();
      final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data']) : {};
      
      switch (notificationType) {
        case 'incident_update':
          _handleIncidentBroadcast(Map<String, dynamic>.from(data));
          break;
        case 'admin_message':
          _handleAdminMessageBroadcast(Map<String, dynamic>.from(data));
          break;
        case 'system_alert':
          _handleSystemAlertBroadcast(Map<String, dynamic>.from(data));
          break;
        default:
          _showNotificationFromPayload(payload);
      }
    } catch (e) {
      debugPrint('Error handling broadcast notification: $e');
    }
  }

  void _handleIncidentBroadcast(Map<String, dynamic> data) {
    final incidentId = data['incident_id']?.toString();
    final title = data['title']?.toString() ?? 'Incident Update';
    final body = data['message']?.toString() ?? 'Your incident has been updated';
    final userId = data['user_id']?.toString();

    if (userId == _currentUserId) {
      _showLocalNotification(
        id: incidentId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        data: Map<String, dynamic>.from(data),
      );

      if (incidentId != null) {
        _updateUnreadCount(userId!, incidentId);
      }
    }
  }

  void _handleAdminMessageBroadcast(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Admin Message';
    final body = data['message']?.toString() ?? 'New message from admin';
    final userId = data['user_id']?.toString();

    if (userId == _currentUserId) {
      _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        data: Map<String, dynamic>.from(data),
      );
    }
  }

  void _handleSystemAlertBroadcast(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'System Alert';
    final body = data['message']?.toString() ?? 'System notification';
    
    // System alerts go to all users
    _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      data: Map<String, dynamic>.from(data),
    );
  }

  void _handleIncidentUpdate(Map<String, dynamic> incident) {
    try {
      final incidentId = incident['id']?.toString();
      final previousStatus = incident['previous_status']?.toString();
      final currentStatus = incident['status']?.toString();
      final adminNote = incident['latest_admin_note']?.toString();
      final userId = incident['user_id']?.toString();
      final updateKey = '$incidentId|${currentStatus ?? "null"}';

      // Avoid processing duplicates
      if (_processedUpdateKeys.contains(updateKey)) return;
      _processedUpdateKeys.add(updateKey);
      
      // Clean up old keys
      if (_processedUpdateKeys.length > 200) {
        _processedUpdateKeys.remove(_processedUpdateKeys.first);
      }

      // Only process if this is for the current user
      if (userId != _currentUserId) return;

      // Handle status changes
      if (previousStatus != currentStatus && currentStatus != null) {
        _sendStatusUpdateNotification(
          incidentId: incidentId!,
          incidentType: incident['incident_type']?.toString() ?? 'Incident',
          oldStatus: previousStatus ?? 'Unknown',
          newStatus: currentStatus,
          adminNote: adminNote,
          userId: userId,
        );
      }

      // Handle recent admin notes
      if (adminNote != null && adminNote.isNotEmpty) {
        final lastUpdatedStr = incident['last_updated']?.toString();
        if (lastUpdatedStr != null) {
          final lastUpdated = DateTime.tryParse(lastUpdatedStr);
          if (lastUpdated != null &&
              DateTime.now().difference(lastUpdated).inMinutes < 10) {
            _sendAdminNoteNotification(
              incidentId: incidentId!,
              incidentType: incident['incident_type']?.toString() ?? 'Incident',
              adminNote: adminNote,
              userId: userId,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling incident update: $e');
    }
  }

  // MARK: - Notification Display

  Future<void> _showNotificationFromPayload(Map<String, dynamic> payload) async {
    try {
      final title = payload['title']?.toString() ?? 'Notification';
      final body = payload['body']?.toString() ?? payload['message']?.toString() ?? 'New notification';
      final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data']) : {};

      await _showLocalNotification(
        id: payload.hashCode,
        title: title,
        body: body,
        data: (Map<String, dynamic>.from(data)),
      );
    } catch (e) {
      debugPrint('Error showing notification from payload: $e');
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
    final incidentId = data['incident_id']?.toString() ?? data['incidentId']?.toString();
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
        'incident_id': incidentId,
        'type': 'status_update',
        'new_status': newStatus,
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
      data: {'incident_id': incidentId, 'type': 'admin_note'},
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

  /// Send a test notification
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from your app',
      data: {'type': 'test', 'testTime': DateTime.now().toString()},
    );
  }

  /// Send a broadcast notification to all users (admin function)
  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.channel('broadcast').sendBroadcastMessage(
        event: 'notification',
        payload: {
          'title': title,
          'message': message,
          'type': type,
          'data': data ?? {},
          'sent_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
    }
  }

  /// Cleanup on account delete
  Future<void> cleanupOnAccountDelete({required String userId}) async {
    try {
      // Remove notification preferences from Supabase
      try {
        await _supabase.from('user_preferences').delete().eq('user_id', userId);
      } catch (e) {
        debugPrint('Failed to remove preferences from Supabase for $userId: $e');
      }

      // Clear local state
      _stopIncidentListener();
      await _removeUserFromPresence(userId);
      _processedUpdateKeys.clear();
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

  void dispose() {
    _processedUpdateKeys.clear();
    unreadCount.dispose();
    _stopIncidentListener();
    _presenceChannel?.unsubscribe();
  }
}