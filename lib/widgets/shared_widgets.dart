import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Logo Row ──────────────────────────────────────────────────────────────────
class RoleRosterLogo extends StatelessWidget {
  final double size;
  final Color textColor;
  final Color iconColor;

  const RoleRosterLogo({
    super.key,
    this.size = 40,
    this.textColor = AppColors.textDark,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
            color: AppColors.white,
          ),
          child: Center(
            child: Icon(
              Icons.auto_stories,
              color: iconColor,
              size: size * 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'RoleRoster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size * 0.6,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ── Custom Text Field ─────────────────────────────────────────────────────────
class RRTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final String? helper;

  const RRTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textMid),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(helper!,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ),
        ],
      ],
    );
  }
}

// ── Auth Card Wrapper ─────────────────────────────────────────────────────────
class AuthCard extends StatelessWidget {
  final List<Widget> children;
  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

// ── Orange Primary Button ─────────────────────────────────────────────────────
class RRButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const RRButton(
      {super.key, required this.label, this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? ElevatedButton(
              onPressed: onTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            )
          : OutlinedButton(
              onPressed: onTap ?? () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textDark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});

  Color get _bg {
    switch (label.toLowerCase()) {
      case 'completed':
        return AppColors.doneBg;
      case 'in progress':
      case 'in-progress':
        return AppColors.inProgressBg;
      case 'to do':
      case 'todo':
      case 'pending':
        return AppColors.todoBg;
      case 'overdue':
        return AppColors.overdueBg;
      default:
        return AppColors.cardBg;
    }
  }

  Color get _fg {
    switch (label.toLowerCase()) {
      case 'completed':
        return AppColors.doneText;
      case 'in progress':
      case 'in-progress':
        return AppColors.inProgressText;
      case 'to do':
      case 'todo':
      case 'pending':
        return AppColors.todoText;
      case 'overdue':
        return AppColors.overdueText;
      default:
        return AppColors.textDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(color: _fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class RRBottomNav extends StatelessWidget {
  final int current;
  final Function(int) onTap;

  const RRBottomNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
      {'icon': Icons.group_outlined, 'label': 'Groups'},
      {'icon': Icons.check_box_outlined, 'label': 'My Task'},
      {'icon': Icons.folder_outlined, 'label': 'Projects'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Archived'},
    ];

    return BottomNavigationBar(
      currentIndex: current,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items
          .map((e) => BottomNavigationBarItem(
                icon: Icon(e['icon'] as IconData),
                label: e['label'] as String,
              ))
          .toList(),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class RRSearchBar extends StatelessWidget {
  final String hint;
  const RRSearchBar(
      {super.key, this.hint = 'Search tasks, projects, groups...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textLight, size: 20),
          const SizedBox(width: 8),
          Text(hint,
              style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
        ],
      ),
    );
  }
}
