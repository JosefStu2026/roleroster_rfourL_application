// lib/services/fcm_service.dart
// Lightweight Firebase Cloud Messaging initialization and helpers.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'role_roster_notifications',
    'RoleRoster notifications',
    description: 'Notifications for group invites and updates.',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      // Request permission (for iOS / web interactive prompts)
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotificationsPlugin.initialize(initSettings);

      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get and log token (can be saved to user doc for targeted messages)
      final token = await _messaging.getToken();
      // ignore: avoid_print
      print('FCM token: $token');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('FCM message received: ${message.notification?.title}');
        final notification = message.notification;
        if (notification == null) return;

        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      });

      // Optional: handle when the app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('FCM onMessageOpenedApp: ${message.data}');
      });
    } catch (e) {
      // ignore: avoid_print
      print('FCM init error: $e');
    }
  }

  /// Returns the current FCM token for this device (may be null).
  Future<String?> getToken() => _messaging.getToken();
}
