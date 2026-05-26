import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';

class CreateGroupProjectScreen extends StatefulWidget {
  const CreateGroupProjectScreen({super.key});

  @override
  State<CreateGroupProjectScreen> createState() =>
      _CreateGroupProjectScreenState();
}

class _CreateGroupProjectScreenState extends State<CreateGroupProjectScreen> {
  final _projectNameCtrl = TextEditingController();
  final _projectTitleCtrl = TextEditingController();
  final List<_MemberInviteRow> _memberRows = [];

  DateTime _startedAt = DateTime.now();
  DateTime _dueAt = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _memberRows.add(_MemberInviteRow());
  }

  @override
  void dispose() {
    _projectNameCtrl.dispose();
    _projectTitleCtrl.dispose();
    for (final row in _memberRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStartedAt() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _startedAt = selected);
    }
  }

  Future<void> _pickDueAt() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt.isBefore(_startedAt) ? _startedAt : _dueAt,
      firstDate: _startedAt,
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _dueAt = selected);
    }
  }

  Future<void> _submit() async {
    if (_projectNameCtrl.text.trim().isEmpty ||
        _projectTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name and title are required.')),
      );
      return;
    }

    if (_dueAt.isBefore(_startedAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date cannot be before start date.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final invites = <InvitedMemberInput>[];
    for (final row in _memberRows) {
      final identifier = row.identifierCtrl.text.trim();
      if (identifier.isEmpty) continue;

      final role = row.selectedRole == _RoleChoice.custom
          ? row.customRoleCtrl.text.trim()
          : row.selectedRole.label;

      if (role.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Each invited member must have a role.')),
        );
        return;
      }

      invites.add(InvitedMemberInput(identifier: identifier, role: role));
    }

    setState(() => _submitting = true);
    final gp = context.read<GroupProvider>();
    final ok = await gp.createGroup(
      name: _projectNameCtrl.text.trim(),
      title: _projectTitleCtrl.text.trim(),
      startedAt: _startedAt,
      dueAt: _dueAt,
      leaderId: user.uid,
      leaderName: user.username,
      invitedMembers: invites,
    );
    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group project created and invitations sent.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create group project.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Group Project'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _projectNameCtrl,
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projectTitleCtrl,
              decoration: const InputDecoration(labelText: 'Project title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Project started',
                    date: _startedAt,
                    onTap: _pickStartedAt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'Project due date',
                    date: _dueAt,
                    onTap: _pickDueAt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._memberRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return _MemberInviteCard(
                row: row,
                onRemove: _memberRows.length == 1
                    ? null
                    : () {
                        setState(() {
                          row.dispose();
                          _memberRows.removeAt(index);
                        });
                      },
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _memberRows.add(_MemberInviteRow())),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Member'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Project'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Invite using email or username. Invited members must accept from Notifications before they receive tasks.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${date.month}/${date.day}/${date.year}'),
          ],
        ),
      ),
    );
  }
}

enum _RoleChoice {
  documentationLead('Documentation lead'),
  tester('Tester'),
  developer('Developer'),
  custom('Custom role');

  final String label;
  const _RoleChoice(this.label);
}

class _MemberInviteRow {
  final identifierCtrl = TextEditingController();
  final customRoleCtrl = TextEditingController();
  _RoleChoice selectedRole = _RoleChoice.documentationLead;

  void dispose() {
    identifierCtrl.dispose();
    customRoleCtrl.dispose();
  }
}

class _MemberInviteCard extends StatelessWidget {
  final _MemberInviteRow row;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _MemberInviteCard({
    required this.row,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: row.identifierCtrl,
            decoration: InputDecoration(
              labelText: 'Member email or username',
              suffixIcon: onRemove == null
                  ? null
                  : IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_RoleChoice>(
            initialValue: row.selectedRole,
            items: _RoleChoice.values
                .map(
                  (choice) => DropdownMenuItem<_RoleChoice>(
                    value: choice,
                    child: Text(choice.label),
                  ),
                )
                .toList(),
            onChanged: (choice) {
              if (choice == null) return;
              row.selectedRole = choice;
              onChanged();
            },
            decoration: const InputDecoration(labelText: 'Member role'),
          ),
          if (row.selectedRole == _RoleChoice.custom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: row.customRoleCtrl,
              decoration: const InputDecoration(labelText: 'Custom role'),
            ),
          ],
        ],
      ),
    );
  }
}
