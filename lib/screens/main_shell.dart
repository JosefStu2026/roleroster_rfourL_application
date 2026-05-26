import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'groups_screen.dart';
import 'my_task_screen.dart';
import 'projects_screen.dart';
import 'archived_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final _screens = const [
    DashboardScreen(),
    GroupsScreen(),
    MyTaskScreen(),
    ProjectsScreen(),
    ArchivedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined), label: 'Groups'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_box_outlined), label: 'My Task'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined), label: 'Projects'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Archived'),
        ],
      ),
    );
  }
}
