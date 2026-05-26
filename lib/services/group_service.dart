// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class InvitedMemberInput {
  final String identifier;
  final String role;

  const InvitedMemberInput({
    required this.identifier,
    required this.role,
  });
}

class GroupService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference get _groups => _db.collection('groups');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _invitations => _db.collection('group_invitations');

  // ── Create group ──────────────────────────────────────────────────────────
  Future<GroupModel> createGroup({
    required String name,
    required String title,
    required DateTime startedAt,
    required DateTime dueAt,
    required String leaderId,
    required String leaderName,
    List<InvitedMemberInput> invitedMembers = const [],
  }) async {
    final ref = _groups.doc(); // auto-id
    final normalizedLeaderRole = 'Leader';
    final group = GroupModel(
      id: ref.id,
      name: name,
      title: title,
      leaderId: leaderId,
      leaderName: leaderName,
      memberIds: [leaderId],
      memberNames: {leaderId: leaderName},
      memberRoles: {leaderId: normalizedLeaderRole},
      totalTasks: 0,
      doneTasks: 0,
      startedAt: startedAt,
      dueAt: dueAt,
      createdAt: DateTime.now(),
    );
    await ref.set(group.toMap());

    for (final invited in invitedMembers) {
      final target = await _findUserByIdentifier(invited.identifier);
      if (target == null) continue;
      final recipientId = target['uid'] as String;
      if (recipientId == leaderId) continue;

      final invitationRef = _invitations.doc();
      await invitationRef.set({
        'groupId': group.id,
        'groupName': group.name,
        'groupTitle': group.title,
        'leaderId': leaderId,
        'leaderName': leaderName,
        'recipientId': recipientId,
        'recipientName': target['username'] ?? '',
        'recipientEmail': target['email'] ?? '',
        'role': invited.role,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _notifications.doc('invite_${invitationRef.id}').set({
        'recipientId': recipientId,
        'type': 'group_invite_pending',
        'title': 'Group invitation',
        'body':
            '$leaderName invited you to join ${group.name} as ${invited.role}.',
        'taskId': invitationRef.id,
        'groupId': group.id,
        'actorId': leaderId,
        'actorName': leaderName,
        'createdAt': DateTime.now().toIso8601String(),
        'readAt': null,
      });
    }

    return group;
  }

  // ── Fetch all groups for a user ───────────────────────────────────────────
  Future<List<GroupModel>> fetchGroupsForUser(String uid) async {
    final snap = await _groups
        .where('memberIds', arrayContains: uid)
        .where('archived', isEqualTo: false)
        .get();
    return snap.docs
        .map((d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<GroupModel?> fetchGroupById(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ── Real-time stream (optional, for live UI updates) ─────────────────────
  Stream<List<GroupModel>> groupsStream(String uid) {
    return _groups.where('memberIds', arrayContains: uid).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── Update task counts (called after task status changes) ─────────────────
  Future<void> updateTaskCounts(
      String groupId, int totalTasks, int doneTasks) async {
    await _groups.doc(groupId).update({
      'totalTasks': totalTasks,
      'doneTasks': doneTasks,
    });
  }

  // ── Add member to group ───────────────────────────────────────────────────
  Future<void> addMember(String groupId, String userId) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final inviteRef = _invitations.doc(invitationId);

    await _db.runTransaction((tx) async {
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) return;
      final invite = inviteSnap.data() as Map<String, dynamic>;

      final recipientId = invite['recipientId'] as String? ?? '';
      final status = invite['status'] as String? ?? '';
      if (recipientId != userId || status != 'pending') return;

      final groupId = invite['groupId'] as String? ?? '';
      final role = (invite['role'] as String? ?? 'Member').trim();
      final recipientName = invite['recipientName'] as String? ?? 'Member';
      final groupRef = _groups.doc(groupId);

      tx.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberNames.$userId': recipientName,
        'memberRoles.$userId': role,
      });

      tx.update(inviteRef, {
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
      });
    });

    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists || inviteSnap.data() == null) return;
    final invite = inviteSnap.data() as Map<String, dynamic>;

    final leaderId = invite['leaderId'] as String? ?? '';
    if (leaderId.isNotEmpty) {
      await _notifications.doc('invite_accept_${invitationId}_$leaderId').set({
        'recipientId': leaderId,
        'type': 'group_invite_accepted',
        'title': 'Invitation accepted',
        'body':
            '${invite['recipientName'] ?? 'A member'} accepted your invite to ${invite['groupName'] ?? 'group'}.',
        'taskId': '',
        'groupId': invite['groupId'] ?? '',
        'actorId': userId,
        'actorName': invite['recipientName'] ?? 'Member',
        'createdAt': DateTime.now().toIso8601String(),
        'readAt': null,
      });
    }
  }

  Future<void> declineInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final inviteRef = _invitations.doc(invitationId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists || inviteSnap.data() == null) return;
    final invite = inviteSnap.data() as Map<String, dynamic>;

    if ((invite['recipientId'] as String? ?? '') != userId ||
        (invite['status'] as String? ?? '') != 'pending') {
      return;
    }

    await inviteRef.update({
      'status': 'declined',
      'respondedAt': DateTime.now().toIso8601String(),
    });

    final leaderId = invite['leaderId'] as String? ?? '';
    if (leaderId.isNotEmpty) {
      await _notifications.doc('invite_decline_${invitationId}_$leaderId').set({
        'recipientId': leaderId,
        'type': 'group_invite_declined',
        'title': 'Invitation declined',
        'body':
            '${invite['recipientName'] ?? 'A member'} declined your invite to ${invite['groupName'] ?? 'group'}.',
        'taskId': '',
        'groupId': invite['groupId'] ?? '',
        'actorId': userId,
        'actorName': invite['recipientName'] ?? 'Member',
        'createdAt': DateTime.now().toIso8601String(),
        'readAt': null,
      });
    }
  }

  Future<Map<String, dynamic>?> _findUserByIdentifier(String identifier) async {
    final value = identifier.trim();
    if (value.isEmpty) return null;

    final emailSnap =
        await _users.where('email', isEqualTo: value).limit(1).get();
    if (emailSnap.docs.isNotEmpty) {
      final doc = emailSnap.docs.first;
      return {
        'uid': doc.id,
        ...((doc.data() as Map<String, dynamic>)),
      };
    }

    final usernameSnap =
        await _users.where('username', isEqualTo: value).limit(1).get();
    if (usernameSnap.docs.isNotEmpty) {
      final doc = usernameSnap.docs.first;
      return {
        'uid': doc.id,
        ...((doc.data() as Map<String, dynamic>)),
      };
    }

    return null;
  }

  // ── Delete group (leader-only, cascades tasks/invitations + notifies members)
  Future<void> deleteGroup({
    required String groupId,
    required String requesterId,
  }) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists || doc.data() == null) return;
    final map = doc.data() as Map<String, dynamic>;
    final leaderId = map['leaderId'] as String? ?? '';
    if (leaderId != requesterId) {
      throw Exception('Only the leader can delete the group.');
    }

    final memberIds = List<String>.from(map['memberIds'] ?? []);

    final batch = _db.batch();

    // delete tasks belonging to the group
    final tasksSnap = await _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final t in tasksSnap.docs) {
      batch.delete(t.reference);
    }

    // delete invitations
    final invSnap =
        await _invitations.where('groupId', isEqualTo: groupId).get();
    for (final i in invSnap.docs) {
      batch.delete(i.reference);
    }

    // notify members and delete group doc
    for (final memberId in memberIds) {
      final nRef = _notifications.doc('group_deleted_${groupId}_$memberId');
      batch.set(nRef, {
        'recipientId': memberId,
        'type': 'group_deleted',
        'title': 'Group deleted',
        'body':
            '${map['leaderName'] ?? 'Leader'} deleted the group ${map['name'] ?? ''}.',
        'taskId': '',
        'groupId': groupId,
        'actorId': requesterId,
        'actorName': map['leaderName'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'readAt': null,
      });
    }

    batch.delete(_groups.doc(groupId));

    await batch.commit();
  }

  // ── Remove member (leader-only)
  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String removedById,
  }) async {
    final groupRef = _groups.doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists || groupSnap.data() == null) return;
    final map = groupSnap.data() as Map<String, dynamic>;
    final leaderId = map['leaderId'] as String? ?? '';
    if (leaderId != removedById) {
      throw Exception('Only the leader can remove members.');
    }

    await groupRef.update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'memberNames.$memberId': FieldValue.delete(),
      'memberRoles.$memberId': FieldValue.delete(),
    });

    // Reassign open tasks assigned to the removed member to unassigned
    final taskSnap = await _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .where('assignedToId', isEqualTo: memberId)
        .get();
    final batch = _db.batch();
    for (final t in taskSnap.docs) {
      String status = '';
      try {
        final s = t.get('status');
        if (s is String) status = s;
      } catch (_) {}
      if (status == 'archived') continue;
      batch.update(t.reference, {
        'assignedToId': '',
        'assignedToName': 'Unassigned',
      });
    }

    // notify removed member
    final nRef = _notifications.doc('member_removed_${groupId}_$memberId');
    batch.set(nRef, {
      'recipientId': memberId,
      'type': 'member_removed',
      'title': 'Removed from group',
      'body':
          '${map['leaderName'] ?? 'Leader'} removed you from ${map['name'] ?? ''}.',
      'taskId': '',
      'groupId': groupId,
      'actorId': removedById,
      'actorName': map['leaderName'] ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'readAt': null,
    });

    await batch.commit();
  }

  // ── Archive / mark group completed (leader-only)
  Future<void> archiveGroup({
    required String groupId,
    required String requesterId,
  }) async {
    final groupRef = _groups.doc(groupId);
    final snap = await groupRef.get();
    if (!snap.exists || snap.data() == null) return;
    final map = snap.data() as Map<String, dynamic>;
    final leaderId = map['leaderId'] as String? ?? '';
    if (leaderId != requesterId) {
      throw Exception('Only the leader can archive the group.');
    }

    await groupRef.update({
      'archived': true,
      'archivedAt': DateTime.now().toIso8601String(),
    });

    final memberIds = List<String>.from(map['memberIds'] ?? []);
    final batch = _db.batch();
    for (final memberId in memberIds) {
      final nRef = _notifications.doc('group_completed_${groupId}_$memberId');
      batch.set(nRef, {
        'recipientId': memberId,
        'type': 'group_completed',
        'title': 'Group completed',
        'body':
            '${map['leaderName'] ?? 'Leader'} marked ${map['name'] ?? ''} as completed.',
        'taskId': '',
        'groupId': groupId,
        'actorId': requesterId,
        'actorName': map['leaderName'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'readAt': null,
      });
    }

    await batch.commit();
  }
}
