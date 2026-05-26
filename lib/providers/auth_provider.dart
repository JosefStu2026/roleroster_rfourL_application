// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status  = AuthStatus.initial;
  AppUser?   _user;
  String?    _errorMsg;

  AuthStatus get status   => _status;
  AppUser?   get user     => _user;
  String?    get errorMsg => _errorMsg;
  bool       get isLoggedIn => _user != null;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    _setLoading();
    try {
      _user = await _service.register(
        email:    email,
        password: password,
        username: username,
        role:     role,
      );
      _status = AuthStatus.authenticated;
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
    await _service.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<bool> deleteAccount() async {
    _setLoading();
    try {
      await _service.deleteAccount();
      _user   = null;
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
    _status   = AuthStatus.loading;
    _errorMsg = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status   = AuthStatus.error;
    _errorMsg = msg;
    notifyListeners();
  }
}
