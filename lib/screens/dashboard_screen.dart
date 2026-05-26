// lib/screens/dashboard_screen.dart
// REPLACE your existing dashboard_screen.dart with this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/task_provider.dart';
import '../models/group_model.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data once the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    context.read<GroupProvider>().loadGroups(uid);
    context.read<TaskProvider>().loadTasks(uid);
    context.read<NotificationProvider>().loadNotifications(uid);
  }

  Future<void> _showCreateTaskSheet(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final groups = context.read<GroupProvider>().groups;
    if (!auth.isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only leaders can create tasks.')),
      );
      return;
    }
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or join a group first.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    GroupModel selectedGroup = groups.first;
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
                  : (selectedGroup.memberNames[assigneeId] ?? assigneeId);

              if (titleCtrl.text.trim().isEmpty ||
                  assigneeId == null ||
                  roleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Fill in all task fields.')),
                );
                return;
              }

              await sheetContext.read<TaskProvider>().createTask(
                    groupId: selectedGroup.id,
                    groupName: selectedGroup.name,
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
                    DropdownButtonFormField<GroupModel>(
                      initialValue: selectedGroup,
                      items: groups
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(group.name),
                            ),
                          )
                          .toList(),
                      onChanged: (group) {
                        if (group != null) {
                          setSheetState(() {
                            selectedGroup = group;
                            selectedAssigneeId = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Group'),
                    ),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final candidateMemberIds = selectedGroup.memberIds
                          .where((id) => id != selectedGroup.leaderId)
                          .toList();
                      if (candidateMemberIds.isEmpty) {
                        return const Text(
                          'No accepted members in this group yet. Invite members and wait for acceptance.',
                          style: TextStyle(color: AppColors.textLight),
                        );
                      }

                      final validSelection = selectedAssigneeId != null &&
                          candidateMemberIds.contains(selectedAssigneeId);

                      return DropdownButtonFormField<String>(
                        initialValue:
                            validSelection ? selectedAssigneeId : null,
                        items: candidateMemberIds
                            .map(
                              (memberId) => DropdownMenuItem<String>(
                                value: memberId,
                                child: Text(
                                  '${selectedGroup.memberNames[memberId] ?? memberId} (${selectedGroup.memberRoles[memberId] ?? 'Member'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (memberId) {
                          setSheetState(() => selectedAssigneeId = memberId);
                        },
                        decoration:
                            const InputDecoration(labelText: 'Assign member'),
                      );
                    }),
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
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final auth = context.watch<AuthProvider>();
    final groups = context.watch<GroupProvider>().groups;
    final notifications = context.watch<NotificationProvider>();
    final taskProv = context.watch<TaskProvider>();

    final greeting = _greeting();
    final firstName = user?.username.split(' ').first ?? 'User';
    final initials = firstName.length >= 2
        ? firstName.substring(0, 2).toUpperCase()
        : firstName.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primary,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: const TextStyle(
                                color: AppColors.white, fontSize: 12)),
                        Text('Welcome back, $firstName',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.white, size: 28),
                        ),
                        if (notifications.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: Center(
                                child: Text(
                                  '${notifications.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RRSearchBar(),
                  const SizedBox(height: 16),
                  // ── Stats ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.group_outlined,
                          iconBg: const Color(0xFFE3F0FF),
                          iconColor: AppColors.primary,
                          label: 'Active groups',
                          value: '${groups.length}',
                          sub: '${groups.length} joined',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.access_time,
                          iconBg: const Color(0xFFFFECE0),
                          iconColor: AppColors.accent,
                          label: 'Pending tasks',
                          value: '${taskProv.pendingCount}',
                          sub: 'Tap My Task to view',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Recent tasks ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Tasks',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  if (taskProv.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (taskProv.tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: Text('No tasks yet.',
                              style: TextStyle(color: AppColors.textLight))),
                    )
                  else
                    ...taskProv.tasks.take(3).map((t) => _TaskTile(
                          title: t.title,
                          group: t.groupName,
                          status: t.status,
                          time: _formatDeadline(t.deadline),
                        )),
                  const SizedBox(height: 20),
                  const Text('Quick actions',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: auth.isLeader
                              ? () => _showCreateTaskSheet(context)
                              : () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Only leaders can create tasks.'),
                                    ),
                                  ),
                          icon: const Icon(Icons.add),
                          label: const Text('New task'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.message_outlined),
                          label: const Text('Message team'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDeadline(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    return 'Due in $diff days';
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value, sub;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
          Text(sub,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title, group, status, time;

  const _TaskTile({
    required this.title,
    required this.group,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == 'done'
        ? AppColors.success
        : status == 'in_progress'
            ? AppColors.accent
            : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textMid.withValues(alpha: 0.5)),
            child: Icon(Icons.task_alt, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(group,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 11)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }
}
