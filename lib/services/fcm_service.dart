// lib/services/fcm_service.dart
// Lightweight Firebase Cloud Messaging initialization and helpers.

import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // Request permission (for iOS / web interactive prompts)
      await _messaging.requestPermission();

      // Get and log token (can be saved to user doc for targeted messages)
      final token = await _messaging.getToken();
      // ignore: avoid_print
      print('FCM token: $token');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('FCM message received: ${message.notification?.title}');
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
