import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/teacher.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class TeacherScheduleScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherScheduleScreen({super.key, required this.teacher});

  @override
  State<TeacherScheduleScreen> createState() =>
      _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
  ];
  String _selectedDay = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final allSchedule =
      state.getTeacherSchedule(widget.teacher.id);
      final filtered = _selectedDay == 'ALL'
          ? allSchedule
          : allSchedule
          .where((e) => e.day == _selectedDay)
          .toList()
        ..sort((a, b) => a.timeStart.compareTo(b.timeStart));

      final totalUnits =
      allSchedule.fold<int>(0, (s, e) => s + e.subject.units);
      final conflicts =
          allSchedule.where((e) => e.hasConflict).length;

      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
        ),
        body: Column(
          children: [
            // ── Header + filters ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Schedule',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allSchedule.length} classes · $totalUnits units',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.lightGray),
                  ),
                  const SizedBox(height: 14),

                  // Day filter tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', ..._days].map((day) {
                        final active = _selectedDay == day;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDay = day),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.darkGray
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: active
                                    ? AppColors.darkGray
                                    : AppColors.borderGray,
                              ),
                            ),
                            child: Text(
                              day == 'ALL'
                                  ? 'ALL DAYS'
                                  : day.substring(0, 3).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.lightGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Summary row
                  Row(
                    children: [
                      Text(
                        '${filtered.length} of ${allSchedule.length} classes shown',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.lightGray),
                      ),
                      const Spacer(),
                      if (conflicts > 0) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.conflict,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$conflicts conflict${conflicts > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.conflict,
                              fontWeight: FontWeight.w600),
                        ),
                      ] else ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.available,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'No conflicts',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.available,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Schedule list ───────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.free_breakfast_outlined,
                        size: 52, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDay == 'ALL'
                          ? 'No classes assigned'
                          : 'No classes on $_selectedDay',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.lightGray,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _ScheduleCard(entry: filtered[i]),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScheduleCard — room-card style matching the screenshots
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry;
  const _ScheduleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasConflict = entry.hasConflict;
    final statusColor =
    hasConflict ? AppColors.conflict : AppColors.available;
    final isLab =
    entry.subject.type.toString().contains('laboratory');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
            ),
            child: Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasConflict ? 'Conflict Detected' : 'Scheduled',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
              const Spacer(),
              // Day badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.darkGray.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.day,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray),
                ),
              ),
            ]),
          ),

          // ── Content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject name + type badge
                Row(children: [
                  Expanded(
                    child: Text(
                      entry.subject.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.borderGray),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLab ? 'laboratory' : 'lecture',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.lightGray),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${entry.room.typeLabel} · Capacity: ${entry.room.capacity} students',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.lightGray),
                ),
                const SizedBox(height: 10),

                // Equipment chips
                Wrap(
                  spacing: 8,
                  children: [
                    if (entry.room.hasProjector)
                      _equipChip(Icons.tv_outlined, 'Projector'),
                    if (entry.room.hasAirConditioning)
                      _equipChip(
                          Icons.ac_unit_outlined, 'Air Conditioning'),
                    if (entry.room.hasComputers)
                      _equipChip(
                          Icons.computer_outlined, 'Computers'),
                  ],
                ),
                const SizedBox(height: 12),

                // Status / time row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasConflict ? 'Conflict' : 'Confirmed',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                // Current class info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.subject.code} · ${entry.section}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.room.name} · ${entry.day} ${entry.timeStart}–${entry.timeEnd}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.lightGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipChip(IconData icon, String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.lightGray),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.midGray)),
      ]),
    );
  }
}