// lib/screens/profile_screen.dart
// REPLACE your existing profile_screen.dart with this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.username ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Save profile edits ────────────────────────────────────────────────────
  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    final updated = auth.user!.copyWith(
      username: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    final ok = await profile.updateProfile(updated);
    if (!mounted) return;

    if (ok) {
      auth.updateLocalUser(updated);
      setState(() => _editing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profile.error ?? 'Update failed.')));
    }
  }

  // ── Pick profile photo ────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto({required bool fromCamera}) async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    final url =
        await profile.changePhoto(auth.user!.uid, fromCamera: fromCamera);

    if (!mounted) return;

    if (url != null) {
      auth.updateLocalUser(auth.user!.copyWith(photoUrl: url));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Photo updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isLoading = context.watch<ProfileProvider>().loading;
    String? cachedPhoto;
    if (user?.uid != null) {
      try {
        final box = Hive.box('profiles');
        cachedPhoto = box.get(user!.uid) as String?;
      } catch (_) {
        cachedPhoto = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit,
                color: AppColors.white),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_editing ? 'Editing Profile' : 'Edit Profile',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                  child: const Text('Settings'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Avatar ─────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.textMid.withValues(alpha: 0.15),
                      backgroundImage: (user?.photoUrl ?? cachedPhoto) != null
                          ? NetworkImage(user?.photoUrl ?? cachedPhoto!)
                          : null,
                      child: (user?.photoUrl ?? cachedPhoto) == null
                          ? const Icon(Icons.person,
                              size: 56, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.primary),
                        child: const Icon(Icons.edit,
                            size: 16, color: AppColors.white),
                      ),
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.black26,
                          child:
                              CircularProgressIndicator(color: AppColors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ── Fields ─────────────────────────────────────────────────────
            _FieldRow(
              label: 'Full Name',
              value: user?.username ?? '',
              controller: _nameCtrl,
              editing: _editing,
            ),
            _FieldRow(
              label: 'Account ID',
              value: user?.uid.substring(0, 8).toUpperCase() ?? '',
              controller: null,
              editing: false, // never editable
            ),
            _FieldRow(
              label: 'Email Address',
              value: user?.email ?? '',
              controller: null,
              editing: false, // managed by Firebase Auth
            ),
            _FieldRow(
              label: 'Phone Number',
              value: user?.phone ?? '',
              controller: _phoneCtrl,
              editing: _editing,
            ),
            _FieldRow(
              label: 'Role',
              value: user?.role ?? '',
              controller: null,
              editing: false,
            ),
            if (_editing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text('Save Changes',
                          style: TextStyle(color: AppColors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label, value;
  final TextEditingController? controller;
  final bool editing;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.controller,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 4),
          editing && controller != null
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(value, style: const TextStyle(fontSize: 15)),
                ),
        ],
      ),
    );
  }
}
