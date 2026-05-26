// lib/providers/task_provider.dart

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final _service = TaskService();
  final _notificationService = NotificationService();

  List<TaskModel> _tasks = [];
  List<TaskModel> _archived = [];
  bool _loading = false;
  String? _error;

  List<TaskModel> get tasks => _tasks;
  List<TaskModel> get archived => _archived;
  bool get loading => _loading;
  String? get error => _error;

  int get pendingCount => _tasks.where((t) => t.status == 'pending').length;

  // ── Load tasks for the current user ───────────────────────────────────────
  Future<void> loadTasks(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _service.fetchTasksForUser(uid);
    } catch (e) {
      // Fallback: load from local Hive cache when offline
      _tasks = _service.readLocalTasks();
      _error = 'Offline — showing cached data';
    }

    _loading = false;
    notifyListeners();
  }

  // ── Load archived tasks ───────────────────────────────────────────────────
  Future<void> loadArchived(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      _archived = await _service.fetchArchivedTasks(uid);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<List<TaskModel>> fetchTasksForGroup(String groupId) {
    return _service.fetchTasksForGroup(groupId);
  }

  // ── Create task ───────────────────────────────────────────────────────────
  Future<bool> createTask({
    required String groupId,
    required String groupName,
    required String title,
    required String assignedToId,
    required String assignedToName,
    required String createdById,
    required String createdByName,
    required String role,
    required DateTime deadline,
  }) async {
    try {
      final task = await _service.createTask(
        groupId: groupId,
        groupName: groupName,
        title: title,
        assignedToId: assignedToId,
        assignedToName: assignedToName,
        createdById: createdById,
        createdByName: createdByName,
        role: role,
        deadline: deadline,
      );
      _tasks.insert(0, task);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Update task status ────────────────────────────────────────────────────
  Future<void> updateStatus(String taskId, String status) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    final task = taskIndex == -1 ? null : _tasks[taskIndex];
    await _service.updateTaskStatus(taskId, status);
    if (task != null) {
      await _notificationService.notifyTaskStatusChange(
        task: task,
        status: status,
      );
    }

    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> reassignTask({
    required String taskId,
    required String assignedToId,
    required String assignedToName,
  }) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    await _service.reassignTask(
      taskId: taskId,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
    );

    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        assignedToId: assignedToId,
        assignedToName: assignedToName,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // ── Archive task ──────────────────────────────────────────────────────────
  Future<void> archiveTask(String taskId) async {
    await _service.archiveTask(taskId);
    final task = _tasks.firstWhere((t) => t.id == taskId,
        orElse: () => throw StateError('not found'));
    _tasks.removeWhere((t) => t.id == taskId);
    _archived.add(task.copyWith(status: 'archived'));
    notifyListeners();
  }

  // ── Delete task ───────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    await _service.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _archived.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }
}
