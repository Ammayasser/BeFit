// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      // Request permissions for Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        debugPrint('NotificationService: Android permission status: $status');
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final initialized = await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );
      
      _isInitialized = initialized ?? false;
      debugPrint('NotificationService: Initialized successfully: $_isInitialized');
    } catch (e) {
      debugPrint('NotificationService: Initialization error: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        debugPrint('NotificationService: Not initialized, initializing now...');
        await init();
      }

      // Final check for Android 13+ permission before showing
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          debugPrint('NotificationService: Permission not granted, requesting...');
          await Permission.notification.request();
        }
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'befit_test_channel',
        'BeFit Test Notifications',
        channelDescription: 'Used for testing the notification system',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      debugPrint('NotificationService: Attempting to show notification...');
      await _notificationsPlugin.show(
        id: 12345,
        title: 'BeFit Test 🚀',
        body: 'Notification is working perfectly! 💪',
        notificationDetails: platformDetails,
      );
      debugPrint('NotificationService: Notification command executed');
    } catch (e) {
      debugPrint('NotificationService: Error showing notification: $e');
    }
  }
}
