// lib/providers/group_provider.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final _service = GroupService();

  List<GroupModel> _groups  = [];
  bool             _loading = false;
  String?          _error;

  List<GroupModel> get groups  => _groups;
  bool             get loading => _loading;
  String?          get error   => _error;

  // ── Load groups for signed-in user ────────────────────────────────────────
  Future<void> loadGroups(String uid) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      _groups = await _service.fetchGroupsForUser(uid);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ── Create group ──────────────────────────────────────────────────────────
  Future<bool> createGroup({
    required String name,
    required String leaderId,
    required String leaderName,
  }) async {
    try {
      final group = await _service.createGroup(
        name:        name,
        leaderId:    leaderId,
        leaderName:  leaderName,
      );
      _groups.insert(0, group);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Refresh a group's task counts ─────────────────────────────────────────
  Future<void> refreshTaskCounts(
      String groupId, int total, int done) async {
    await _service.updateTaskCounts(groupId, total, done);
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      // Rebuild the item with updated counts
      final old = _groups[idx];
      _groups[idx] = GroupModel(
        id:          old.id,
        name:        old.name,
        leaderId:    old.leaderId,
        leaderName:  old.leaderName,
        memberIds:   old.memberIds,
        totalTasks:  total,
        doneTasks:   done,
        createdAt:   old.createdAt,
      );
      notifyListeners();
    }
  }
}
