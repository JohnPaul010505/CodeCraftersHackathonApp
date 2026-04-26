// lib/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import 'admin_dashboard_screen.dart';
import 'room_availability_screen.dart';
import 'teacher_management_screen.dart';
import 'subject_management_screen.dart';
import 'schedule_screen.dart';
import 'sections_management_screen.dart';
import 'export_reports_screen.dart';
import 'profile_screen.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const List<_NavItem> _tabs = [
    _NavItem(Icons.dashboard_outlined,     Icons.dashboard,      'Dashboard'),
    _NavItem(Icons.meeting_room_outlined,  Icons.meeting_room,   'Rooms'),
    _NavItem(Icons.people_outline,         Icons.people,         'Teachers'),
    _NavItem(Icons.book_outlined,          Icons.book,           'Subjects'),
    _NavItem(Icons.grid_view_outlined,     Icons.grid_view,      'Sections'),
    _NavItem(Icons.calendar_month_outlined,Icons.calendar_month, 'Schedule'),
    _NavItem(Icons.bar_chart_outlined,     Icons.bar_chart,      'Reports'),
    _NavItem(Icons.person_outline,         Icons.person,         'Profile'),
  ];

  List<Widget> get _bodies => [
    AdminDashboardBody(onNavigate: (i) => setState(() => _index = i)),
    const RoomAvailabilityScreen(),
    const TeacherManagementScreen(),
    const SubjectManagementScreen(),
    const SectionsManagementScreen(),
    const ScheduleScreen(),
    const ExportReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Wide layout: side rail + content
    if (width >= 720) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(
              tabs: _tabs,
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderGray),
            Expanded(
              child: IndexedStack(index: _index, children: _bodies),
            ),
          ],
        ),
      );
    }

    // Mobile layout: bottom nav
    return Scaffold(
      body: IndexedStack(index: _index, children: _bodies),
      bottomNavigationBar: _BottomNav(
        tabs: _tabs,
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Side navigation rail for wide screens ────────────────────────────────────
class _SideRail extends StatelessWidget {
  final List<_NavItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SideRail({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.darkGray,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SASS Admin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Scheduling System',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: tabs.length,
                itemBuilder: (_, i) {
                  final active = selectedIndex == i;
                  return _SideNavItem(
                    item: tabs[i],
                    isActive: active,
                    onTap: () => onTap(i),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.red.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 18,
              color: isActive ? AppColors.red : Colors.white54,
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation bar for mobile ─────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final List<_NavItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? tabs[i].activeIcon : tabs[i].icon,
                        size: 20,
                        color: active ? AppColors.red : Colors.white38,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? AppColors.red : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: active ? 18 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}