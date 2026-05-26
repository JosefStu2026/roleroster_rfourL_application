// lib/screens/my_task_screen.dart
// REPLACE your existing my_task_screen.dart with this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'task_detail_screen.dart';

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<TaskProvider>().loadTasks(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RoleRoster'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: RRSearchBar(),
          ),
          Expanded(
            child: taskProv.loading
                ? const Center(child: CircularProgressIndicator())
                : taskProv.tasks.isEmpty
                    ? const Center(
                        child: Text('No tasks assigned.',
                            style: TextStyle(color: AppColors.textLight)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: taskProv.tasks.length,
                        itemBuilder: (ctx, i) {
                          final t = taskProv.tasks[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                    builder: (_) => TaskDetailScreen(task: t))),
                            child: _TaskCard(task: t),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  Color get _color {
    switch (task.status) {
      case 'done':
        return AppColors.success;
      case 'in_progress':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.groupName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDark),
                    children: [
                      const TextSpan(
                          text: 'Role: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: task.role),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDark),
                    children: [
                      const TextSpan(
                          text: 'Deadline: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: _formatDate(task.deadline)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textMid.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: _color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Task',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Text('1',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              const SizedBox(height: 4),
              const Text('View Details',
                  style: TextStyle(color: AppColors.textMid, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
