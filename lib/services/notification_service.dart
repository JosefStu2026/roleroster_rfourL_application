// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/group_model.dart';
import '../models/task_model.dart';
import 'group_service.dart';
import 'task_service.dart';

class NotificationService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final _groupService = GroupService();
  final _taskService = TaskService();

  CollectionReference get _notifications => _db.collection('notifications');

  Future<List<AppNotification>> fetchNotificationsForUser(String uid) async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map((d) =>
            AppNotification.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> respondToGroupInvite({
    required AppNotification notification,
    required String userId,
    required bool accept,
  }) async {
    final invitationId = notification.taskId;
    if (invitationId.isEmpty) return;

    if (accept) {
      await _groupService.acceptInvitation(
        invitationId: invitationId,
        userId: userId,
      );
    } else {
      await _groupService.declineInvitation(
        invitationId: invitationId,
        userId: userId,
      );
    }

    await markAsRead(notification.id);
  }

  Future<void> notifyTaskStatusChange({
    required TaskModel task,
    required String status,
  }) async {
    final group = await _groupService.fetchGroupById(task.groupId);
    if (group == null) return;

    final recipients = <String>{
      if (group.leaderId.isNotEmpty) group.leaderId,
      if (task.createdById.isNotEmpty) task.createdById,
    }..remove(task.assignedToId);

    final title = status == 'done'
        ? 'Task completed'
        : status == 'in_progress'
            ? 'Task started'
            : 'Task updated';

    final body = status == 'done'
        ? '${task.assignedToName} completed "${task.title}" in ${task.groupName}.'
        : status == 'in_progress'
            ? '${task.assignedToName} started "${task.title}" in ${task.groupName}.'
            : '${task.assignedToName} updated "${task.title}" in ${task.groupName}.';

    for (final recipientId in recipients) {
      await _upsertNotification(
        id: '${task.id}_${status}_$recipientId',
        recipientId: recipientId,
        type: 'task_status_$status',
        title: title,
        body: body,
        taskId: task.id,
        groupId: task.groupId,
        actorId: task.assignedToId,
        actorName: task.assignedToName,
      );
    }
  }

  Future<void> syncLeaderFollowUps({
    required String leaderId,
    required Iterable<GroupModel> groups,
    Duration staleAfter = const Duration(days: 3),
  }) async {
    final now = DateTime.now();
    for (final group in groups.where((g) => g.leaderId == leaderId)) {
      final tasks = await _taskService.fetchTasksForGroup(group.id);
      for (final task in tasks) {
        if (task.status == 'done' || task.status == 'archived') continue;

        final isStale = now.difference(task.updatedAt) >= staleAfter;
        if (!isStale) continue;

        await _upsertNotification(
          id: '${task.id}_followup_$leaderId',
          recipientId: leaderId,
          type: 'task_follow_up',
          title: 'Follow-up needed',
          body:
              '${task.assignedToName} has not updated "${task.title}" in ${group.name}.',
          taskId: task.id,
          groupId: task.groupId,
          actorId: task.assignedToId,
          actorName: task.assignedToName,
        );
      }
    }
  }

  /// Scan groups for due dates and notify members when a group's due date
  /// is now or has arrived. Uses upsert ids to avoid duplicates.
  Future<void> checkDueDates({required Iterable<GroupModel> groups}) async {
    final now = DateTime.now();
    for (final group in groups) {
      // ignore already archived groups
      if (group.archived) continue;
      if (group.dueAt.isBefore(now) || group.dueAt.isAtSameMomentAs(now)) {
        for (final memberId in group.memberIds) {
          await _upsertNotification(
            id: 'group_due_${group.id}_$memberId',
            recipientId: memberId,
            type: 'group_due_date',
            title: 'Group due date',
            body:
                'The project ${group.name} is due now (${group.dueAt.toIso8601String()}).',
            taskId: '',
            groupId: group.id,
            actorId: group.leaderId,
            actorName: group.leaderName,
          );
        }
      }
    }
  }

  Future<void> _upsertNotification({
    required String id,
    required String recipientId,
    required String type,
    required String title,
    required String body,
    required String taskId,
    required String groupId,
    required String actorId,
    required String actorName,
  }) async {
    final ref = _notifications.doc(id);
    final snap = await ref.get();
    if (snap.exists) return;

    final notification = AppNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      body: body,
      taskId: taskId,
      groupId: groupId,
      actorId: actorId,
      actorName: actorName,
      createdAt: DateTime.now(),
    );
    await ref.set(notification.toMap());
  }
}
