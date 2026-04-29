// lib/screens/export_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/teacher.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

// Conditional import: uses dart:html on web, no-op stubs on Android/iOS.
import 'download_helper_stub.dart'
if (dart.library.html) 'download_helper_web.dart';

// ─── Report type enum ─────────────────────────────────────────────────────────
enum _ReportType { teacherLoad, roomSchedule, fullSchedule, conflict }

// =============================================================================
//  Export Reports – entry list
// =============================================================================
class ExportReportsScreen extends StatefulWidget {
  final Teacher? teacher;
  const ExportReportsScreen({super.key, this.teacher});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen>
    with _GenerateReportsMixin {

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return buildGenerateReports(context, state);
  }
}


class GenerateReportsScreen extends StatefulWidget {
  const GenerateReportsScreen({super.key});

  @override
  State<GenerateReportsScreen> createState() => _GenerateReportsScreenState();
}

mixin _GenerateReportsMixin<T extends StatefulWidget> on State<T> {
  _ReportType _selected = _ReportType.teacherLoad;
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _doneCsv = false;
  bool _donePdf = false;

  static const _options = [
    (
    type: _ReportType.teacherLoad,
    icon: Icons.people_outline,
    label: 'Teacher\nLoad',
    desc: 'Teaching units, subjects & workload for all teachers',
    ),
    (
    type: _ReportType.roomSchedule,
    icon: Icons.meeting_room_outlined,
    label: 'Room\nSchedule',
    desc: 'Room usage, time slots & assigned subjects per floor',
    ),
    (
    type: _ReportType.fullSchedule,
    icon: Icons.calendar_month_outlined,
    label: 'Full\nSchedule',
    desc: 'All scheduled classes — subject, teacher, room & time',
    ),
    (
    type: _ReportType.conflict,
    icon: Icons.warning_amber_outlined,
    label: 'Conflict\nReport',
    desc: 'Active and resolved scheduling conflicts',
    ),
  ];

  Widget buildGenerateReports(BuildContext context, AppState state) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _exportingCsv || _exportingPdf
                ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh data',
              onPressed: () async {
                setState(() => _exportingCsv = true);
                await state.refreshAllData();
                if (mounted) setState(() {
                  _exportingCsv = false;
                  _doneCsv = false;
                  _donePdf = false;
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Generate Reports',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Select a report type to preview and export',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _options.map((opt) {
                final isActive = _selected == opt.type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selected = opt.type;
                      _doneCsv = false;
                      _donePdf = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.darkGray : AppColors.bgGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? AppColors.darkGray : AppColors.borderGray,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(opt.icon, size: 22,
                              color: isActive ? Colors.white : AppColors.midGray),
                          const SizedBox(height: 6),
                          Text(opt.label, textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : AppColors.midGray,
                                height: 1.3,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_selected),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkGray.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(_options.firstWhere((o) => o.type == _selected).icon,
                      size: 16, color: AppColors.darkGray),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _options.firstWhere((o) => o.type == _selected).desc,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.midGray),
                  )),
                ]),
              ),
            ),
          ),
          _buildTableHeader(),
          Expanded(child: _buildTableBody(state)),
          _ExportBar(
            exportingCsv: _exportingCsv,
            exportingPdf: _exportingPdf,
            doneCsv: _doneCsv,
            donePdf: _donePdf,
            onExportCsv: () => _doExport(context: context, state: state, isCsv: true),
            onExportPdf: () => _doExport(context: context, state: state, isCsv: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    switch (_selected) {
      case _ReportType.teacherLoad:
        return const _TableHeader(cells: [
          _Cell('Teacher', flex: 3), _Cell('Department', flex: 2),
          _Cell('Subjects', flex: 3), _Cell('Units', fixedWidth: 70),
          _Cell('Status', flex: 2),
        ]);
      case _ReportType.roomSchedule:
        return const _TableHeader(cells: [
          _Cell('Room', flex: 2), _Cell('Floor', fixedWidth: 50),
          _Cell('Capacity', fixedWidth: 70), _Cell('Status', flex: 2),
          _Cell('Usage', flex: 4),
        ]);
      case _ReportType.fullSchedule:
        return const _TableHeader(cells: [
          _Cell('Subject', flex: 2), _Cell('Teacher', flex: 2),
          _Cell('Room', flex: 2), _Cell('Section', flex: 2),
          _Cell('Day & Time', flex: 3),
        ]);
      case _ReportType.conflict:
        return const _TableHeader(cells: [
          _Cell('Type', flex: 2), _Cell('Description', flex: 4),
          _Cell('Status', flex: 2), _Cell('Detected', flex: 2),
        ]);
    }
  }

  Widget _buildTableBody(AppState state) {
    switch (_selected) {
      case _ReportType.teacherLoad: return _TeacherLoadTable(state: state);
      case _ReportType.roomSchedule: return _RoomTable(state: state);
      case _ReportType.fullSchedule: return _ScheduleTable(state: state);
      case _ReportType.conflict: return _ConflictTable(state: state);
    }
  }

  Future<void> _doExport({required BuildContext context, required AppState state, required bool isCsv}) async {
    setState(() {
      if (isCsv) { _exportingCsv = true; _doneCsv = false; }
      else { _exportingPdf = true; _donePdf = false; }
    });
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    String csvContent = '';
    String fileName = '';
    String htmlContent = '';
    switch (_selected) {
      case _ReportType.teacherLoad:
        csvContent = _buildTeacherCsv(state); fileName = 'teacher_load_report_$ts.csv';
        htmlContent = _buildTeacherHtml(state);
      case _ReportType.roomSchedule:
        csvContent = _buildRoomCsv(state); fileName = 'room_schedule_report_$ts.csv';
        htmlContent = _buildRoomHtml(state);
      case _ReportType.fullSchedule:
        csvContent = _buildScheduleCsv(state); fileName = 'full_schedule_report_$ts.csv';
        htmlContent = _buildScheduleHtml(state);
      case _ReportType.conflict:
        csvContent = _buildConflictCsv(state); fileName = 'conflict_report_$ts.csv';
        htmlContent = _buildConflictHtml(state);
    }
    if (isCsv) { downloadCsv(csvContent, fileName); }
    else { openHtmlInNewTab(htmlContent); }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      if (isCsv) { _exportingCsv = false; _doneCsv = true; }
      else { _exportingPdf = false; _donePdf = true; }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isCsv ? '$fileName downloaded' : 'Opened in new tab — use browser Print → Save as PDF',
        style: GoogleFonts.inter(),
      ),
      backgroundColor: AppColors.available,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  String _buildTeacherCsv(AppState state) {
    final buf = StringBuffer();
    buf.writeln('Teacher Name,Department,Employee ID,Unit Type,Current Units,Max Units,Status,Subjects');
    for (final t in state.teachers) {
      final subjects = state.scheduleEntries.where((e) => e.teacher.id == t.id).map((e) => e.subject.code).toSet().join('; ');
      buf.writeln('"${t.fullName}","${t.department}","${t.employeeId}","${t.unitType}",${t.currentUnits},${t.maxUnits},"${t.status.name}","$subjects"');
    }
    return buf.toString();
  }

  String _buildRoomCsv(AppState state) {
    final buf = StringBuffer();
    buf.writeln('Room,Floor,Capacity,Type,Projector,AC,Computers,Status,Usage');
    for (final r in state.rooms) {
      final hasEntries = state.scheduleEntries.any((e) => e.room.id == r.id);
      final label = (r.status == RoomStatus.available && hasEntries) ? 'Occupied' : r.statusLabel;
      buf.writeln('"${r.name}",${r.floor},${r.capacity},"${r.typeLabel}",${r.hasProjector},${r.hasAirConditioning},${r.hasComputers},"$label","${_roomUsageText(r, state)}"');
    }
    return buf.toString();
  }

  String _buildScheduleCsv(AppState state) {
    final buf = StringBuffer();
    buf.writeln('Subject Code,Subject Name,Teacher,Room,Section,Day,Time Start,Time End,Semester,Academic Year');
    for (final e in state.scheduleEntries) {
      buf.writeln('"${e.subject.code}","${e.subject.name}","${e.teacher.fullName}","${e.room.name}","${e.section}","${e.day}","${e.timeStart}","${e.timeEnd}","${e.semester}","${e.academicYear}"');
    }
    return buf.toString();
  }

  String _buildConflictCsv(AppState state) {
    final buf = StringBuffer();
    buf.writeln('Conflict Type,Description,Status,Entry 1,Entry 2,Detected At');
    for (final c in state.conflicts) {
      final e1 = '${c.conflictingEntry1.subject.code} ${c.conflictingEntry1.teacher.fullName}';
      final e2 = '${c.conflictingEntry2.subject.code} ${c.conflictingEntry2.teacher.fullName}';
      buf.writeln('"${c.typeLabel}","${c.description}","${c.isResolved ? 'Resolved' : 'Active'}","$e1","$e2","${DateFormat('yyyy-MM-dd HH:mm').format(c.detectedAt)}"');
    }
    return buf.toString();
  }

  String _baseHtml(String title, String tableHtml) => '''
<html lang="en"><head><title>$title</title>
<style>
  body{font-family:Arial,sans-serif;font-size:13px;padding:24px;color:#1E1E1E}
  h2{margin-bottom:4px}p.sub{color:#888;font-size:12px;margin-bottom:16px}
  table{width:100%;border-collapse:collapse}
  th{background:#1E1E1E;color:#fff;padding:8px 10px;text-align:left;font-size:12px}
  td{padding:8px 10px;border-bottom:1px solid #eee;font-size:12px}
  .green{color:#2E7D32}.red{color:#C62828}.orange{color:#E65100}.amber{color:#F57F17}
</style></head><body>
<h2>$title</h2>
<p class="sub">Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}</p>
$tableHtml
</body></html>''';

  String _buildTeacherHtml(AppState state) {
    final rows = state.teachers.map((t) {
      final subjects = state.scheduleEntries.where((e) => e.teacher.id == t.id).map((e) => e.subject.code).toSet().join(', ');
      final hasConflict = state.conflicts.where((c) => !c.isResolved).any((c) => c.conflictingEntry1.teacher.id == t.id || c.conflictingEntry2.teacher.id == t.id);
      final reqStatus = state.teacherRequestStatuses[t.id] ?? '';
      final htmlStatus = reqStatus.isNotEmpty ? reqStatus : (hasConflict ? 'Has conflict' : 'No conflicts');
      final htmlClass = (reqStatus == 'Absent') ? 'amber' : (reqStatus == 'Class Cancelled' || hasConflict) ? 'red' : reqStatus.isNotEmpty ? 'amber' : 'green';
      return '<tr><td>${t.fullName}</td><td>${t.department}</td><td>${subjects.isEmpty ? '—' : subjects}</td><td>${t.currentUnits}/${t.maxUnits}</td><td class="$htmlClass">$htmlStatus</td></tr>';
    }).join();
    return _baseHtml('Teacher Load Report', '<table><tr><th>Teacher</th><th>Department</th><th>Subjects</th><th>Units</th><th>Status</th></tr>$rows</table>');
  }

  String _buildRoomHtml(AppState state) {
    final rows = state.rooms.map((r) {
      final hasEntries = state.scheduleEntries.any((e) => e.room.id == r.id);
      final cls = switch (r.status) {
        RoomStatus.event => 'amber', RoomStatus.maintenance => 'orange',
        RoomStatus.occupied => 'red',
        RoomStatus.available => hasEntries ? 'red' : 'green',
      };
      final label = (r.status == RoomStatus.available && hasEntries) ? 'Occupied' : r.statusLabel;
      return '<tr><td>${r.name}</td><td>${r.floor}</td><td>${r.capacity}</td><td class="$cls">$label</td><td>${_roomUsageText(r, state)}</td></tr>';
    }).join();
    return _baseHtml('Room Schedule Report', '<table><tr><th>Room</th><th>Floor</th><th>Capacity</th><th>Status</th><th>Usage</th></tr>$rows</table>');
  }

  String _buildScheduleHtml(AppState state) {
    final rows = state.scheduleEntries.map((e) =>
    '<tr><td>${e.subject.code}</td><td>${e.teacher.fullName}</td><td>${e.room.name}</td><td>${e.section}</td><td>${e.day} ${e.timeStart}–${e.timeEnd}</td></tr>').join();
    return _baseHtml('Full Schedule Report', '<table><tr><th>Subject</th><th>Teacher</th><th>Room</th><th>Section</th><th>Day & Time</th></tr>$rows</table>');
  }

  String _buildConflictHtml(AppState state) {
    final rows = state.conflicts.map((c) =>
    '<tr><td>${c.typeLabel}</td><td>${c.description}</td><td class="${c.isResolved ? 'green' : 'red'}">${c.isResolved ? 'Resolved' : 'Active'}</td><td>${DateFormat('MMM dd, yyyy').format(c.detectedAt)}</td></tr>').join();
    return _baseHtml('Conflict Report', '<table><tr><th>Type</th><th>Description</th><th>Status</th><th>Detected</th></tr>$rows</table>');
  }

  String _roomUsageText(Room r, AppState state) {
    if (r.status == RoomStatus.occupied && r.currentSubject != null) return '${r.currentSubject} – ${r.currentTeacher ?? ''}';
    if (r.status == RoomStatus.occupied) return 'Manually set as occupied';
    if ((r.status == RoomStatus.event || r.status == RoomStatus.maintenance) && r.eventNote != null) return r.eventNote!;
    final entries = state.scheduleEntries.where((e) => e.room.id == r.id).toList();
    if (entries.isNotEmpty) return '${entries.first.subject.code} – ${entries.first.teacher.fullName}';
    return 'Not scheduled';
  }
}

