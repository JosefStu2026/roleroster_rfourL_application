// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Current user stream (used by AuthProvider) ────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Register ──────────────────────────────────────────────────────────────
  /// Creates a Firebase Auth account and saves user profile to Firestore.
  Future<AppUser> register({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = AppUser(
      uid: cred.user!.uid,
      username: username,
      email: email,
      phone: '',
      role: role,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final snap = await _db.collection('users').doc(cred.user!.uid).get();

    return AppUser.fromMap(snap.data()!, cred.user!.uid);
  }

  // ── Google sign-in ───────────────────────────────────────────────────────
  Future<AppUser> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Google sign-in is currently configured for web builds only.',
      );
    }

    final provider = GoogleAuthProvider()..addScope('email');
    final cred = await _auth.signInWithPopup(provider);
    final user = cred.user;

    if (user == null) {
      throw StateError('Google sign-in did not return a user.');
    }

    final docRef = _db.collection('users').doc(user.uid);
    final snap = await docRef.get();

    if (snap.exists && snap.data() != null) {
      return AppUser.fromMap(snap.data()!, user.uid);
    }

    final profile = AppUser(
      uid: user.uid,
      username: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email ?? 'User').split('@').first,
      email: user.email ?? '',
      phone: '',
      role: 'Member',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await docRef.set(profile.toMap());
    return profile;
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() => _auth.signOut();

  // ── Fetch user profile ────────────────────────────────────────────────────
  Future<AppUser?> fetchUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data()!, uid);
  }

  // ── Update user profile ───────────────────────────────────────────────────
  Future<void> updateUser(AppUser user) =>
      _db.collection('users').doc(user.uid).update(user.toMap());

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).delete();
    }
    await _auth.currentUser?.delete();
  }

  // ── Save FCM token to user's document for targeted pushes
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> removeFcmToken(String uid) async {
    await _db.collection('users').doc(uid).update(
        {'fcmToken': FieldValue.delete(), 'notificationsEnabled': false});
  }
}
