// lib/providers/notification_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<AppNotification>>? _subscription;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.fetchNotificationsForUser(uid);
      await _subscription?.cancel();
      _subscription = _service.watchNotificationsForUser(uid).listen(
        (notifications) {
          _notifications = notifications;
          _loading = false;
          notifyListeners();
        },
        onError: (Object error) {
          _error = error.toString();
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String uid) => loadNotifications(uid);

  Future<void> markAsRead(String notificationId, String uid) async {
    await _service.markAsRead(notificationId);
    await loadNotifications(uid);
  }

  Future<void> respondToGroupInvite({
    required AppNotification notification,
    required String uid,
    required bool accept,
  }) async {
    await _service.respondToGroupInvite(
      notification: notification,
      userId: uid,
      accept: accept,
    );
    await loadNotifications(uid);
  }
}
