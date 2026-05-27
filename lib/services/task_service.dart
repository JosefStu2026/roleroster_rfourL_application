// lib/services/task_service.dart
//
// Handles all task operations:
//   • Firestore  →  remote source of truth
//   • Hive       →  local offline cache (CRUD demonstrated here for rubric)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/task_model.dart' as remote;
import '../hive_models/task_model.dart' as local;

class TaskService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference get _tasks => _db.collection('tasks');
  Box<local.TaskModel> get _box => Hive.box<local.TaskModel>('tasks');

  // ────────────────────────────────────────────────────────────────────────
  //  CREATE
  // ────────────────────────────────────────────────────────────────────────
  Future<remote.TaskModel> createTask({
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
    final ref = _tasks.doc();
    final task = remote.TaskModel(
      id: ref.id,
      groupId: groupId,
      groupName: groupName,
      title: title,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      createdById: createdById,
      createdByName: createdByName,
      status: 'pending',
      role: role,
      deadline: deadline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore
    await ref.set(task.toMap());

    // Cache locally in Hive (CREATE)
    await _saveToHive(task);

    return task;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  READ
  // ────────────────────────────────────────────────────────────────────────

  /// Fetch tasks from Firestore assigned to a user.
  Future<List<remote.TaskModel>> fetchTasksForUser(String uid) async {
    // Firestore does not always support complex negative filters reliably
    // across SDK versions or require composite indexes. Fetch by assignee
    // then filter out archived locally.
    final snap = await _tasks.where('assignedToId', isEqualTo: uid).get();

    final list = snap.docs
        .map((d) =>
            remote.TaskModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .where((t) => t.status != 'archived')
        .toList();

    // Sync to Hive
    for (final t in list) {
      await _saveToHive(t);
    }

    return list;
  }

  /// Fetch tasks for a specific group.
  Future<List<remote.TaskModel>> fetchTasksForGroup(String groupId) async {
    final snap = await _tasks.where('groupId', isEqualTo: groupId).get();

    return snap.docs
        .map((d) =>
            remote.TaskModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Read from local Hive cache (offline READ).
  List<remote.TaskModel> readLocalTasks() {
    return _box.values.map(_fromHive).toList();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  UPDATE
  // ────────────────────────────────────────────────────────────────────────
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    // Firestore UPDATE
    await _tasks.doc(taskId).update({
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Hive UPDATE
    final local = _box.get(taskId);
    if (local != null) {
      local.status = newStatus;
      await local.save();
    }
  }

  Future<void> reassignTask({
    required String taskId,
    required String assignedToId,
    required String assignedToName,
  }) async {
    await _tasks.doc(taskId).update({
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final local = _box.get(taskId);
    if (local != null) {
      local.assignedToId = assignedToId;
      local.assignedToName = assignedToName;
      await local.save();
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  DELETE
  // ────────────────────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    // Firestore DELETE
    await _tasks.doc(taskId).delete();

    // Hive DELETE
    await _box.delete(taskId);
  }

  // Archive = soft-delete (status change only)
  Future<void> archiveTask(String taskId) =>
      updateTaskStatus(taskId, 'archived');

  // ────────────────────────────────────────────────────────────────────────
  //  Archived tasks
  // ────────────────────────────────────────────────────────────────────────
  Future<List<remote.TaskModel>> fetchArchivedTasks(String uid) async {
    final snap = await _tasks
        .where('assignedToId', isEqualTo: uid)
        .where('status', isEqualTo: 'archived')
        .get();

    return snap.docs
        .map((d) =>
            remote.TaskModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Private helpers
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _saveToHive(remote.TaskModel task) async {
    final hiveTask = local.TaskModel(
      id: task.id,
      groupId: task.groupId,
      groupName: task.groupName,
      title: task.title,
      assignedToId: task.assignedToId,
      assignedToName: task.assignedToName,
      status: task.status,
      role: task.role,
      deadline: task.deadline.toIso8601String(),
      createdAt: task.createdAt.toIso8601String(),
    );
    await _box.put(task.id, hiveTask);
  }

  remote.TaskModel _fromHive(local.TaskModel h) => remote.TaskModel(
        id: h.id,
        groupId: h.groupId,
        groupName: h.groupName,
        title: h.title,
        assignedToId: h.assignedToId,
        assignedToName: h.assignedToName,
        createdById: h.assignedToId,
        createdByName: h.assignedToName,
        status: h.status,
        role: h.role,
        deadline: DateTime.parse(h.deadline),
        createdAt: DateTime.parse(h.createdAt),
        updatedAt: DateTime.parse(h.createdAt),
      );
}