class _GenerateReportsScreenState extends State<GenerateReportsScreen>
    with _GenerateReportsMixin {

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return buildGenerateReports(context, state);
  }
}

// ── Table body sub-widgets ────────────────────────────────────────────────────

class _TeacherLoadTable extends StatelessWidget {
  final AppState state;
  const _TeacherLoadTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final teachers = state.teachers;
    if (teachers.isEmpty) return const _EmptyState(message: 'No teachers found');
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: teachers.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final t = teachers[i];
        final subjects = state.scheduleEntries
            .where((e) => e.teacher.id == t.id)
            .map((e) => e.subject.code).toSet().toList();
        final hasConflict = state.conflicts.where((c) => !c.isResolved).any((c) =>
        c.conflictingEntry1.teacher.id == t.id || c.conflictingEntry2.teacher.id == t.id);
        final reqStatus = state.teacherRequestStatuses[t.id] ?? '';
        final String statusLabel = reqStatus.isNotEmpty ? reqStatus
            : (hasConflict ? 'Has conflict' : 'No conflicts');
        final Color statusColor = (reqStatus == 'Absent') ? AppColors.moderate
            : (reqStatus == 'Class Cancelled' || (reqStatus.isEmpty && hasConflict)) ? AppColors.conflict
            : reqStatus.isNotEmpty ? AppColors.warning : AppColors.available;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: [
            Expanded(flex: 3, child: _cellText(t.fullName)),
            Expanded(flex: 2, child: _cellText(t.department)),
            Expanded(flex: 3, child: Text(
              subjects.isEmpty ? '—' : subjects.take(3).join(', '),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
              overflow: TextOverflow.ellipsis,
            )),
            SizedBox(width: 70, child: _cellText('${t.currentUnits}/${t.maxUnits}')),
            Expanded(flex: 2, child: Text(
              statusLabel,
              style: GoogleFonts.inter(fontSize: 13, color: statusColor),
            )),
          ]),
        );
      },
    );
  }
}

