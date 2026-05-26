import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _statusValue;
  final _assigneeNameCtrl = TextEditingController();
  final _assigneeIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusValue = _statusLabelFromBackend(widget.task.status);
    _assigneeNameCtrl.text = widget.task.assignedToName;
    _assigneeIdCtrl.text = widget.task.assignedToId;
  }

  @override
  void dispose() {
    _assigneeNameCtrl.dispose();
    _assigneeIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    final backendStatus = _backendStatusFromLabel(_statusValue);
    final taskProv = context.read<TaskProvider>();
    await taskProv.updateStatus(widget.task.id, backendStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task progress updated.')),
    );
  }

  Future<void> _reassign() async {
    final name = _assigneeNameCtrl.text.trim();
    final id = _assigneeIdCtrl.text.trim();
    if (name.isEmpty || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the member name and ID.')),
      );
      return;
    }

    final taskProv = context.read<TaskProvider>();
    await taskProv.reassignTask(
      taskId: widget.task.id,
      assignedToId: id,
      assignedToName: name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task reassigned.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLeader = auth.user?.uid == widget.task.createdById;
    final isAssignee = auth.user?.uid == widget.task.assignedToId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.task.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Group: ${widget.task.groupName}',
                      style: const TextStyle(color: AppColors.textLight)),
                  Text(
                      'Assigned to: ${widget.task.assignedToName} (${widget.task.assignedToId})',
                      style: const TextStyle(color: AppColors.textLight)),
                  Text('Task type: ${widget.task.role}',
                      style: const TextStyle(color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  StatusBadge(label: _statusValue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLeader) ...[
              _ActionCard(
                title: 'Reassign task',
                child: Column(
                  children: [
                    TextField(
                      controller: _assigneeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Member name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _assigneeIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Member ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _reassign,
                        child: const Text('Reassign to member'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isAssignee) ...[
              _ActionCard(
                title: 'Update progress',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _statusValue,
                      items: const [
                        DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                        DropdownMenuItem(
                          value: 'On Going',
                          child: Text('On Going'),
                        ),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statusValue = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Progress status',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProgress,
                        child: const Text('Save progress'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _ActionCard(
                title: 'Task access',
                child: const Text(
                  'This task is assigned to another member. Only the assignee can update progress.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabelFromBackend(String status) {
    switch (status) {
      case 'in_progress':
        return 'On Going';
      case 'done':
        return 'Completed';
      default:
        return 'To Do';
    }
  }

  String _backendStatusFromLabel(String label) {
    switch (label) {
      case 'On Going':
        return 'in_progress';
      case 'Completed':
        return 'done';
      default:
        return 'pending';
    }
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ActionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
