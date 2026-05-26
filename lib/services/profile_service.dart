// lib/services/profile_service.dart
//
// Handles profile picture upload using image_picker + Firebase Storage,
// then saves the download URL back to Firestore.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  FirebaseStorage get _storage => FirebaseStorage.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final _picker = ImagePicker();

  // ── Pick image from gallery or camera ─────────────────────────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ── Upload to Firebase Storage & save URL to Firestore ───────────────────
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');

    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    // Update user's Firestore document with the new photo URL
    await _db.collection('users').doc(uid).update({'photoUrl': url});

    return url;
  }

  // ── Show bottom sheet helper (call from UI) ───────────────────────────────
  /// Returns the new photo URL, or null if cancelled.
  Future<String?> changeProfilePhoto(String uid,
      {required bool fromCamera}) async {
    final file = await pickImage(fromCamera: fromCamera);
    if (file == null) return null;
    return uploadProfilePhoto(uid, file);
  }
}
