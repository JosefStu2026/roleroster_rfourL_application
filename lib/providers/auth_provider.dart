// lib/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final FcmService _fcmService;
  StreamSubscription<String?>? _tokenSub;

  AuthProvider({AuthService? service, FcmService? fcmService})
      : _service = service ?? AuthService(),
        _fcmService = fcmService ?? FcmService();

  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _errorMsg;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMsg => _errorMsg;
  bool get isLoggedIn => _user != null;
  bool get isLeader => _isLeaderRole(_user?.role);

  bool get isMember => _user != null && !isLeader;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading();
    try {
      _user = await _service.register(
        email: email,
        password: password,
        username: username,
      );
      _status = AuthStatus.authenticated;
      // Save FCM token for this user if available
      try {
        final token = await _fcmService.getToken();
        if (token != null) await _service.saveFcmToken(_user!.uid, token);
        // subscribe to token refreshes
        _tokenSub?.cancel();
        _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
          if (_user?.notificationsEnabled == true) {
            await _service.saveFcmToken(_user!.uid, t);
          }
        });
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      // Save FCM token for this user if available
      try {
        final token = await _fcmService.getToken();
        if (token != null) await _service.saveFcmToken(_user!.uid, token);
        _tokenSub?.cancel();
        _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
          if (_user?.notificationsEnabled == true) {
            await _service.saveFcmToken(_user!.uid, t);
          }
        });
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Google login ─────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      _user = await _service.signInWithGoogle();
      _status = AuthStatus.authenticated;
      // Save FCM token for this user if available
      try {
        final token = await _fcmService.getToken();
        if (token != null) await _service.saveFcmToken(_user!.uid, token);
        _tokenSub?.cancel();
        _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
          if (_user?.notificationsEnabled == true) {
            await _service.saveFcmToken(_user!.uid, t);
          }
        });
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _service.sendPasswordReset(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final uid = _user?.uid;
      // remove token when logging out
      if (uid != null) {
        try {
          await _fcmService.getToken().then((token) async {
            if (token != null) await _service.removeFcmToken(uid);
          });
        } catch (_) {}
      }
    } catch (_) {}
    // cancel token subscription
    _tokenSub?.cancel();
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Enable or disable push notifications for the current user.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      if (enabled) {
        final token = await _fcmService.getToken();
        if (token != null) await _service.saveFcmToken(uid, token);
      } else {
        await _service.removeFcmToken(uid);
      }
      // update local user copy
      _user = _user?.copyWith(notificationsEnabled: enabled);
      notifyListeners();
    } catch (_) {}
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<bool> deleteAccount() async {
    _setLoading();
    try {
      await _service.deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Update local user copy (called by ProfileProvider) ───────────────────
  void updateLocalUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMsg = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMsg = msg;
    notifyListeners();
  }

  bool _isLeaderRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    return normalized == 'leader' ||
        normalized == 'teacher' ||
        normalized == 'lead' ||
        normalized == 'manager';
  }
}