class _RoomTable extends StatelessWidget {
  final AppState state;
  const _RoomTable({required this.state});

  Color _statusColor(Room r) => switch (r.status) {
    RoomStatus.available => state.scheduleEntries.any((e) => e.room.id == r.id)
        ? AppColors.conflict : AppColors.available,
    RoomStatus.occupied => AppColors.conflict,
    RoomStatus.maintenance => AppColors.moderate,
    RoomStatus.event => AppColors.warning,
  };

  String _effectiveLabel(Room r) {
    if (r.status == RoomStatus.event) return 'Event';
    if (r.status == RoomStatus.maintenance) return 'Maintenance';
    if (r.status == RoomStatus.occupied) return 'Occupied';
    return state.scheduleEntries.any((e) => e.room.id == r.id) ? 'Occupied' : 'Available';
  }

  String _usage(Room r) {
    if (r.status == RoomStatus.occupied && r.currentSubject != null) {
      return '${r.currentSubject} – ${r.currentTeacher ?? ''}';
    }
    if (r.status == RoomStatus.occupied) return 'Manually set as occupied';
    if ((r.status == RoomStatus.event || r.status == RoomStatus.maintenance) &&
        r.eventNote != null) return r.eventNote!;
    final entries = state.scheduleEntries.where((e) => e.room.id == r.id).toList();
    if (entries.isNotEmpty) return '${entries.first.subject.code} – ${entries.first.teacher.fullName}';
    return 'Not scheduled';
  }

