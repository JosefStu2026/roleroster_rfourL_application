// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _groups => _db.collection('groups');

  // ── Create group ──────────────────────────────────────────────────────────
  Future<GroupModel> createGroup({
    required String name,
    required String leaderId,
    required String leaderName,
  }) async {
    final ref = _groups.doc(); // auto-id
    final group = GroupModel(
      id:          ref.id,
      name:        name,
      leaderId:    leaderId,
      leaderName:  leaderName,
      memberIds:   [leaderId],
      totalTasks:  0,
      doneTasks:   0,
      createdAt:   DateTime.now(),
    );
    await ref.set(group.toMap());
    return group;
  }

  // ── Fetch all groups for a user ───────────────────────────────────────────
  Future<List<GroupModel>> fetchGroupsForUser(String uid) async {
    final snap = await _groups
        .where('memberIds', arrayContains: uid)
        .get();
    return snap.docs
        .map((d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  // ── Real-time stream (optional, for live UI updates) ─────────────────────
  Stream<List<GroupModel>> groupsStream(String uid) {
    return _groups
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── Update task counts (called after task status changes) ─────────────────
  Future<void> updateTaskCounts(
      String groupId, int totalTasks, int doneTasks) async {
    await _groups.doc(groupId).update({
      'totalTasks': totalTasks,
      'doneTasks':  doneTasks,
    });
  }

  // ── Add member to group ───────────────────────────────────────────────────
  Future<void> addMember(String groupId, String userId) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  // ── Delete group ──────────────────────────────────────────────────────────
  Future<void> deleteGroup(String groupId) =>
      _groups.doc(groupId).delete();
}
