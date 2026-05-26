// lib/screens/groups_screen.dart
// REPLACE your existing groups_screen.dart with this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import 'create_group_project_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<GroupProvider>().loadGroups(uid);
    });
  }

  Future<void> _openCreateProjectForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupProjectScreen()),
    );
    if (!mounted) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      await context.read<GroupProvider>().loadGroups(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final groupProv = context.watch<GroupProvider>();
    final initials = (user?.username ?? 'U').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RoleRoster'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: _openCreateProjectForm,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.white),
            tooltip: 'Create group',
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text('My Groups',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${groupProv.groups.length} total',
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: RRSearchBar(hint: 'Search groups...'),
          ),
          Expanded(
            child: groupProv.loading
                ? const Center(child: CircularProgressIndicator())
                : groupProv.groups.isEmpty
                    ? const Center(
                        child: Text('No groups yet. Tap + to create one.',
                            style: TextStyle(color: AppColors.textLight)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupProv.groups.length,
                        itemBuilder: (context, i) {
                          final g = groupProv.groups[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        GroupDetailScreen(group: g))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.textMid
                                          .withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                      'Leader: ${g.leaderName} · ${g.memberCount} members',
                                      style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12)),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: g.progress,
                                      backgroundColor: AppColors.divider,
                                      valueColor: const AlwaysStoppedAnimation(
                                          AppColors.progressBlue),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${g.doneTasks}/${g.totalTasks} tasks done',
                                      style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