  @override
  Widget build(BuildContext context) {
    if (state.rooms.isEmpty) return const _EmptyState(message: 'No rooms found');
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: state.rooms.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final r = state.rooms[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: [
            Expanded(flex: 2, child: _cellText(r.name)),
            SizedBox(width: 50, child: _cellText('${r.floor}')),
            SizedBox(width: 70, child: _cellText('${r.capacity}')),
            Expanded(flex: 2, child: Text(_effectiveLabel(r),
                style: GoogleFonts.inter(fontSize: 13,
                    color: _statusColor(r), fontWeight: FontWeight.w500))),
            Expanded(flex: 4, child: Text(_usage(r),
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                overflow: TextOverflow.ellipsis)),
          ]),
        );
      },
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  final AppState state;
  const _ScheduleTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final entries = state.scheduleEntries;
    if (entries.isEmpty) return const _EmptyState(message: 'No schedule entries found');
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: [
            Expanded(flex: 2, child: _cellText(e.subject.code)),
            Expanded(flex: 2, child: Text(e.teacher.fullName,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: _cellText(e.room.name)),
            Expanded(flex: 2, child: _cellText(e.section)),
            Expanded(flex: 3, child: _cellText('${e.day} ${e.timeStart}–${e.timeEnd}')),
          ]),
        );
      },
    );
  }
}

