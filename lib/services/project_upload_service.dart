// lib/services/project_upload_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../hive_models/project_upload_model.dart';

class ProjectUploadService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  CollectionReference<Map<String, dynamic>> get _uploads =>
      _db.collection('project_uploads');

  Box<ProjectUploadModel> get _box =>
      Hive.box<ProjectUploadModel>('project_uploads');

  Future<ProjectUploadModel?> pickAndUpload({
    required String ownerId,
    required String ownerName,
    required bool fromCamera,
    String? groupName,
    String? taskTitle,
  }) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) {
      return null;
    }

    final file = File(picked.path);
    final fileName = picked.name;
    final fileType = _extensionFromName(fileName).toLowerCase();
    final createdAt = DateTime.now();
    final storagePath =
        'project_uploads/$ownerId/${createdAt.millisecondsSinceEpoch}_$fileName';

    final ref = _storage.ref(storagePath);
    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();
    final doc = _uploads.doc();
    final upload = ProjectUploadModel(
      id: doc.id,
      ownerId: ownerId,
      ownerName: ownerName,
      fileName: fileName,
      groupName: groupName?.trim() ?? '',
      taskTitle: taskTitle?.trim() ?? '',
      fileUrl: downloadUrl,
      storagePath: storagePath,
      fileType: fileType,
      createdAt: createdAt.toIso8601String(),
    );

    await doc.set(upload.toMap());
    await _box.put(upload.id, upload);
    return upload;
  }

  Future<List<ProjectUploadModel>> fetchUploadsForUser(String ownerId) async {
    final snap = await _uploads.where('ownerId', isEqualTo: ownerId).get();
    final uploads = snap.docs
        .map((doc) => ProjectUploadModel.fromMap(doc.data(), doc.id))
        .toList();
    uploads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return uploads;
  }

  List<ProjectUploadModel> readLocalUploads(String ownerId) {
    final uploads =
        _box.values.where((upload) => upload.ownerId == ownerId).toList();
    uploads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return uploads;
  }

  String _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'file';
    return name.substring(dot + 1);
  }
}
