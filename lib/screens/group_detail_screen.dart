import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupName;
  const GroupDetailScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final isLeader = groupName == 'Data Analysis';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: AppColors.primary,
        actions: [
          Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child:
                    Icon(Icons.notifications_outlined, color: AppColors.white),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.red)),
              ),
            ],
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text('JC',
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RRSearchBar(hint: 'Search groups...'),
            const SizedBox(height: 16),

            // Leader: show workload balance
            if (isLeader) ...[
              Row(
                children: [
                  Text(groupName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(width: 8),
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
              _WorkloadCard(),
              const SizedBox(height: 16),
            ],

            // Members & Roles
            _SectionCard(
              title: 'Members & Roles',
              child: Column(
                children: [
                  _MemberRow('JC', '123', 'Leader', isLeader: false),
                  _MemberRow('Diana', '124', 'Week 2 Rep', isLeader: isLeader),
                  _MemberRow('Onia', '125', 'Week 1 Rep', isLeader: isLeader),
                  _MemberRow('Diana', '124', 'Week 2 Rep', isLeader: isLeader),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See more',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tasks
            _SectionCard(
              title: 'Tasks',
              child: Column(
                children: [
                  _TaskRow('Progress Report', 'Week 1 Rep', 'Completed',
                      canReassign: isLeader),
                  _TaskRow('Python Code', 'Leader', 'in-progress',
                      canReassign: isLeader),
                  _TaskRow('Progress Report', 'Week 1 Rep', 'Completed',
                      canReassign: isLeader),
                  _TaskRow('Python Code', 'Leader', 'in-progress',
                      canReassign: isLeader),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See more',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final members = [
      ('Onia (Week 1 Rep)', '1 task'),
      ('Diana (Week 2 Rep)', '1 task'),
      ('JC (Leader)', '2 task'),
      ('Gab (Week 3 Rep)', '1 task'),
    ];

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
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.$1, style: const TextStyle(fontSize: 13)),
                  Text(m.$2, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('See more',
                style: TextStyle(color: AppColors.primary)),
          ),
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
  final String name, id, role;
  final bool isLeader;

  const _MemberRow(this.name, this.id, this.role, {required this.isLeader});

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
            const Text('Edit',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String taskName, assignedTo, status;
  final bool canReassign;

  const _TaskRow(this.taskName, this.assignedTo, this.status,
      {required this.canReassign});

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
              Text(taskName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              StatusBadge(label: status),
            ],
          ),
          const SizedBox(height: 4),
          Text('Assigned to: $assignedTo',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          if (canReassign) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Reassign to : ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Week 1 Re..', style: TextStyle(fontSize: 12)),
                      Icon(Icons.expand_more, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