class _ConflictTable extends StatelessWidget {
  final AppState state;
  const _ConflictTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final conflicts = state.conflicts;
    if (conflicts.isEmpty) {
      return const _EmptyState(
        message: 'No conflicts detected',
        icon: Icons.check_circle_outline,
        color: AppColors.available,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: conflicts.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final c = conflicts[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: [
            Expanded(flex: 2, child: _cellText(c.typeLabel)),
            Expanded(flex: 4, child: Text(c.description,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(
              c.isResolved ? 'Resolved' : 'Active',
              style: GoogleFonts.inter(fontSize: 13,
                  color: c.isResolved ? AppColors.available : AppColors.conflict,
                  fontWeight: FontWeight.w500),
            )),
            Expanded(flex: 2, child: _cellText(
                DateFormat('MMM dd, yyyy').format(c.detectedAt))),
          ]),
        );
      },
    );
  }
}

Widget _cellText(String text) =>
    Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray));

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.color = AppColors.lightGray,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: color.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text(message, style: GoogleFonts.inter(fontSize: 14, color: color)),
      ]),
    );
  }
}

// =============================================================================
//  Teacher Load Report Screen
// =============================================================================
class TeacherLoadReportScreen extends StatefulWidget {
  final AppState state;
  const TeacherLoadReportScreen({super.key, required this.state});

  @override
  State<TeacherLoadReportScreen> createState() => _TeacherLoadReportScreenState();
}

class _TeacherLoadReportScreenState extends State<TeacherLoadReportScreen> {
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _doneCsv = false;
  bool _donePdf = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final teachers = state.teachers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _exportingCsv || _exportingPdf
                ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh data',
              onPressed: () async {
                setState(() => _exportingCsv = true);
                await state.refreshAllData();
                if (mounted) setState(() => _exportingCsv = false);
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Teacher Load Summary',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          ),

          const _TableHeader(cells: [
            _Cell('Teacher', flex: 3),
            _Cell('Department', flex: 2),
            _Cell('Subjects', flex: 3),
            _Cell('Units', fixedWidth: 70),
            _Cell('Status', flex: 2),
          ]),

          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: teachers.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) {
                final t = teachers[i];
                final subjectCodes = state.scheduleEntries
                    .where((e) => e.teacher.id == t.id)
                    .map((e) => e.subject.code).toSet().toList();
                final hasConflict = state.conflicts.where((c) => !c.isResolved).any((c) =>
                c.conflictingEntry1.teacher.id == t.id ||
                    c.conflictingEntry2.teacher.id == t.id);
                final reqStatus2 = state.teacherRequestStatuses[t.id] ?? '';
                final String statusLabel2 = reqStatus2.isNotEmpty ? reqStatus2
                    : (hasConflict ? 'Has conflict' : 'No conflicts');
                final Color statusColor2 = (reqStatus2 == 'Absent') ? AppColors.moderate
                    : (reqStatus2 == 'Class Cancelled' || (reqStatus2.isEmpty && hasConflict)) ? AppColors.conflict
                    : reqStatus2.isNotEmpty ? AppColors.warning : AppColors.available;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    Expanded(flex: 3, child: _cellText(t.fullName)),
                    Expanded(flex: 2, child: _cellText(t.department)),
                    Expanded(flex: 3, child: Text(
                      subjectCodes.isEmpty ? '—' : subjectCodes.take(3).join(', '),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                      overflow: TextOverflow.ellipsis,
                    )),
                    SizedBox(width: 70, child: _cellText('${t.currentUnits}/${t.maxUnits}')),
                    Expanded(flex: 2, child: Text(
                      statusLabel2,
                      style: GoogleFonts.inter(fontSize: 13, color: statusColor2),
                    )),
                  ]),
                );
              },
            ),
          ),

          _ExportBar(
            exportingCsv: _exportingCsv,
            exportingPdf: _exportingPdf,
            doneCsv: _doneCsv,
            donePdf: _donePdf,
            onExportCsv: () => _doExport(state: state, isCsv: true),
            onExportPdf: () => _doExport(state: state, isCsv: false),
          ),
        ],
      ),
    );
  }

  Future<void> _doExport({required AppState state, required bool isCsv}) async {
    setState(() {
      if (isCsv) { _exportingCsv = true; _doneCsv = false; }
      else { _exportingPdf = true; _donePdf = false; }
    });
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (isCsv) {
      final buf = StringBuffer();
      buf.writeln('Teacher Name,Department,Employee ID,Unit Type,Current Units,Max Units,Status,Subjects');
      for (final t in state.teachers) {
        final subjects = state.scheduleEntries
            .where((e) => e.teacher.id == t.id)
            .map((e) => e.subject.code).toSet().join('; ');
        buf.writeln('"${t.fullName}","${t.department}","${t.employeeId}","${t.unitType}",${t.currentUnits},${t.maxUnits},"${t.status.name}","$subjects"');
      }
      downloadCsv(buf.toString(), 'teacher_load_report_$ts.csv');
    } else {
      final rows = state.teachers.map((t) {
        final subjects = state.scheduleEntries
            .where((e) => e.teacher.id == t.id)
            .map((e) => e.subject.code).toSet().join(', ');
        final hasConflict = state.conflicts.where((c) => !c.isResolved).any((c) =>
        c.conflictingEntry1.teacher.id == t.id || c.conflictingEntry2.teacher.id == t.id);
        final reqStatus3 = state.teacherRequestStatuses[t.id] ?? '';
        final String htmlStatus3 = reqStatus3.isNotEmpty ? reqStatus3
            : (hasConflict ? 'Has conflict' : 'No conflicts');
        final String htmlColor3 = (reqStatus3 == 'Absent') ? '#E65100'
            : (reqStatus3 == 'Class Cancelled' || (reqStatus3.isEmpty && hasConflict)) ? '#C62828'
            : reqStatus3.isNotEmpty ? '#F57F17' : '#2E7D32';
        final subjectsCell3 = subjects.isEmpty ? '\u2014' : subjects;
        return '<tr><td>${t.fullName}</td><td>${t.department}</td>'
            '<td>$subjectsCell3</td><td>${t.currentUnits}/${t.maxUnits}</td>'
            '<td style="color:$htmlColor3">'
            '$htmlStatus3</td></tr>';
      }).join();
      openHtmlInNewTab('''<html lang="en"><head><title>Teacher Load Report</title>
<style>body{font-family:Arial;font-size:13px;padding:24px}
table{width:100%;border-collapse:collapse}
th{background:#1E1E1E;color:#fff;padding:8px 10px;text-align:left}
td{padding:8px 10px;border-bottom:1px solid #eee}</style></head><body>
<h2>Teacher Load Report</h2>
<p style="color:#888">Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}</p>
<table><tr><th>Teacher</th><th>Department</th><th>Subjects</th><th>Units</th><th>Status</th></tr>
$rows</table></body></html>''');
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      if (isCsv) { _exportingCsv = false; _doneCsv = true; }
      else { _exportingPdf = false; _donePdf = true; }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isCsv ? 'teacher_load_report_$ts.csv downloaded'
            : 'Opened in new tab — use browser Print → Save as PDF',
        style: GoogleFonts.inter(),
      ),
      backgroundColor: AppColors.available,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}

