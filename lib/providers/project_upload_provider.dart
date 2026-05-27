// lib/providers/project_upload_provider.dart

import 'package:flutter/material.dart';

import '../hive_models/project_upload_model.dart';
import '../services/project_upload_service.dart';

class ProjectUploadProvider extends ChangeNotifier {
  final ProjectUploadService _service = ProjectUploadService();

  List<ProjectUploadModel> _uploads = [];
  bool _loading = false;
  String? _error;

  List<ProjectUploadModel> get uploads => _uploads;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadUploads(String ownerId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _uploads = await _service.fetchUploadsForUser(ownerId);
    } catch (e) {
      _uploads = _service.readLocalUploads(ownerId);
      _error = 'Offline - showing cached uploads';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> uploadDocument({
    required String ownerId,
    required String ownerName,
    required bool fromCamera,
    String? groupName,
    String? taskTitle,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final upload = await _service.pickAndUpload(
        ownerId: ownerId,
        ownerName: ownerName,
        fromCamera: fromCamera,
        groupName: groupName,
        taskTitle: taskTitle,
      );

      if (upload != null) {
        _uploads.insert(0, upload);
      }

      _loading = false;
      notifyListeners();
      return upload != null;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
