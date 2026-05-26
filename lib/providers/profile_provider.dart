// lib/providers/profile_provider.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final AuthService _authService;
  final ProfileService _profileService;

  ProfileProvider({AuthService? authService, ProfileService? profileService})
      : _authService = authService ?? AuthService(),
        _profileService = profileService ?? ProfileService();

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Update text fields (name, phone, etc.) ────────────────────────────────
  Future<bool> updateProfile(AppUser updatedUser) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.updateUser(updatedUser);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Change profile photo (device feature: image_picker) ───────────────────
  /// Shows gallery/camera picker, uploads, returns new URL (or null).
  Future<String?> changePhoto(String uid, {required bool fromCamera}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final url =
          await _profileService.changeProfilePhoto(uid, fromCamera: fromCamera);
      // persist locally in Hive profiles box
      try {
        final box = await Hive.openBox('profiles');
        if (url != null) await box.put(uid, url);
      } catch (_) {}
      _loading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }
}
