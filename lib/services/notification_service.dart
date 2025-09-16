import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Show attendance reminder notification
  Future<void> showAttendanceReminder({
    required String title,
    required String body,
    required String sessionId,
  }) async {
    if (!await areNotificationsEnabled()) {
      await requestPermission();
    }

    const androidDetails = AndroidNotificationDetails(
      'attendance_reminders',
      'Attendance Reminders',
      channelDescription: 'Notifications for attendance sessions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      sessionId.hashCode,
      title,
      body,
      details,
      payload: sessionId,
    );
  }

  // Show attendance success notification
  Future<void> showAttendanceSuccess({
    required String title,
    required String body,
  }) async {
    if (!await areNotificationsEnabled()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'attendance_success',
      'Attendance Success',
      channelDescription: 'Notifications for successful attendance submissions',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF4CAF50),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
    );
  }

  // Show attendance error notification
  Future<void> showAttendanceError({
    required String title,
    required String body,
  }) async {
    if (!await areNotificationsEnabled()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'attendance_errors',
      'Attendance Errors',
      channelDescription: 'Notifications for attendance submission errors',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFF44336),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
    );
  }

  // Show offline queue notification
  Future<void> showOfflineQueueNotification({
    required int queueSize,
  }) async {
    if (!await areNotificationsEnabled()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'offline_queue',
      'Offline Queue',
      channelDescription: 'Notifications for offline attendance submissions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFFFF9800),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      'offline_queue'.hashCode,
      'Offline Attendance Queue',
      'You have $queueSize attendance submissions waiting to be synced',
      details,
    );
  }

  // Schedule attendance reminder
  Future<void> scheduleAttendanceReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String sessionId,
  }) async {
    if (!await areNotificationsEnabled()) {
      await requestPermission();
    }

    const androidDetails = AndroidNotificationDetails(
      'attendance_reminders',
      'Attendance Reminders',
      channelDescription: 'Notifications for attendance sessions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Note: zonedSchedule requires timezone package, using show for now
    await _notifications.show(
      sessionId.hashCode,
      title,
      body,
      details,
      payload: sessionId,
    );
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle notification tap based on payload
      print('Notification tapped with payload: $payload');
    }
  }

  // Show session starting soon notification
  Future<void> showSessionStartingSoon({
    required String sessionTitle,
    required String classroomName,
    required int minutesUntilStart,
  }) async {
    await showAttendanceReminder(
      title: 'Session Starting Soon',
      body: '$sessionTitle in $classroomName starts in $minutesUntilStart minutes',
      sessionId: 'session_starting_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Show session ending soon notification
  Future<void> showSessionEndingSoon({
    required String sessionTitle,
    required int minutesRemaining,
  }) async {
    await showAttendanceReminder(
      title: 'Session Ending Soon',
      body: '$sessionTitle ends in $minutesRemaining minutes',
      sessionId: 'session_ending_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Show location validation error
  Future<void> showLocationError({
    required String errorMessage,
  }) async {
    await showAttendanceError(
      title: 'Location Validation Failed',
      body: errorMessage,
    );
  }

  // Show WiFi validation error
  Future<void> showWifiError({
    required String expectedSSID,
  }) async {
    await showAttendanceError(
      title: 'WiFi Validation Failed',
      body: 'Please connect to the classroom WiFi: $expectedSSID',
    );
  }
}
