import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_model.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'task_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<List<TaskModel>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<List<TaskModel>> _loadTasks() async {
    final taskProv = context.read<TaskProvider>();
    final groupProv = context.read<GroupProvider>();

    final tasks = await taskProv.fetchTasksForGroup(widget.group.id);
    final done = tasks.where((task) => task.status == 'done').length;
    if (mounted) {
      await groupProv.refreshTaskCounts(
        widget.group.id,
        tasks.length,
        done,
      );
    }
    return tasks;
  }

  Future<void> _refresh() async {
    setState(() {
      _tasksFuture = _loadTasks();
    });
    await _tasksFuture;
  }

  Future<void> _showCreateTaskSheet() async {
    final auth = context.read<AuthProvider>();
    final group = widget.group;
    final titleCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    String? selectedAssigneeId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickDeadline() async {
              final date = await showDatePicker(
                context: sheetContext,
                initialDate: selectedDeadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setSheetState(() => selectedDeadline = date);
              }
            }

            Future<void> submit() async {
              final assigneeId = selectedAssigneeId;
              final assigneeName = assigneeId == null
                  ? ''
                  : (group.memberNames[assigneeId] ?? assigneeId);

              if (titleCtrl.text.trim().isEmpty ||
                  assigneeId == null ||
                  roleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Fill in all task fields.')),
                );
                return;
              }

              await sheetContext.read<TaskProvider>().createTask(
                    groupId: group.id,
                    groupName: group.name,
                    title: titleCtrl.text.trim(),
                    assignedToId: assigneeId,
                    assignedToName: assigneeName,
                    createdById: auth.user!.uid,
                    createdByName: auth.user!.username,
                    role: roleCtrl.text.trim(),
                    deadline: selectedDeadline,
                  );

              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }

            final candidateMemberIds =
                group.memberIds.where((id) => id != group.leaderId).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Task',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (candidateMemberIds.isEmpty)
                      const Text(
                        'No accepted members in this group yet.',
                        style: TextStyle(color: AppColors.textLight),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedAssigneeId,
                        items: candidateMemberIds
                            .map(
                              (memberId) => DropdownMenuItem<String>(
                                value: memberId,
                                child: Text(
                                  '${group.memberNames[memberId] ?? memberId} (${group.memberRoles[memberId] ?? 'Member'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (memberId) {
                          setSheetState(() => selectedAssigneeId = memberId);
                        },
                        decoration:
                            const InputDecoration(labelText: 'Assign member'),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Task title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Task title / category',
                        hintText: 'e.g. Create presentation, script, docs',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Deadline: ${selectedDeadline.month}/${selectedDeadline.day}/${selectedDeadline.year}',
                          ),
                        ),
                        TextButton(
                          onPressed: pickDeadline,
                          child: const Text('Pick date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
                        child: const Text('Create task'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    roleCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLeader = auth.user?.uid == widget.group.leaderId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: AppColors.primary,
        actions: [
          if (isLeader)
            PopupMenuButton<String>(
              onSelected: (v) async {
                final gp = context.read<GroupProvider>();
                final uid = context.read<AuthProvider>().user?.uid;
                if (uid == null) return;
                if (v == 'archive') {
                  final navigator = Navigator.of(context);
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Mark group completed'),
                          content: const Text(
                              'Marking the group as completed will archive it for all members. Continue?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Confirm')),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok) {
                    await gp.archiveGroup(
                      groupId: widget.group.id,
                      requesterId: uid,
                    );
                    if (mounted) navigator.pop();
                  }
                } else if (v == 'delete') {
                  final navigator = Navigator.of(context);
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete group'),
                          content: const Text(
                              'This will delete the group and its tasks for all members. This action cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok) {
                    await gp.deleteGroup(
                      groupId: widget.group.id,
                      requesterId: uid,
                    );
                    if (mounted) navigator.pop();
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'archive', child: Text('Mark Completed')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete Group')),
              ],
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TaskModel>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            final tasks = (snapshot.data ?? const <TaskModel>[])
                .where((task) => task.status != 'archived')
                .toList();
            final totalTasks = tasks.length;
            final completedTasks =
                tasks.where((task) => task.status == 'done').length;
            final inProgressTasks =
                tasks.where((task) => task.status == 'in_progress').length;
            final todoTasks =
                tasks.where((task) => task.status == 'pending').length;
            final workload = _buildWorkload(tasks);
            final progress =
                totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
            final balanceScore = _balanceScore(workload.values.toList());
            final balanceLabel = _balanceLabel(balanceScore);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const RRSearchBar(hint: 'Search groups...'),
                const SizedBox(height: 16),
                _HeaderCard(group: widget.group, isLeader: isLeader),
                const SizedBox(height: 16),
                _ProgressCard(
                  totalTasks: totalTasks,
                  completedTasks: completedTasks,
                  inProgressTasks: inProgressTasks,
                  todoTasks: todoTasks,
                  progress: progress,
                ),
                const SizedBox(height: 16),
                _WorkloadCard(
                  group: widget.group,
                  workload: workload,
                  balanceScore: balanceScore,
                  balanceLabel: balanceLabel,
                ),
                const SizedBox(height: 16),
                if (isLeader) ...[
                  _SectionCard(
                    title: 'Task Actions',
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateTaskSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add task for member'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  title: 'Members & Roles',
                  child: Column(
                    children: [
                      ...widget.group.memberIds.map(
                        (memberId) => _MemberRow(
                          groupId: widget.group.id,
                          name: widget.group.memberNames[memberId] ?? memberId,
                          id: memberId,
                          role: widget.group.memberRoles[memberId] ?? 'Member',
                          isLeader: isLeader,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Tasks',
                  child: tasks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No tasks yet in this group.',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        )
                      : Column(
                          children: tasks
                              .map(
                                (task) => GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailScreen(task: task),
                                      ),
                                    );
                                    if (mounted) {
                                      await _refresh();
                                    }
                                  },
                                  child: _TaskRow(
                                    task: task,
                                    canReassign: isLeader,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, int> _buildWorkload(List<TaskModel> tasks) {
    final workload = <String, int>{
      for (final memberId in widget.group.memberIds) memberId: 0,
    };

    for (final task in tasks) {
      if (task.status == 'archived') continue;
      workload[task.assignedToId] = (workload[task.assignedToId] ?? 0) + 1;
    }

    return workload;
  }

  String _balanceLabel(double score) {
    if (score <= 0.15) return 'Balanced';
    if (score <= 0.35) return 'Mostly balanced';
    return 'Needs attention';
  }

  double _balanceScore(List<int> values) {
    if (values.isEmpty) return 0;
    final maxCount = values.reduce((a, b) => a > b ? a : b);
    final minCount = values.reduce((a, b) => a < b ? a : b);
    final spread = maxCount - minCount;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return 0;
    return spread / (total == 0 ? 1 : total);
  }
}

class _HeaderCard extends StatelessWidget {
  final GroupModel group;
  final bool isLeader;

  const _HeaderCard({required this.group, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(group.title,
                        style: const TextStyle(color: AppColors.textLight)),
                  ],
                ),
              ),
              if (isLeader)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('You are the Leader',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Project started: ${_formatDate(group.startedAt)}'),
          Text('Project due: ${_formatDate(group.dueAt)}'),
          Text('Leader: ${group.leaderName}'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _ProgressCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int todoTasks;
  final double progress;

  const _ProgressCard({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.todoTasks,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group Progress Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.progressBlue),
            ),
          ),
          const SizedBox(height: 10),
          Text('${(progress * 100).round()}% complete'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MetricCard(label: 'Total', value: '$totalTasks')),
              const SizedBox(width: 8),
              Expanded(
                  child: _MetricCard(label: 'Done', value: '$completedTasks')),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _MetricCard(label: 'Doing', value: '$inProgressTasks')),
              const SizedBox(width: 8),
              Expanded(child: _MetricCard(label: 'To do', value: '$todoTasks')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  final GroupModel group;
  final Map<String, int> workload;
  final double balanceScore;
  final String balanceLabel;

  const _WorkloadCard({
    required this.group,
    required this.workload,
    required this.balanceScore,
    required this.balanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final maxTasks = workload.values.isEmpty
        ? 0
        : workload.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workload Balance Check',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            'Balance status: $balanceLabel',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...group.memberIds.map((memberId) {
            final count = workload[memberId] ?? 0;
            final ratio = maxTasks == 0 ? 0.0 : count / maxTasks;
            final name = group.memberNames[memberId] ?? memberId;
            final role = group.memberRoles[memberId] ?? 'Member';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('$name · $role',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text('$count task${count == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String groupId;
  final String name, id, role;
  final bool isLeader;

  const _MemberRow(
      {required this.groupId,
      required this.name,
      required this.id,
      required this.role,
      required this.isLeader});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('ID: $id',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tagBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role,
                style: const TextStyle(
                    color: AppColors.progressBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          if (isLeader && role != 'Leader') ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) async {
                final gp = context.read<GroupProvider>();
                final uid = context.read<AuthProvider>().user?.uid;
                if (uid == null) return;
                if (v == 'remove') {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Remove member'),
                          content: Text('Remove $name from this group?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Remove',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok) {
                    await gp.removeMember(
                      groupId: groupId,
                      memberId: id,
                      removedById: uid,
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'remove', child: Text('Remove member')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final bool canReassign;

  const _TaskRow({required this.task, required this.canReassign});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(task.title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              StatusBadge(label: _displayStatus(task.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Assigned to: ${task.assignedToName}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          Text('Role: ${task.role}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          if (canReassign) ...[
            const SizedBox(height: 6),
            const Text('Open the task to reassign or update status',
                style: TextStyle(fontSize: 12, color: AppColors.textMid)),
          ],
        ],
      ),
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'done':
        return 'Completed';
      case 'in_progress':
        return 'On Going';
      default:
        return 'To Do';
    }
  }
}
