import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/teacher.dart';
import '../theme/app_theme.dart';
import 'teacher_schedule_screen.dart';
import 'export_reports_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Teacher teacher;
  const TeacherProfileScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final schedule = state.getTeacherSchedule(teacher.id);
        final conflictCount = schedule.where((s) => s.hasConflict).length;

        return Scaffold(
          backgroundColor: AppColors.bgGray,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExportReportsScreen(teacher: teacher),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.redDark, AppColors.redLight],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${teacher.firstName[0]}${teacher.lastName[0]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            teacher.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            teacher.department,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(teacher.status),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick stats
                      Row(
                        children: [
                          _statCard('${teacher.currentUnits}', 'Current\nUnits',
                              Icons.book_outlined, AppColors.red),
                          const SizedBox(width: 12),
                          _statCard('${teacher.maxUnits}', 'Max\nUnits',
                              Icons.trending_up, AppColors.warning),
                          const SizedBox(width: 12),
                          _statCard('${schedule.length}', 'Classes\nScheduled',
                              Icons.calendar_month_outlined, AppColors.available),
                          const SizedBox(width: 12),
                          _statCard(
                            '$conflictCount',
                            'Conflict\nAlerts',
                            Icons.warning_amber_outlined,
                            conflictCount > 0
                                ? AppColors.conflict
                                : AppColors.available,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Load bar
                      _sectionTitle('Teaching Load'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${teacher.currentUnits} of ${teacher.maxUnits} units',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  teacher.unitType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: teacher.loadPercentage.clamp(0.0, 1.0),
                                backgroundColor: AppColors.bgGray,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  teacher.isOverloaded
                                      ? AppColors.conflict
                                      : AppColors.red,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (teacher.isOverloaded)
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber,
                                      color: AppColors.conflict, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Overloaded by ${teacher.currentUnits - teacher.maxUnits} units',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.conflict,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Info
                      _sectionTitle('Profile Information'),
                      const SizedBox(height: 10),
                      _infoCard([
                        _InfoRow(Icons.badge_outlined, 'Employee ID', teacher.employeeId),
                        _InfoRow(Icons.email_outlined, 'Email', teacher.email),
                        _InfoRow(Icons.business_outlined, 'Department', teacher.department),
                        _InfoRow(Icons.work_outline, 'Unit Type', teacher.unitType),
                        _InfoRow(
                          Icons.star_outline,
                          'Expertise',
                          teacher.expertise.join(', '),
                        ),
                        _InfoRow(
                          Icons.calendar_today_outlined,
                          'Available Days',
                          teacher.availableDays
                              .map((d) => d.substring(0, 3))
                              .join(', '),
                        ),
                        _InfoRow(
                          Icons.access_time_outlined,
                          'Available Hours',
                          '${teacher.availableTimeStart} – ${teacher.availableTimeEnd}',
                        ),
                      ]),
                      const SizedBox(height: 20),
                      // Subjects
                      _sectionTitle('Assigned Subjects (${schedule.length})'),
                      const SizedBox(height: 10),
                      if (schedule.isEmpty)
                        _emptyState('No subjects assigned yet.')
                      else
                        ...schedule.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: entry.hasConflict
                                      ? AppColors.conflict.withValues(alpha: 0.4)
                                      : AppColors.borderGray,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      entry.subject.type.name == 'laboratory'
                                          ? Icons.science_outlined
                                          : Icons.menu_book_outlined,
                                      color: AppColors.red,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.subject.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${entry.subject.code} · ${entry.subject.units} units · ${entry.section}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.lightGray,
                                          ),
                                        ),
                                        Text(
                                          '${entry.day} · ${entry.timeRange} · ${entry.room.name}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entry.hasConflict)
                                    const Icon(Icons.warning_amber,
                                        color: AppColors.conflict, size: 16),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      // Actions
                      _sectionTitle('Actions'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              Icons.calendar_month_outlined,
                              'View Schedule',
                              AppColors.red,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TeacherScheduleScreen(teacher: teacher),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              Icons.download_outlined,
                              'Export Report',
                              AppColors.available,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExportReportsScreen(teacher: teacher),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(TeacherStatus status) {
    String label;
    Color color;
    switch (status) {
      case TeacherStatus.active:
        label = 'Active';
        color = AppColors.available;
        break;
      case TeacherStatus.onLeave:
        label = 'On Leave';
        color = AppColors.moderate;
        break;
      case TeacherStatus.inactive:
        label = 'Inactive';
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.lightGray,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray));
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(e.value.icon, size: 16, color: AppColors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.value.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.lightGray)),
                    ),
                    Flexible(
                      child: Text(e.value.value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGray)),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 44),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(msg,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.lightGray)),
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}
