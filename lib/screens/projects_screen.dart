import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _fabOpen = false;

  @override
  Widget build(BuildContext context) {
    final folders = ['Data Mining', 'Data Analysis', 'Mobile Dev'];

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
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: folders.length,
                    itemBuilder: (ctx, i) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 64, color: AppColors.textDark),
                        const SizedBox(height: 6),
                        Text(folders[i], style: const TextStyle(fontSize: 13)),
                      ],
                    ),
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
              child: _FabMenu(onClose: () => setState(() => _fabOpen = false)),
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
}

class _FabMenu extends StatelessWidget {
  final VoidCallback onClose;
  const _FabMenu({required this.onClose});

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
                onTap: onClose,
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
