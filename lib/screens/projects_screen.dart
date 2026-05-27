import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/project_upload_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'profile_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _fabOpen = false;
  String? _loadedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null && uid != _loadedUid) {
      _loadedUid = uid;
      context.read<ProjectUploadProvider>().loadUploads(uid);
    }
  }

  Future<void> _uploadFile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final groupCtrl = TextEditingController();
    final taskCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload project file'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        );
      },
    );

    if (fromCamera == null || !mounted) return;

    final ok = await context.read<ProjectUploadProvider>().uploadDocument(
          ownerId: user.uid,
          ownerName: user.username,
          fromCamera: fromCamera,
          groupName: groupCtrl.text.trim(),
          taskTitle: taskCtrl.text.trim(),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Project file uploaded and saved.'
              : 'Upload cancelled or failed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    final uploadProv = context.watch<ProjectUploadProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RoleRoster'),
        backgroundColor: AppColors.primary,
        actions: [
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: AppColors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: const RRSearchBar(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: uid == null
                      ? const Center(
                          child: Text(
                            'Please sign in to view project files.',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        )
                      : uploadProv.loading && uploadProv.uploads.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : uploadProv.uploads.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No uploaded documents yet.',
                                    style:
                                        TextStyle(color: AppColors.textLight),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (uploadProv.error != null) ...[
                                      Text(
                                        uploadProv.error!,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Expanded(
                                      child: GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.05,
                                        ),
                                        itemCount: uploadProv.uploads.length,
                                        itemBuilder: (ctx, i) {
                                          final upload = uploadProv.uploads[i];
                                          final fileName = _safeString(
                                              upload.fileName, 'Untitled');
                                          final groupName = _safeString(
                                              upload.groupName,
                                              'Unassigned group');
                                          final taskTitle = _safeString(
                                              upload.taskTitle, 'No task');

                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  _fileIcon(fileName),
                                                  size: 34,
                                                  color: AppColors.textDark,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  fileName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  groupName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMid,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  taskTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatDate(upload.createdAt),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                ),
              ),
            ],
          ),
          // FAB + overlay menu
          if (_fabOpen)
            GestureDetector(
              onTap: () => setState(() => _fabOpen = false),
              child: Container(color: Colors.transparent),
            ),
          if (_fabOpen)
            Positioned(
              bottom: 80,
              right: 16,
              child: _FabMenu(
                onClose: () => setState(() => _fabOpen = false),
                onUpload: () async {
                  setState(() => _fabOpen = false);
                  await _uploadFile();
                },
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => setState(() => _fabOpen = !_fabOpen),
              backgroundColor: AppColors.cardBg,
              child: Icon(
                _fabOpen ? Icons.close : Icons.add,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeString(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return Icons.grid_on_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }
}

class _FabMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onUpload;
  const _FabMenu({required this.onClose, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.create_new_folder_outlined, 'New Folder'],
      [Icons.drive_folder_upload_outlined, 'Upload Folder'],
      [Icons.upload_file, 'Upload File'],
      [Icons.grid_on, 'Google Sheets', true],
      [Icons.slideshow, 'PowerPoint', true],
      [Icons.description_outlined, 'Google Docs', true],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.textMid.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => InkWell(
                onTap: () {
                  onClose();
                  if (item[1] == 'Upload File') {
                    onUpload();
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item[0] as IconData, size: 22),
                      const SizedBox(width: 12),
                      Text(item[1] as String,
                          style: const TextStyle(fontSize: 15)),
                      if (item.length > 2) ...[
                        const SizedBox(width: 20),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