// =============================================================================
//  Room Schedule Report Screen
// =============================================================================
class RoomScheduleReportScreen extends StatefulWidget {
  const RoomScheduleReportScreen({super.key});

  @override
  State<RoomScheduleReportScreen> createState() => _RoomScheduleReportScreenState();
}

class _RoomScheduleReportScreenState extends State<RoomScheduleReportScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<int> _floors = [];
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _doneCsv = false;
  bool _donePdf = false;

  void _rebuildTabs(List<int> newFloors) {
    _tabController?.dispose();
    _floors = List.from(newFloors);
    _tabController = TabController(length: newFloors.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final floors = state.rooms.map((r) => r.floor).toSet().toList()..sort();

      if (_tabController == null ||
          floors.length != _floors.length ||
          !floors.every((f) => _floors.contains(f))) {
        _rebuildTabs(floors);
      }

      final tc = _tabController!;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _exportingCsv || _exportingPdf
                  ? const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh data',
                onPressed: () async {
                  setState(() => _exportingCsv = true);
                  await state.refreshAllData();
                  if (mounted) setState(() => _exportingCsv = false);
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              controller: tc,
              isScrollable: true,
              labelColor: AppColors.darkGray,
              unselectedLabelColor: AppColors.lightGray,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
              indicatorColor: AppColors.darkGray,
              indicatorWeight: 2,
              dividerColor: Colors.grey.shade200,
              tabs: floors.map((f) => Tab(text: 'FLOOR $f')).toList(),
            ),
            const _TableHeader(cells: [
              _Cell('Room', flex: 2),
              _Cell('Capacity', fixedWidth: 72),
              _Cell('Equipment', flex: 4),
              _Cell('Status', flex: 2),
              _Cell('Usage', flex: 3),
            ]),
            Expanded(
              child: TabBarView(
                controller: tc,
                children: floors.map((floor) {
                  final floorRooms =
                  state.rooms.where((r) => r.floor == floor).toList();
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: floorRooms.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) =>
                        _RoomRow(room: floorRooms[i], state: state),
                  );
                }).toList(),
              ),
            ),
            _ExportBar(
              exportingCsv: _exportingCsv,
              exportingPdf: _exportingPdf,
              doneCsv: _doneCsv,
              donePdf: _donePdf,
              onExportCsv: () => _doExport(state: state, isCsv: true),
              onExportPdf: () => _doExport(state: state, isCsv: false),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _doExport({required AppState state, required bool isCsv}) async {
    setState(() {
      if (isCsv) { _exportingCsv = true; _doneCsv = false; }
      else { _exportingPdf = true; _donePdf = false; }
    });
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (isCsv) {
      final buf = StringBuffer();
      buf.writeln('Room,Floor,Capacity,Type,Projector,AC,Computers,Status,Usage');
      for (final r in state.rooms) {
        final hasEntries = state.scheduleEntries.any((e) => e.room.id == r.id);
        final effectiveLabel = (r.status == RoomStatus.available && hasEntries)
            ? 'Occupied' : r.statusLabel;
        buf.writeln('"${r.name}",${r.floor},${r.capacity},"${r.typeLabel}",'
            '${r.hasProjector},${r.hasAirConditioning},${r.hasComputers},'
            '"$effectiveLabel","${_usageText(r, state)}"');
      }
      downloadCsv(buf.toString(), 'room_schedule_report_$ts.csv');
    } else {
      final floors = state.rooms.map((r) => r.floor).toSet().toList()..sort();
      final htmlBuf = StringBuffer();
      htmlBuf.write('''<html lang="en"><head><title>Room Schedule Report</title>
<style>body{font-family:Arial;font-size:12px;padding:24px}
table{width:100%;border-collapse:collapse;margin-bottom:20px}
th{background:#1E1E1E;color:#fff;padding:7px 10px;text-align:left}
td{padding:7px 10px;border-bottom:1px solid #eee}
.available{color:#2E7D32}.occupied{color:#C62828}
.maintenance{color:#E65100}.event{color:#F57F17}
</style></head><body>
<h2>Room Schedule Report</h2>
<p style="color:#888">Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}</p>''');
      for (final floor in floors) {
        final floorRooms = state.rooms.where((r) => r.floor == floor).toList();
        htmlBuf.write('<h3>Floor $floor</h3><table>'
            '<tr><th>Room</th><th>Capacity</th><th>Equipment</th><th>Status</th><th>Usage</th></tr>');
        for (final r in floorRooms) {
          final equip = _equipText(r);
          final hasEntries = state.scheduleEntries.any((e) => e.room.id == r.id);
          final cls = (r.status == RoomStatus.available && hasEntries) ? 'occupied' : r.status.name;
          final label = (r.status == RoomStatus.available && hasEntries) ? 'Occupied' : r.statusLabel;
          htmlBuf.write('<tr><td>${r.name}</td><td>${r.capacity}</td><td>$equip</td>'
              '<td class="$cls">$label</td><td>${_usageText(r, state)}</td></tr>');
        }
        htmlBuf.write('</table>');
      }
      htmlBuf.write('</body></html>');
      openHtmlInNewTab(htmlBuf.toString());
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      if (isCsv) { _exportingCsv = false; _doneCsv = true; }
      else { _exportingPdf = false; _donePdf = true; }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isCsv ? 'room_schedule_report_$ts.csv downloaded'
            : 'Opened in new tab — use browser Print → Save as PDF',
        style: GoogleFonts.inter(),
      ),
      backgroundColor: AppColors.available,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  String _equipText(Room r) {
    final items = <String>[];
    if (r.type == RoomType.laboratory) items.add('Laboratory');
    if (r.hasComputers) items.add('Computers');
    if (r.hasAirConditioning) items.add('Air Conditioning');
    if (r.hasProjector) items.add('Projector');
    return items.isEmpty ? '—' : items.join(', ');
  }

  String _usageText(Room r, AppState state) {
    if (r.status == RoomStatus.occupied && r.currentSubject != null) {
      final t = r.currentTeacher != null ? ' – ${r.currentTeacher}' : '';
      final time = (r.currentTimeStart != null && r.currentTimeEnd != null)
          ? ' (${r.currentTimeStart} to ${r.currentTimeEnd})' : '';
      return '${r.currentSubject}$t$time';
    }
    if (r.status == RoomStatus.occupied) return 'Manually set as occupied';
    if ((r.status == RoomStatus.event || r.status == RoomStatus.maintenance) &&
        r.eventNote != null) return r.eventNote!;
    final entries = state.scheduleEntries.where((e) => e.room.id == r.id).toList();
    if (entries.isNotEmpty) return '${entries.first.subject.code} – ${entries.first.teacher.fullName}';
    return 'Not scheduled';
  }
}

// ── Room row widget ───────────────────────────────────────────────────────────
class _RoomRow extends StatelessWidget {
  final Room room;
  final AppState state;
  const _RoomRow({required this.room, required this.state});

  Color get _statusColor {
    if (room.status == RoomStatus.event) return AppColors.warning;
    if (room.status == RoomStatus.maintenance) return AppColors.moderate;
    if (room.status == RoomStatus.occupied) return AppColors.conflict;
    return state.scheduleEntries.any((e) => e.room.id == room.id)
        ? AppColors.conflict : AppColors.available;
  }

  String get _statusLabel {
    if (room.status == RoomStatus.event) return 'Event';
    if (room.status == RoomStatus.maintenance) return 'Maintenance';
    if (room.status == RoomStatus.occupied) return 'Occupied';
    return state.scheduleEntries.any((e) => e.room.id == room.id) ? 'Occupied' : 'Available';
  }

  String _equipment() {
    final items = <String>[];
    if (room.type == RoomType.laboratory) items.add('Laboratory');
    if (room.hasComputers) items.add('Computers');
    if (room.hasAirConditioning) items.add('Air Conditioning');
    if (room.hasProjector) items.add('Projector');
    return items.isEmpty ? '—' : items.join(', ');
  }

  String _usage() {
    if (room.status == RoomStatus.occupied && room.currentSubject != null) {
      final t = room.currentTeacher != null ? ' – ${room.currentTeacher}' : '';
      final time = (room.currentTimeStart != null && room.currentTimeEnd != null)
          ? ' (${room.currentTimeStart} to ${room.currentTimeEnd})' : '';
      return '${room.currentSubject}$t$time';
    }
    if (room.status == RoomStatus.occupied) return 'Manually set as occupied';
    if ((room.status == RoomStatus.event || room.status == RoomStatus.maintenance) &&
        room.eventNote != null) return room.eventNote!;
    final entries = state.scheduleEntries.where((e) => e.room.id == room.id).toList();
    if (entries.isNotEmpty) return '${entries.first.subject.code} – ${entries.first.teacher.fullName}';
    return 'Not scheduled';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(children: [
        Expanded(flex: 2, child: _cellText(room.name)),
        SizedBox(width: 72, child: _cellText('${room.capacity}')),
        Expanded(flex: 4, child: Text(_equipment(),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray))),
        Expanded(flex: 2, child: Text(_statusLabel,
            style: GoogleFonts.inter(fontSize: 13,
                color: _statusColor, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Text(_usage(),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// =============================================================================
//  Shared layout widgets
// =============================================================================
class _Cell {
  final String label;
  final int? flex;
  final double? fixedWidth;
  const _Cell(this.label, {this.flex, this.fixedWidth});
}

class _TableHeader extends StatelessWidget {
  final List<_Cell> cells;
  const _TableHeader({required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: cells.map((c) {
          final child = Text(c.label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray));
          if (c.fixedWidth != null) return SizedBox(width: c.fixedWidth, child: child);
          return Expanded(flex: c.flex ?? 1, child: child);
        }).toList(),
      ),
    );
  }
}

class _ExportBar extends StatelessWidget {
  final bool exportingCsv, exportingPdf, doneCsv, donePdf;
  final VoidCallback onExportCsv, onExportPdf;

  const _ExportBar({
    required this.exportingCsv, required this.exportingPdf,
    required this.doneCsv, required this.donePdf,
    required this.onExportCsv, required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        _ExportButton(
          icon: Icons.download, label: 'Export CSV',
          isLoading: exportingCsv, isDone: doneCsv,
          onTap: exportingCsv || doneCsv ? null : onExportCsv,
        ),
        const SizedBox(width: 10),
        _ExportButton(
          icon: Icons.picture_as_pdf_outlined, label: 'Export PDF',
          isLoading: exportingPdf, isDone: donePdf,
          onTap: exportingPdf || donePdf ? null : onExportPdf,
        ),
      ]),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading, isDone;
  final VoidCallback? onTap;

  const _ExportButton({
    required this.icon, required this.label,
    required this.isLoading, required this.isDone, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: isLoading
          ? const SizedBox(width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkGray))
          : Icon(isDone ? Icons.check : icon, size: 16,
          color: isDone ? AppColors.available : AppColors.darkGray),
      label: Text(label,
          style: GoogleFonts.inter(fontSize: 13,
              color: isDone ? AppColors.available : AppColors.darkGray)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: isDone ? AppColors.available : const Color(0xFFCCCCCC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}