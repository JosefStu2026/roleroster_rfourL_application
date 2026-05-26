import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TaskDetailScreen extends StatelessWidget {
  final String groupName;
  const TaskDetailScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final isOverdue = groupName == 'Data Analysis';
    final tasks = [
      _Task('Python Code', 'In Progress', '12/10/2025'),
      _Task('PPT', 'To Do', '12/15/2025'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RoleRoster'),
        backgroundColor: AppColors.primary,
        actions: [
          const Icon(Icons.notifications_outlined, color: AppColors.white),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: AppColors.white, size: 18),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: const RRSearchBar(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(groupName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(width: 12),
                Text(
                  '12/16/2025',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tasks',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...tasks.map((t) => _TaskCard(task: t)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Task {
  final String name, status, dueDate;
  _Task(this.name, this.status, this.dueDate);
}

class _TaskCard extends StatelessWidget {
  final _Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15)),
              StatusBadge(label: task.status),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attachment:',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textMid)),
                    const SizedBox(height: 6),
                    const Icon(Icons.insert_drive_file_outlined,
                        size: 40, color: AppColors.textMid),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Due Date:',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textMid)),
                    const SizedBox(height: 6),
                    Text(task.dueDate,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
