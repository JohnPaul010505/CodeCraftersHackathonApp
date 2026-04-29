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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
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

  /// Returns the formatted date — uses admin-set specificDate when available,
  /// otherwise calculates the nearest upcoming weekday date.
  String _displayDate(String dayName, DateTime? specificDate) {
    if (specificDate != null) return DateFormat('MMM d').format(specificDate);
    const dayMap = {
      'Monday': DateTime.monday, 'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday, 'Thursday': DateTime.thursday,
      'Friday': DateTime.friday, 'Saturday': DateTime.saturday,
    };
    final target = dayMap[dayName];
    if (target == null) return '';
    final now = DateTime.now();
    var diff = target - now.weekday;
    if (diff < 0) diff += 7;
    return DateFormat('MMM d').format(now.add(Duration(days: diff)));
  }

  @override
  Widget build(BuildContext context) {
    final hasConflict = entry.hasConflict;
    final accentColor = hasConflict ? AppColors.conflict : AppColors.red;
    final dateStr = _displayDate(entry.day, entry.specificDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Time pill ──────────────────────────────────────────────
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.timeStart,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.timeEnd,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ── Subject info ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject name
                  Text(
                    entry.subject.name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 4),
                  // Code · Teacher · Section · Room
                  Text(
                    '${entry.subject.code} · ${entry.teacher.fullName} · ${entry.section} · ${entry.room.name}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.lightGray),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  // Date · Day badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.darkGray.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$dateStr · ${entry.day}',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray),
                        ),
                      ),
                      if (hasConflict) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.conflict.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Conflict',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.conflict),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // ── Three-dot menu ─────────────────────────────────────────
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.lightGray),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'details',
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.midGray),
                    const SizedBox(width: 10),
                    Text('View Details',
                        style: GoogleFonts.inter(fontSize: 13)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'room',
                  child: Row(children: [
                    const Icon(Icons.meeting_room_outlined,
                        size: 16, color: AppColors.midGray),
                    const SizedBox(width: 10),
                    Text('Room Info',
                        style: GoogleFonts.inter(fontSize: 13)),
                  ]),
                ),
              ],
              onSelected: (val) {
                if (val == 'details') {
                  _showDetailsSheet(context);
                } else if (val == 'room') {
                  _showRoomSheet(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.subject.name,
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Text('${entry.subject.code} · ${entry.section}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.lightGray)),
            const Divider(height: 24),
            _detailRow(Icons.access_time_outlined,
                '${entry.timeStart} – ${entry.timeEnd}'),
            const SizedBox(height: 10),
            _detailRow(Icons.calendar_today_outlined,
                '${_displayDate(entry.day, entry.specificDate)} · ${entry.day}'),
            const SizedBox(height: 10),
            _detailRow(Icons.meeting_room_outlined, entry.room.name),
            const SizedBox(height: 10),
            _detailRow(Icons.person_outline, entry.teacher.fullName),
            const SizedBox(height: 10),
            _detailRow(Icons.school_outlined,
                entry.subject.typeLabel),
          ],
        ),
      ),
    );
  }

  void _showRoomSheet(BuildContext context) {
    final room = entry.room;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.name,
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Text(room.typeLabel,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.lightGray)),
            const Divider(height: 24),
            _detailRow(Icons.layers_outlined, 'Floor ${room.floor}'),
            const SizedBox(height: 10),
            _detailRow(Icons.people_outline, '${room.capacity} seats'),
            if (room.hasProjector) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.tv_outlined, 'Projector'),
            ],
            if (room.hasAirConditioning) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.ac_unit_outlined, 'Air Conditioning'),
            ],
            if (room.hasComputers) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.computer_outlined, 'Computers'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.lightGray),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.darkGray)),
      ),
    ]);
  }
}