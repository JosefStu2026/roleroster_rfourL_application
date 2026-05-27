// lib/providers/group_provider.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/notification_service.dart';

class GroupProvider extends ChangeNotifier {
  final _service = GroupService();
  final _notificationService = NotificationService();

  List<GroupModel> _groups = [];
  List<GroupModel> _archivedGroups = [];
  bool _loading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get archivedGroups => _archivedGroups;
  bool get loading => _loading;
  String? get error => _error;

  // ── Load groups for signed-in user ────────────────────────────────────────
  Future<void> loadGroups(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _service.fetchGroupsForUser(uid);
      // filter out archived groups from active list
      _groups = fetched.where((g) => g.archived == false).toList();
      await _notificationService.syncLeaderFollowUps(
        leaderId: uid,
        groups: _groups,
      );
      await _notificationService.checkDueDates(groups: _groups);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadArchivedGroups(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _archivedGroups = await _service.fetchArchivedGroupsForUser(uid);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> deleteGroup({
    required String groupId,
    required String requesterId,
  }) async {
    try {
      await _service.deleteGroup(groupId: groupId, requesterId: requesterId);
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String removedById,
  }) async {
    try {
      await _service.removeMember(
          groupId: groupId, memberId: memberId, removedById: removedById);
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) {
        final g = _groups[idx];
        g.memberIds.remove(memberId);
        g.memberNames.remove(memberId);
        g.memberRoles.remove(memberId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> archiveGroup({
    required String groupId,
    required String requesterId,
  }) async {
    try {
      await _service.archiveGroup(groupId: groupId, requesterId: requesterId);
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) {
        final group = _groups.removeAt(idx);
        _archivedGroups.insert(
          0,
          GroupModel(
            id: group.id,
            name: group.name,
            title: group.title,
            leaderId: group.leaderId,
            leaderName: group.leaderName,
            memberIds: group.memberIds,
            memberNames: group.memberNames,
            memberRoles: group.memberRoles,
            totalTasks: group.totalTasks,
            doneTasks: group.doneTasks,
            startedAt: group.startedAt,
            dueAt: group.dueAt,
            createdAt: group.createdAt,
            archived: true,
            archivedAt: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Create group ──────────────────────────────────────────────────────────
  Future<bool> createGroup({
    required String name,
    required String title,
    required DateTime startedAt,
    required DateTime dueAt,
    required String leaderId,
    required String leaderName,
    List<InvitedMemberInput> invitedMembers = const [],
  }) async {
    try {
      final group = await _service.createGroup(
        name: name,
        title: title,
        startedAt: startedAt,
        dueAt: dueAt,
        leaderId: leaderId,
        leaderName: leaderName,
        invitedMembers: invitedMembers,
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
  Future<void> refreshTaskCounts(String groupId, int total, int done) async {
    await _service.updateTaskCounts(groupId, total, done);
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      // Rebuild the item with updated counts
      final old = _groups[idx];
      _groups[idx] = GroupModel(
        id: old.id,
        name: old.name,
        title: old.title,
        leaderId: old.leaderId,
        leaderName: old.leaderName,
        memberIds: old.memberIds,
        memberNames: old.memberNames,
        memberRoles: old.memberRoles,
        totalTasks: total,
        doneTasks: done,
        startedAt: old.startedAt,
        dueAt: old.dueAt,
        createdAt: old.createdAt,
        archived: old.archived,
        archivedAt: old.archivedAt,
      );
      notifyListeners();
    }
  }
}
